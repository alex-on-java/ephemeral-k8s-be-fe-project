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

# Remote state from 01-cluster phase
data "terraform_remote_state" "cluster" {
  backend = "gcs"
  config = {
    bucket = var.state_bucket_name
    prefix = "01-cluster"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Data sources for cluster connection
data "google_container_cluster" "plants" {
  name     = data.terraform_remote_state.prerequisites.outputs.cluster_name
  location = var.region
}

data "google_client_config" "default" {}

# Configure kubernetes provider to connect to the cluster
provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.plants.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.plants.master_auth[0].cluster_ca_certificate)
}

# Data source for VPC network
data "google_compute_network" "vpc" {
  name = data.terraform_remote_state.prerequisites.outputs.vpc_network
}

# Data source for static IP (created in 00-prerequisites)
data "google_compute_address" "lb_ip" {
  name   = data.terraform_remote_state.prerequisites.outputs.lb_static_ip_name
  region = var.region
}

# ===================================================================
# AutoNEG Controller Installation
# ITERATION 2: Replace discovery script with AutoNEG controller
# Module creates its own namespace, K8s SA, GCP SA, and RBAC resources
# No more time_sleep or external data sources needed - AutoNEG handles everything
# ===================================================================

# Install AutoNEG controller using official Terraform module
# Watches Services with NEG annotations and automatically attaches NEGs to backend services
# Module manages all resources: namespace (autoneg-system), K8s SA, GCP SA, RBAC
module "autoneg" {
  source     = "github.com/GoogleCloudPlatform/gke-autoneg-controller//terraform/autoneg?ref=v1.5.0"
  project_id = var.project_id
}
