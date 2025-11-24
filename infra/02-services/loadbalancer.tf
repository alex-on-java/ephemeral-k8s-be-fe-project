# Load Balancer Configuration for Plants Project
# ITERATION 1 FIX APPLIED:
# 1. SSL certificates removed (now manual prerequisites, referenced as data sources in dns.tf)
# 2. Backend services now have dynamic backend blocks (references GKE-created NEGs via external data)
# 3. Static IP referenced via data source (created in 00-prerequisites)
# 4. NEGs discovered via external data source after GKE creates them

# ===================================================================
# Health Checks
# ===================================================================

# Health check for Java Backend
resource "google_compute_region_health_check" "java_be" {
  name   = "plants-java-be-hc"
  region = var.region

  http_health_check {
    port         = 8080
    request_path = "/actuator/health"
  }

  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

# Health check for Client Frontend
resource "google_compute_region_health_check" "client_fe" {
  name   = "plants-client-fe-hc"
  region = var.region

  http_health_check {
    port         = 80
    request_path = "/"
  }

  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

# Health check for Admin Frontend
resource "google_compute_region_health_check" "admin_fe" {
  name   = "plants-admin-fe-hc"
  region = var.region

  http_health_check {
    port         = 80
    request_path = "/"
  }

  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

# ===================================================================
# Backend Services with Dynamic Backend Blocks
# ===================================================================

# Backend service for Java Backend
# Automatically attaches all GKE-created NEGs discovered via external data
resource "google_compute_region_backend_service" "java_be" {
  name                  = "plants-java-be-backend"
  region                = var.region
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks         = [google_compute_region_health_check.java_be.id]

  # ITERATION 2: AutoNEG controller manages backend attachments
  # No backend blocks - AutoNEG discovers NEGs and attaches them automatically
  # ignore_changes prevents Terraform from removing AutoNEG-managed backends

  log_config {
    enable      = true
    sample_rate = 1.0
  }

  lifecycle {
    ignore_changes = [backend]
  }
}

# Backend service for Client Frontend
# Automatically attaches all GKE-created NEGs discovered via external data
resource "google_compute_region_backend_service" "client_fe" {
  name                  = "plants-client-fe-backend"
  region                = var.region
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks         = [google_compute_region_health_check.client_fe.id]

  # ITERATION 2: AutoNEG controller manages backend attachments
  # No backend blocks - AutoNEG discovers NEGs and attaches them automatically
  # ignore_changes prevents Terraform from removing AutoNEG-managed backends

  log_config {
    enable      = true
    sample_rate = 1.0
  }

  lifecycle {
    ignore_changes = [backend]
  }
}

# Backend service for Admin Frontend
# Automatically attaches all GKE-created NEGs discovered via external data
resource "google_compute_region_backend_service" "admin_fe" {
  name                  = "plants-admin-fe-backend"
  region                = var.region
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks         = [google_compute_region_health_check.admin_fe.id]

  # ITERATION 2: AutoNEG controller manages backend attachments
  # No backend blocks - AutoNEG discovers NEGs and attaches them automatically
  # ignore_changes prevents Terraform from removing AutoNEG-managed backends

  log_config {
    enable      = true
    sample_rate = 1.0
  }

  lifecycle {
    ignore_changes = [backend]
  }
}

# ===================================================================
# URL Map with Host-based Routing
# ===================================================================

resource "google_compute_region_url_map" "plants" {
  name            = "plants-url-map"
  region          = var.region
  default_service = google_compute_region_backend_service.client_fe.id

  host_rule {
    hosts        = [var.base_domain]
    path_matcher = "client-paths"
  }

  host_rule {
    hosts        = [var.admin_domain]
    path_matcher = "admin-paths"
  }

  # Path matcher for base domain
  path_matcher {
    name            = "client-paths"
    default_service = google_compute_region_backend_service.client_fe.id

    path_rule {
      paths   = ["/api/*"]
      service = google_compute_region_backend_service.java_be.id
    }
  }

  # Path matcher for admin domain
  path_matcher {
    name            = "admin-paths"
    default_service = google_compute_region_backend_service.admin_fe.id

    path_rule {
      paths   = ["/api/*"]
      service = google_compute_region_backend_service.java_be.id
    }
  }
}

# ===================================================================
# Target HTTPS Proxy
# ===================================================================

# Note: Certificate Manager certificate is manual prerequisite, referenced by ID in dns.tf
resource "google_compute_region_target_https_proxy" "plants" {
  name    = "plants-https-proxy"
  region  = var.region
  url_map = google_compute_region_url_map.plants.id

  # Certificate Manager certificate from manual prerequisite (local variable in dns.tf)
  # Single cert covers both base_domain and admin_domain
  # Uses full Certificate Manager URL format
  certificate_manager_certificates = [local.cert_url]
}

# ===================================================================
# Forwarding Rule (uses static IP from 00-prerequisites)
# ===================================================================

resource "google_compute_forwarding_rule" "plants_https" {
  name                  = "plants-https-fr"
  region                = var.region
  ip_address            = data.google_compute_address.lb_ip.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_region_target_https_proxy.plants.id
  network               = data.google_compute_network.vpc.id
}

# ===================================================================
# HTTP to HTTPS Redirect
# ===================================================================

resource "google_compute_region_url_map" "http_redirect" {
  name   = "plants-http-redirect"
  region = var.region

  default_url_redirect {
    https_redirect         = true
    strip_query            = false
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
  }
}

resource "google_compute_region_target_http_proxy" "plants" {
  name    = "plants-http-proxy"
  region  = var.region
  url_map = google_compute_region_url_map.http_redirect.id
}

resource "google_compute_forwarding_rule" "plants_http" {
  name                  = "plants-http-fr"
  region                = var.region
  ip_address            = data.google_compute_address.lb_ip.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_region_target_http_proxy.plants.id
  network               = data.google_compute_network.vpc.id
}
