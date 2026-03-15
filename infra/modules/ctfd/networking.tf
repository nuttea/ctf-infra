# Enable required GCP APIs
resource "google_project_service" "service_networking" {
  project            = var.gcp_project_id
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sqladmin" {
  project            = var.gcp_project_id
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "redis_api" {
  project            = var.gcp_project_id
  service            = "redis.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "run_api" {
  project            = var.gcp_project_id
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "storage_api" {
  project            = var.gcp_project_id
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

# Private Service Access (PSA) reserved IP range for Cloud SQL and Memorystore Redis.
# Both services use VPC peering via servicenetworking.googleapis.com.
# NOTE: If PSA is already configured on this VPC, import the existing resources
# instead of creating new ones to avoid conflicts:
#   terraform import google_compute_global_address.psa_range projects/<project>/global/addresses/ctfd-psa-range
#   terraform import google_service_networking_connection.psa <network>:<service>
resource "google_compute_global_address" "psa_range" {
  project       = var.gcp_project_id
  name          = "ctfd-psa-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 20
  network       = "projects/${var.gcp_project_id}/global/networks/${var.cr_vpc}"

  depends_on = [google_project_service.service_networking]
}

resource "google_service_networking_connection" "psa" {
  network                 = "projects/${var.gcp_project_id}/global/networks/${var.cr_vpc}"
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.psa_range.name]

  depends_on = [
    google_project_service.service_networking,
    google_compute_global_address.psa_range,
  ]
}
