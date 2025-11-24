# Firewall Rules for Plants Project

# Rule 1: Allow Google Cloud Load Balancer health checks to reach pods
# Source: https://cloud.google.com/load-balancing/docs/health-check-concepts#ip-ranges
resource "google_compute_firewall" "allow_health_checks" {
  name    = "allow-health-check-to-gke-plants"
  network = data.google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "8080"]
  }

  # Google Cloud health check IP ranges
  source_ranges = [
    "35.191.0.0/16",    # Global load balancer health checks
    "130.211.0.0/22"    # Legacy health checks
  ]

  description = "Allow Google Cloud health checks to reach GKE pods"
}

# Rule 2: Allow traffic from proxy subnet to backend pods
# FIXED: Removed target_tags (incompatible with GKE Autopilot)
resource "google_compute_firewall" "allow_proxy_to_backends" {
  name    = "allow-proxy-to-plants-backends"
  network = data.google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "443"]
  }

  source_ranges = [data.google_compute_subnetwork.proxy_only.ip_cidr_range]

  # target_tags removed - GKE Autopilot doesn't support node tags
  # Rule now applies to all instances in the network

  description = "Allow traffic from load balancer proxy subnet to backend pods"
}
