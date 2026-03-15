# MySQL 8.0 — Enterprise edition, 8 vCPU / 16 GB RAM, single zone, no HA, private IP only
resource "google_sql_database_instance" "ctfd" {
  project          = var.gcp_project_id
  name             = var.cloud_sql_instance_name
  database_version = "MYSQL_8_0"
  region           = var.gcp_region

  settings {
    # db-custom-<vcpus>-<memory_mb>: 8 vCPU, 16 GB RAM
    tier              = "db-custom-8-16384"
    edition           = "ENTERPRISE"
    availability_type = "ZONAL" # single zone, no HA

    ip_configuration {
      ipv4_enabled    = false
      private_network = "projects/${var.gcp_project_id}/global/networks/${var.cr_vpc}"
      # Allows Cloud Run (via Cloud SQL Auth Proxy annotation) to reach the instance
      enable_private_path_for_google_cloud_services = true
    }

    location_preference {
      zone = var.gcp_zone
    }

    backup_configuration {
      enabled            = false
      binary_log_enabled = false
    }

    disk_type       = "PD_SSD"
    disk_size       = 20
    disk_autoresize = true
  }

  deletion_protection = false

  depends_on = [google_service_networking_connection.psa]
}

resource "google_sql_database" "ctfd" {
  project  = var.gcp_project_id
  instance = google_sql_database_instance.ctfd.name
  name     = var.db_name
}

resource "google_sql_user" "ctfd" {
  project  = var.gcp_project_id
  instance = google_sql_database_instance.ctfd.name
  name     = var.db_user
  password = var.db_password
  host     = "%"
}
