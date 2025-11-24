# Variables for 02-services phase

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "europe-west3"
}

variable "zones" {
  description = "List of zones within the region for multi-zone NEG distribution"
  type        = list(string)
  default     = ["a", "b", "c"]
}

variable "k8s_namespace" {
  description = "Kubernetes namespace for plants workloads"
  type        = string
  default     = "plants"
}

# Secrets (must be provided via environment variables)
variable "base_domain" {
  description = "Base domain for the plants project (secret - via TF_VAR_base_domain)"
  type        = string
}

variable "admin_domain" {
  description = "Admin domain for the plants project (secret - via TF_VAR_admin_domain)"
  type        = string
}

# Manual prerequisites (must be created before Terraform runs)
variable "state_bucket_name" {
  description = "GCS bucket name for Terraform state (manual prerequisite)"
  type        = string
}

variable "dns_zone_name" {
  description = "Name of the Cloud DNS managed zone (manual prerequisite - via TF_VAR_dns_zone_name)"
  type        = string
}

variable "ssl_cert_name" {
  description = "Name of the SSL certificate (manual prerequisite - via TF_VAR_ssl_cert_name)"
  type        = string
}

# Full image paths (deploy-time configuration - must be provided)
variable "java_be_full_image_path" {
  description = "Full Docker image path including registry and tag for Java backend (e.g., europe-west10-docker.pkg.dev/project/registry/plants_backend:latest)"
  type        = string
}

variable "client_fe_full_image_path" {
  description = "Full Docker image path including registry and tag for client frontend (e.g., europe-west10-docker.pkg.dev/project/registry/plants_frontend:latest)"
  type        = string
}

variable "admin_fe_full_image_path" {
  description = "Full Docker image path including registry and tag for admin frontend (e.g., europe-west10-docker.pkg.dev/project/registry/plants_admin:latest)"
  type        = string
}

# Service configurations (with sensible defaults)
variable "services" {
  description = "Map of service configurations for NEG creation and load balancing"
  type = map(object({
    name      = string
    namespace = string
    port      = number
  }))
  default = {
    "java-be" = {
      name      = "java-be-svc"
      namespace = "plants"
      port      = 8080
    }
    "client-fe" = {
      name      = "client-fe-svc"
      namespace = "plants"
      port      = 80
    }
    "admin-fe" = {
      name      = "admin-fe-svc"
      namespace = "plants"
      port      = 80
    }
  }
}

# Note: vpc_network, cluster_name, artifact_registry_name, postgres_password, and lb_static_ip_name
# are now consumed from remote state (00-prerequisites and 01-cluster)
