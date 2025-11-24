terraform {
  backend "gcs" {
    # bucket provided via -backend-config in deploy.sh
    prefix = "01-cluster"
  }
}
