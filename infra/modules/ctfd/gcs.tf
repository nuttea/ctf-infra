resource "google_storage_bucket" "ctfd_uploads" {
  project       = var.gcp_project_id
  name          = var.gcs_bucket
  location      = var.gcs_bucket_region
  force_destroy = false

  # Uniform bucket-level access required for GCS FUSE with service account IAM
  uniform_bucket_level_access = true

  versioning {
    enabled = false
  }

  depends_on = [google_project_service.storage_api]
}
