output "cloud_run_url" {
  description = "CTFd Cloud Run service URL"
  value       = google_cloud_run_v2_service.ctfd.uri
}

output "service_account_email" {
  description = "CTFd Cloud Run service account email"
  value       = google_service_account.ctfd_runner.email
}

output "cloud_sql_connection_name" {
  description = "Cloud SQL instance connection name (project:region:instance)"
  value       = google_sql_database_instance.ctfd.connection_name
}

output "cloud_sql_private_ip" {
  description = "Cloud SQL instance private IP address"
  value       = google_sql_database_instance.ctfd.private_ip_address
}

output "redis_host" {
  description = "Cloud Memorystore Redis host IP address"
  value       = google_redis_instance.ctfd.host
}

output "gcs_bucket_name" {
  description = "GCS bucket name used for CTFd image uploads"
  value       = google_storage_bucket.ctfd_uploads.name
}
