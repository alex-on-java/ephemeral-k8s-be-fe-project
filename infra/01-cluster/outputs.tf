# Outputs for 01-cluster phase
# These values are used by 02-services phase

output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.plants.name
}

output "cluster_id" {
  description = "GKE cluster ID"
  value       = google_container_cluster.plants.id
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.plants.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = base64decode(google_container_cluster.plants.master_auth[0].cluster_ca_certificate)
  sensitive   = true
}

output "postgres_password" {
  description = "Generated PostgreSQL password"
  value       = random_password.postgres.result
  sensitive   = true
}

output "cluster_location" {
  description = "GKE cluster location (region)"
  value       = google_container_cluster.plants.location
}
