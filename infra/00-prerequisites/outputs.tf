# Outputs for 00-prerequisites phase
# These values are used by subsequent phases (01-cluster, 02-services)

output "artifact_registry_url" {
  description = "Full URL of the Artifact Registry repository"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_name}"
}

output "artifact_registry_repository" {
  description = "Artifact Registry repository resource"
  value       = google_artifact_registry_repository.plants.id
}

output "lb_static_ip" {
  description = "Static IP address for the load balancer"
  value       = google_compute_address.lb_ip.address
}

output "lb_static_ip_name" {
  description = "Name of the static IP resource"
  value       = google_compute_address.lb_ip.name
}

output "vpc_network" {
  description = "VPC network name"
  value       = data.google_compute_network.vpc.name
}

output "vpc_network_id" {
  description = "VPC network ID"
  value       = data.google_compute_network.vpc.id
}

output "proxy_subnet_cidr" {
  description = "CIDR range of the proxy-only subnet"
  value       = data.google_compute_subnetwork.proxy_only.ip_cidr_range
}

# Shared configuration outputs for downstream modules
output "cluster_name" {
  description = "GKE cluster name (shared config)"
  value       = var.cluster_name
}

output "artifact_registry_name" {
  description = "Artifact Registry repository name (shared config)"
  value       = var.artifact_registry_name
}
