# Service account used by Cloud Run to access Cloud SQL, Redis (via VPC), and GCS FUSE
resource "google_service_account" "ctfd_runner" {
  project      = var.gcp_project_id
  account_id   = var.cr_sa_name
  display_name = "CTFd Cloud Run Service Account"
}

# Allows Cloud SQL Auth Proxy (injected by Cloud Run) to connect to the instance
resource "google_project_iam_member" "ctfd_cloudsql_client" {
  project = var.gcp_project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.ctfd_runner.email}"
}

# GCS Object Admin on the uploads bucket — required for GCS FUSE read/write
resource "google_storage_bucket_iam_member" "ctfd_gcs_fuse" {
  bucket = google_storage_bucket.ctfd_uploads.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.ctfd_runner.email}"
}

# Allows reading secrets from Secret Manager (optional — for future DB/Redis credential rotation)
resource "google_project_iam_member" "ctfd_secret_accessor" {
  project = var.gcp_project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.ctfd_runner.email}"
}
