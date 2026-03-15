terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  backend "gcs" {
    bucket = "ctf-nuttee-tfstate"
    prefix = "cftd"
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

module "ctfd" {
  source = "./modules/ctfd"

  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  gcp_zone       = var.gcp_zone

  gcs_bucket        = var.gcs_bucket
  gcs_bucket_region = var.gcs_bucket_region

  cr_vpc    = var.cr_vpc
  cr_subnet = var.cr_subnet
  cr_sa_name = var.cr_sa_name

  cloud_sql_instance_name = var.cloud_sql_instance_name
  db_name                 = var.db_name
  db_user                 = var.db_user
  db_password             = var.db_password

  redis_instance_name = var.redis_instance_name
}

output "cloud_run_url" {
  description = "CTFd Cloud Run service URL"
  value       = module.ctfd.cloud_run_url
}

output "service_account_email" {
  description = "CTFd Cloud Run service account email"
  value       = module.ctfd.service_account_email
}

output "cloud_sql_connection_name" {
  description = "Cloud SQL instance connection name"
  value       = module.ctfd.cloud_sql_connection_name
}

output "redis_host" {
  description = "Cloud Memorystore Redis host IP"
  value       = module.ctfd.redis_host
}
