terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Data source for existing VPC network
data "google_compute_network" "vpc" {
  name = var.vpc_network
}

# Reference existing proxy-only subnet (manual prerequisite)
data "google_compute_subnetwork" "proxy_only" {
  name   = var.proxy_subnet_name
  region = var.region
}

# Static IP address for load balancer
resource "google_compute_address" "lb_ip" {
  name   = "plants-lb-ip"
  region = var.region
}

# Artifact Registry for container images
resource "google_artifact_registry_repository" "plants" {
  location      = var.region
  repository_id = var.artifact_registry_name
  description   = "Docker repository for plants project containers"
  format        = "DOCKER"

  cleanup_policies {
    id     = "keep-minimum-versions"
    action = "KEEP"
    most_recent_versions {
      keep_count = 5
    }
  }
}
