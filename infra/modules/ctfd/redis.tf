# Cloud Memorystore Redis — Basic tier, 1 GB (minimum capacity), private service access
# Cloud Run connects via Direct VPC Egress on the same VPC (private IP reachable through PSA peering)
resource "google_redis_instance" "ctfd" {
  project        = var.gcp_project_id
  name           = var.redis_instance_name
  tier           = "BASIC"
  memory_size_gb = 1 # minimum supported capacity

  region      = var.gcp_region
  location_id = var.gcp_zone

  # Connect via Private Service Access — Cloud Run reaches Redis through Direct VPC Egress
  authorized_network = "projects/${var.gcp_project_id}/global/networks/${var.cr_vpc}"
  connect_mode       = "PRIVATE_SERVICE_ACCESS"

  redis_version = "REDIS_7_0"

  depends_on = [
    google_project_service.redis_api,
    google_service_networking_connection.psa,
  ]
}
