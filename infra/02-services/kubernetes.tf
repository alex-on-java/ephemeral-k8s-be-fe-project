# Kubernetes Resources for Plants Project
# ITERATION 1 FIX APPLIED:
# 1. NEG annotations ADDED to all services - GKE creates NEGs automatically
# 2. Service type changed from NodePort to ClusterIP (required for NEGs)
# 3. Image tags PARAMETERIZED using variables
# 4. PostgreSQL password from 01-cluster phase

# Kubernetes namespace for plants application
resource "kubernetes_namespace" "plants" {
  metadata {
    name = var.k8s_namespace
  }
}

# Kubernetes Secret for PostgreSQL password (from 01-cluster via remote state)
resource "kubernetes_secret" "postgres_credentials" {
  metadata {
    name      = "postgres-credentials"
    namespace = kubernetes_namespace.plants.metadata[0].name
  }

  data = {
    POSTGRES_PASSWORD = data.terraform_remote_state.cluster.outputs.postgres_password
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.plants]
}

# ConfigMap for database configuration
resource "kubernetes_config_map" "postgres_config" {
  metadata {
    name      = "postgres-config"
    namespace = kubernetes_namespace.plants.metadata[0].name
  }

  data = {
    POSTGRES_HOST = "postgres.${var.k8s_namespace}.svc.cluster.local"
    POSTGRES_PORT = "5432"
    POSTGRES_DB   = "plantsdb"
    POSTGRES_USER = "plantsuser"
  }

  depends_on = [kubernetes_namespace.plants]
}

# ===================================================================
# Kubernetes Services (WITH NEG annotations - GKE creates NEGs)
# ===================================================================

# Java Backend Service
# ITERATION 1 FIX: NEG annotation added - GKE will create NEGs automatically
resource "kubernetes_service" "java_be" {
  metadata {
    name      = "java-be-svc"
    namespace = kubernetes_namespace.plants.metadata[0].name
    annotations = {
      # GKE creates NEGs with this name
      "cloud.google.com/neg" = jsonencode({
        exposed_ports = {
          "8080" = {
            name = "java-be-svc-neg"
          }
        }
      })
      # AutoNEG attaches those NEGs to the backend service
      "controller.autoneg.dev/neg" = jsonencode({
        backend_services = {
          "8080" = [{
            name                  = "plants-java-be-backend"
            region                = var.region
            max_rate_per_endpoint = 100
          }]
        }
      })
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "java-be"
    }

    port {
      name        = "http"
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }
  }

  # CRITICAL: Service must be destroyed BEFORE backend service and AutoNEG controller
  # This ensures AutoNEG controller is alive to remove finalizers during service deletion
  depends_on = [
    kubernetes_namespace.plants,
    module.autoneg,
    google_compute_region_backend_service.java_be
  ]
}

# Client Frontend Service
# ITERATION 1 FIX: NEG annotation added - GKE will create NEGs automatically
resource "kubernetes_service" "client_fe" {
  metadata {
    name      = "client-fe-svc"
    namespace = kubernetes_namespace.plants.metadata[0].name
    annotations = {
      # GKE creates NEGs with this name
      "cloud.google.com/neg" = jsonencode({
        exposed_ports = {
          "80" = {
            name = "client-fe-svc-neg"
          }
        }
      })
      # AutoNEG attaches those NEGs to the backend service
      "controller.autoneg.dev/neg" = jsonencode({
        backend_services = {
          "80" = [{
            name                  = "plants-client-fe-backend"
            region                = var.region
            max_rate_per_endpoint = 100
          }]
        }
      })
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "client-fe"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
  }

  # CRITICAL: Service must be destroyed BEFORE backend service and AutoNEG controller
  # This ensures AutoNEG controller is alive to remove finalizers during service deletion
  depends_on = [
    kubernetes_namespace.plants,
    module.autoneg,
    google_compute_region_backend_service.client_fe
  ]
}

# Admin Frontend Service
# ITERATION 1 FIX: NEG annotation added - GKE will create NEGs automatically
resource "kubernetes_service" "admin_fe" {
  metadata {
    name      = "admin-fe-svc"
    namespace = kubernetes_namespace.plants.metadata[0].name
    annotations = {
      # GKE creates NEGs with this name
      "cloud.google.com/neg" = jsonencode({
        exposed_ports = {
          "80" = {
            name = "admin-fe-svc-neg"
          }
        }
      })
      # AutoNEG attaches those NEGs to the backend service
      "controller.autoneg.dev/neg" = jsonencode({
        backend_services = {
          "80" = [{
            name                  = "plants-admin-fe-backend"
            region                = var.region
            max_rate_per_endpoint = 100
          }]
        }
      })
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "admin-fe"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
  }

  # CRITICAL: Service must be destroyed BEFORE backend service and AutoNEG controller
  # This ensures AutoNEG controller is alive to remove finalizers during service deletion
  depends_on = [
    kubernetes_namespace.plants,
    module.autoneg,
    google_compute_region_backend_service.admin_fe
  ]
}

# ===================================================================
# PostgreSQL Database
# ===================================================================

# PostgreSQL Service (ClusterIP for internal access)
resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.plants.metadata[0].name
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "postgres"
    }

    port {
      name        = "postgres"
      port        = 5432
      target_port = 5432
      protocol    = "TCP"
    }
  }

  depends_on = [kubernetes_namespace.plants]
}

