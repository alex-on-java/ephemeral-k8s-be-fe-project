# Variables for 01-cluster phase

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "europe-west3"
}

# Manual prerequisite (for remote state backend config)
variable "state_bucket_name" {
  description = "GCS bucket name for Terraform state (manual prerequisite)"
  type        = string
}

# Note: vpc_network and cluster_name are consumed from 00-prerequisites remote state
