# Variables for 00-prerequisites phase

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "europe-west3"
}

variable "vpc_network" {
  description = "VPC network to use"
  type        = string
  default     = "default"
}

variable "cluster_name" {
  description = "GKE cluster name (shared config - output to remote state)"
  type        = string
  default     = "plants-cluster"
}

variable "artifact_registry_name" {
  description = "Name of the Artifact Registry repository (shared config - output to remote state)"
  type        = string
  default     = "plants-registry"
}

# Manual prerequisites (must be created before Terraform runs)
variable "state_bucket_name" {
  description = "GCS bucket name for Terraform state (manual prerequisite)"
  type        = string
}

variable "proxy_subnet_name" {
  description = "Proxy-only subnet name for load balancer (manual prerequisite)"
  type        = string
}
