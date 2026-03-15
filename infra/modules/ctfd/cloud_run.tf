# CTFd Cloud Run v2 — multi-container capable, gen2 execution environment
# Uses Direct VPC Egress for private connectivity to Cloud SQL (via Auth Proxy annotation),
# Redis (private IP), and GCS FUSE for the /var/uploads volume.
resource "google_cloud_run_v2_service" "ctfd" {
  project  = var.gcp_project_id
  name     = "ctfd-multi-containers"
  location = var.gcp_region

  template {
    service_account = google_service_account.ctfd_runner.email

    execution_environment = "EXECUTION_ENVIRONMENT_GEN2"

    # Cloud SQL Auth Proxy is injected by Cloud Run using this annotation
    annotations = {
      "run.googleapis.com/cloudsql-instances" = "${var.gcp_project_id}:${var.gcp_region}:${var.cloud_sql_instance_name}"
    }

    scaling {
      min_instance_count = 1
      max_instance_count = 100
    }

    containers {
      name  = "ctfd"
      image = "ctfd/ctfd:latest"

      ports {
        container_port = 8000
      }

      resources {
        # cpu_idle = false maps to run.googleapis.com/cpu-throttling: false
        # (CPU always allocated — needed for background tasks in CTFd)
        cpu_idle          = false
        startup_cpu_boost = true
      }

      env {
        name  = "DATABASE_URL"
        # urlencode() percent-encodes special characters in the password (e.g. @, /, #, ?)
        # that would otherwise corrupt the URL and cause MySQL authentication failures.
        value = "mysql+pymysql://${var.db_user}:${urlencode(var.db_password)}@/${var.db_name}?unix_socket=/cloudsql/${var.gcp_project_id}:${var.gcp_region}:${var.cloud_sql_instance_name}"
      }

      env {
        name  = "REDIS_URL"
        value = "redis://${google_redis_instance.ctfd.host}:6379"
      }

      env {
        name  = "UPLOAD_FOLDER"
        value = "/var/uploads"
      }

      env {
        name  = "REVERSE_PROXY"
        value = "true"
      }

      volume_mounts {
        name       = "uploads-volume"
        mount_path = "/var/uploads"
      }
    }

    # GCS FUSE volume for persistent image uploads across instances
    volumes {
      name = "uploads-volume"
      gcs {
        bucket    = google_storage_bucket.ctfd_uploads.name
        read_only = false
      }
    }

    # Direct VPC Egress — routes private-range traffic through the VPC
    # This enables connectivity to Cloud SQL private IP, Redis, and GCS FUSE
    vpc_access {
      egress = "PRIVATE_RANGES_ONLY"
      network_interfaces {
        network    = var.cr_vpc
        subnetwork = var.cr_subnet
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  depends_on = [
    google_project_service.run_api,
    google_sql_database_instance.ctfd,
    google_sql_database.ctfd,
    google_sql_user.ctfd,
    google_redis_instance.ctfd,
    google_storage_bucket.ctfd_uploads,
    google_project_iam_member.ctfd_cloudsql_client,
    google_storage_bucket_iam_member.ctfd_gcs_fuse,
  ]
}

# Allow unauthenticated invocations (public CTF access)
# NOTE: In the Datadog Sandbox project, org policy "Domain restricted sharing" may block this.
# Workaround: add label "external-access:allowed" to the Cloud Run service via gcloud.
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  project  = var.gcp_project_id
  location = var.gcp_region
  name     = google_cloud_run_v2_service.ctfd.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
