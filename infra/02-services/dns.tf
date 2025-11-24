# DNS and SSL Certificate Configuration
# CRITICAL CHANGES from original:
# 1. SSL certificates are now DATA SOURCES (manual prerequisites, not managed)
# 2. DNS authorization records removed (certificates created manually handle their own validation)
# 3. A records updated to use static IP data source from 00-prerequisites

# ===================================================================
# Cloud DNS Zone Reference (Manual Prerequisite)
# ===================================================================

# Reference to manually created Cloud DNS zone
# Zone was created outside Terraform to ensure NS records remain stable
# across terraform destroy/apply cycles
data "google_dns_managed_zone" "plants" {
  name = var.dns_zone_name
}

# ===================================================================
# SSL Certificates (Manual Prerequisites - Certificate Manager)
# ===================================================================

# Manual prerequisite: Certificate Manager certificate created via infra/setup-prerequisites.sh
# Certificate referenced directly by full resource path (no data source available)
#
# The certificate must exist in the specified region:
# - Covers both base_domain and admin_domain
# - Uses DNS authorization (automated CNAME validation)
# - Auto-renews by Google
# - Persists across destroy/recreate cycles
#
# NOTE: Google provider has NO data source for Certificate Manager certificates
# We reference the certificate directly using its full resource path
locals {
  # Full Certificate Manager resource path
  cert_full_path = "projects/${var.project_id}/locations/${var.region}/certificates/${var.ssl_cert_name}"

  # Certificate Manager URL format (required for regional HTTPS proxy)
  cert_url = "//certificatemanager.googleapis.com/${local.cert_full_path}"
}

# ===================================================================
# DNS Records (Managed by Terraform)
# ===================================================================

# A record for base domain
resource "google_dns_record_set" "plants_a" {
  name         = "${var.base_domain}."
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.plants.name
  rrdatas      = [data.google_compute_address.lb_ip.address]
}

# A record for admin domain
resource "google_dns_record_set" "admin_plants_a" {
  name         = "${var.admin_domain}."
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.plants.name
  rrdatas      = [data.google_compute_address.lb_ip.address]
}
