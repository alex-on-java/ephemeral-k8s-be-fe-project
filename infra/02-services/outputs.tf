# Outputs for 02-services phase

# ===================================================================
# Service URLs
# ===================================================================

output "client_url" {
  description = "URL for client frontend"
  value       = "https://${var.base_domain}"
}

output "admin_url" {
  description = "URL for admin frontend"
  value       = "https://${var.admin_domain}"
}

output "api_url" {
  description = "URL for backend API"
  value       = "https://${var.base_domain}/api"
}

output "seed_url" {
  description = "URL for database seeding endpoint"
  value       = "https://${var.base_domain}/api/admin/seed"
}

# ===================================================================
# Load Balancer Details
# ===================================================================

output "lb_ip_address" {
  description = "Load balancer IP address"
  value       = data.google_compute_address.lb_ip.address
}

output "backend_services" {
  description = "Backend service IDs"
  value = {
    java_be   = google_compute_region_backend_service.java_be.id
    client_fe = google_compute_region_backend_service.client_fe.id
    admin_fe  = google_compute_region_backend_service.admin_fe.id
  }
}

# ===================================================================
# NEG Details
# ===================================================================

output "negs_summary" {
  description = "NEG management via AutoNEG controller"
  value = {
    note = "NEGs created automatically by GKE and attached to backend services by AutoNEG controller"
    verification = [
      "List NEGs: gcloud compute network-endpoint-groups list --filter='name~-svc-neg'",
      "Check AutoNEG controller: kubectl logs -n autoneg-system -l control-plane=controller-manager"
    ]
  }
}

# ===================================================================
# SSL Certificate Details
# ===================================================================

output "ssl_certificate" {
  description = "Certificate Manager certificate reference (manual prerequisite)"
  value = {
    name     = "plants-regional-cert"
    path     = local.cert_full_path
    url      = local.cert_url
    domains  = [var.base_domain, var.admin_domain]
    note     = "Certificate is manually managed. Check status with: gcloud certificate-manager certificates describe plants-regional-cert --location=${var.region}"
  }
}

# ===================================================================
# Kubernetes Resources
# ===================================================================

output "k8s_namespace" {
  description = "Kubernetes namespace name"
  value       = kubernetes_namespace.plants.metadata[0].name
}

output "postgres_service" {
  description = "PostgreSQL service endpoint (internal)"
  value       = "postgres.${var.k8s_namespace}.svc.cluster.local:5432"
}

# ===================================================================
# Next Steps
# ===================================================================

output "next_steps" {
  description = "Next steps after deployment"
  value = <<-EOT

  ✅ Infrastructure deployed successfully!

  📋 Next steps:

  1. Verify backends are HEALTHY (may take 1-2 minutes):
     gcloud compute backend-services get-health plants-java-be-backend --region=${var.region}
     gcloud compute backend-services get-health plants-client-fe-backend --region=${var.region}
     gcloud compute backend-services get-health plants-admin-fe-backend --region=${var.region}

  2. Test HTTPS endpoints:
     curl https://${var.base_domain}
     curl https://${var.base_domain}/api/actuator/health
     curl https://${var.admin_domain}

  3. Seed database:
     curl -X POST https://${var.base_domain}/api/admin/seed

  4. Access applications:
     - Client: https://${var.base_domain}
     - Admin:  https://${var.admin_domain}

  🎉 No manual steps required!
  EOT
}
