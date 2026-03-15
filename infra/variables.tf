variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP Region"
  type        = string
}

variable "gcp_zone" {
  description = "GCP Zone for single-zone deployments"
  type        = string
}

variable "gcs_bucket" {
  description = "GCS Bucket name for CTFd image uploads via GCS FUSE"
  type        = string
}

variable "gcs_bucket_region" {
  description = "GCS Bucket location"
  type        = string
}

variable "cr_vpc" {
  description = "VPC network name for Cloud Run Direct VPC Egress"
  type        = string
}

variable "cr_subnet" {
  description = "Subnetwork name for Cloud Run Direct VPC Egress"
  type        = string
}

variable "cr_sa_name" {
  description = "Service Account account_id for Cloud Run (e.g. ctfd-cloud-run-sa)"
  type        = string
}

variable "cloud_sql_instance_name" {
  description = "Cloud SQL instance name"
  type        = string
  default     = "ctfd-mysql"
}

variable "db_name" {
  description = "MySQL database name for CTFd"
  type        = string
  default     = "ctfd"
}

variable "db_user" {
  description = "MySQL database user for CTFd"
  type        = string
  default     = "ctfd"
}

variable "db_password" {
  description = "MySQL database password for CTFd — set via TF_VAR_db_password or secrets.auto.tfvars (do not commit)"
  type        = string
  sensitive   = true
}

variable "redis_instance_name" {
  description = "Cloud Memorystore Redis instance name"
  type        = string
  default     = "ctfd-redis"
}