# PostgreSQL StatefulSet
resource "kubernetes_stateful_set" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.plants.metadata[0].name
  }

  spec {
    service_name = "postgres"
    replicas     = 1

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        container {
          name  = "postgres"
          image = "postgres:16-alpine"

          port {
            container_port = 5432
            name           = "postgres"
          }

          env {
            name = "POSTGRES_DB"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.postgres_config.metadata[0].name
                key  = "POSTGRES_DB"
              }
            }
          }

          env {
            name = "POSTGRES_USER"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.postgres_config.metadata[0].name
                key  = "POSTGRES_USER"
              }
            }
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_credentials.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          # REQUIRED: PGDATA must point to subdirectory to avoid
          # "directory exists but is not empty" error caused by
          # GKE PVC creating lost+found directory at mount point
          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/postgresql/data"
          }

          resources {
            requests = {
              memory = "1Gi"
              cpu    = "500m"
            }
            limits = {
              memory = "2Gi"
              cpu    = "1000m"
            }
          }

          readiness_probe {
            exec {
              command = ["pg_isready", "-U", "plantsuser", "-d", "plantsdb"]
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          liveness_probe {
            exec {
              command = ["pg_isready", "-U", "plantsuser", "-d", "plantsdb"]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 5
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "postgres-data"
      }

      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "standard"

        resources {
          requests = {
            storage = "2Gi"
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_service.postgres,
    kubernetes_config_map.postgres_config,
    kubernetes_secret.postgres_credentials
  ]
}

# ===================================================================
# Backend Application (Java/Spring Boot)
# ===================================================================

resource "kubernetes_deployment" "java_be" {
  metadata {
    name      = "java-be"
    namespace = kubernetes_namespace.plants.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "java-be"
      }
    }

    template {
      metadata {
        labels = {
          app = "java-be"
        }
      }

      spec {
        container {
          name = "java-be"
          # Full image path from deploy.sh
          image = var.java_be_full_image_path

          port {
            container_port = 8080
            name           = "http"
          }

          env {
            name = "POSTGRES_HOST"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.postgres_config.metadata[0].name
                key  = "POSTGRES_HOST"
              }
            }
          }

          env {
            name = "POSTGRES_PORT"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.postgres_config.metadata[0].name
                key  = "POSTGRES_PORT"
              }
            }
          }

          env {
            name = "POSTGRES_DB"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.postgres_config.metadata[0].name
                key  = "POSTGRES_DB"
              }
            }
          }

          env {
            name = "POSTGRES_USER"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.postgres_config.metadata[0].name
                key  = "POSTGRES_USER"
              }
            }
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_credentials.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          resources {
            requests = {
              memory = "512Mi"
              cpu    = "250m"
            }
            limits = {
              memory = "1Gi"
              cpu    = "1000m"
            }
          }

          readiness_probe {
            http_get {
              path = "/actuator/health"
              port = 8080
            }
            initial_delay_seconds = 20
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          liveness_probe {
            http_get {
              path = "/actuator/health"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_stateful_set.postgres,
    kubernetes_service.java_be
  ]
}

# ===================================================================
# Client Frontend (React/Vite)
# ===================================================================

resource "kubernetes_deployment" "client_fe" {
  metadata {
    name      = "client-fe"
    namespace = kubernetes_namespace.plants.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "client-fe"
      }
    }

    template {
      metadata {
        labels = {
          app = "client-fe"
        }
      }

      spec {
        container {
          name = "client-fe"
          # Full image path from deploy.sh
          image = var.client_fe_full_image_path

          port {
            container_port = 80
            name           = "http"
          }

          resources {
            requests = {
              memory = "64Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "256Mi"
              cpu    = "500m"
            }
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 80
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.client_fe]
}

# ===================================================================
# Admin Frontend (React/Vite + Bun)
# ===================================================================

resource "kubernetes_deployment" "admin_fe" {
  metadata {
    name      = "admin-fe"
    namespace = kubernetes_namespace.plants.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "admin-fe"
      }
    }

    template {
      metadata {
        labels = {
          app = "admin-fe"
        }
      }

      spec {
        container {
          name = "admin-fe"
          # Full image path from deploy.sh
          image = var.admin_fe_full_image_path

          port {
            container_port = 80
            name           = "http"
          }

          resources {
            requests = {
              memory = "64Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "256Mi"
              cpu    = "500m"
            }
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 80
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.admin_fe]
}
