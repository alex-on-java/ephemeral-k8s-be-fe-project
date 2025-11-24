terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Remote state from 00-prerequisites phase
data "terraform_remote_state" "prerequisites" {
  backend = "gcs"
  config = {
    bucket = var.state_bucket_name
    prefix = "00-prerequisites"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Data source for existing VPC network
data "google_compute_network" "vpc" {
  name = data.terraform_remote_state.prerequisites.outputs.vpc_network
}

# GKE Autopilot Cluster
resource "google_container_cluster" "plants" {
  name     = data.terraform_remote_state.prerequisites.outputs.cluster_name
  location = var.region

  # Autopilot mode
  enable_autopilot = true

  # Allow easy destroy for ephemeral demo project
  deletion_protection = false

  # Network configuration
  network    = data.google_compute_network.vpc.name
  subnetwork = "default"

  # IP allocation for pods and services
  # VPC-native networking required for NEG support
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = ""
    services_ipv4_cidr_block = ""
  }

  # Release channel for auto-upgrades
  release_channel {
    channel = "REGULAR"
  }

  # Maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  # Enable Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

# Configure kubernetes provider to connect to the cluster
provider "kubernetes" {
  host                   = "https://${google_container_cluster.plants.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.plants.master_auth[0].cluster_ca_certificate)
}

# Data source for GCP client config (for k8s provider auth)
data "google_client_config" "default" {}

# Generate random password for PostgreSQL
resource "random_password" "postgres" {
  length  = 16
  special = true
}
