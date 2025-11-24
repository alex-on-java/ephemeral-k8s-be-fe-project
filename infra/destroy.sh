#!/usr/bin/env bash
set -e

# ============================================
# Plants Project - Full Destruction Script
# ============================================
# This script destroys all Terraform-managed infrastructure using environment
# variables for configuration and Terraform remote state for dependencies.
#
# Prerequisites:
# - Environment variables set (see .env.example)
# ============================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Source .env file if it exists (for local development)
if [ -f "$(dirname "$0")/.env" ]; then
    echo "Loading environment variables from .env file..."
    set -a
    source "$(dirname "$0")/.env"
    set +a
    echo ""
fi

# ============================================
# Environment Variable Validation
# ============================================

echo "Validating required environment variables..."
MISSING_VARS=()

# Required for all phases
if [ -z "$TF_VAR_project_id" ]; then MISSING_VARS+=("TF_VAR_project_id"); fi
if [ -z "$TF_VAR_state_bucket_name" ]; then MISSING_VARS+=("TF_VAR_state_bucket_name"); fi

# Required for 00-prerequisites
if [ -z "$TF_VAR_proxy_subnet_name" ]; then MISSING_VARS+=("TF_VAR_proxy_subnet_name"); fi

# Required for 02-services
if [ -z "$TF_VAR_base_domain" ]; then MISSING_VARS+=("TF_VAR_base_domain"); fi
if [ -z "$TF_VAR_admin_domain" ]; then MISSING_VARS+=("TF_VAR_admin_domain"); fi
if [ -z "$TF_VAR_dns_zone_name" ]; then MISSING_VARS+=("TF_VAR_dns_zone_name"); fi
if [ -z "$TF_VAR_ssl_cert_name" ]; then MISSING_VARS+=("TF_VAR_ssl_cert_name"); fi

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo -e "${RED}ERROR: Missing required environment variables:${NC}"
    printf '%s\n' "${MISSING_VARS[@]}"
    echo ""
    echo "Please set these variables or create a .env file."
    echo "See .env.example for reference."
    exit 1
fi

# Set defaults for optional variables
TF_VAR_region=${TF_VAR_region:-europe-west3}

# Image paths don't matter for destroy, but modules expect them
export TF_VAR_java_be_full_image_path=${TF_VAR_java_be_full_image_path:-dummy:latest}
export TF_VAR_client_fe_full_image_path=${TF_VAR_client_fe_full_image_path:-dummy:latest}
export TF_VAR_admin_fe_full_image_path=${TF_VAR_admin_fe_full_image_path:-dummy:latest}

echo -e "${GREEN}✓ All required environment variables are set${NC}"
echo ""

# ============================================
# Warning and Confirmation
# ============================================

echo "==========================================="
echo "Plants Project - Full Destruction"
echo "==========================================="
echo ""
echo -e "${YELLOW}⚠️  WARNING: This will destroy all Terraform-managed infrastructure${NC}"
echo "    Estimated duration: 10-15 minutes"
echo "    Remaining cost after destruction: ~\$0.21/month (manual prerequisites only)"
echo ""
echo "The following will be DESTROYED:"
echo "  - All Kubernetes resources (deployments, services, PostgreSQL)"
echo "  - NEGs and backend services"
echo "  - Load balancer and forwarding rules"
echo "  - DNS A records"
echo "  - GKE Autopilot cluster"
echo "  - Artifact Registry (and all Docker images)"
echo "  - Static IP address"
echo "  - Firewall rules"
echo ""
echo "The following will be PRESERVED:"
echo "  - GCS state bucket ($TF_VAR_state_bucket_name)"
echo "  - DNS zone ($TF_VAR_dns_zone_name)"
echo "  - Proxy-only subnet ($TF_VAR_proxy_subnet_name)"
echo "  - SSL certificates ($TF_VAR_ssl_cert_name)"
echo ""

# Check if gum is available for better prompts
if command -v gum &> /dev/null; then
    if ! gum confirm "Continue with destruction?"; then
        echo "Destruction cancelled"
        exit 0
    fi
else
    read -p "Continue with destruction? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
        echo "Destruction cancelled"
        exit 0
    fi
fi
echo ""

# ============================================
# Check for State Locks
# ============================================

echo "Checking for Terraform state locks..."
LOCK_FILES=$(gsutil ls -r gs://$TF_VAR_state_bucket_name/ 2>/dev/null | grep -i "\.tflock$" || true)

if [ -n "$LOCK_FILES" ]; then
    echo -e "${YELLOW}⚠️  Found Terraform state lock files:${NC}"
    echo "$LOCK_FILES"
    echo ""
    echo "These locks may indicate:"
    echo "  - A previous terraform operation was interrupted"
    echo "  - Another terraform operation is currently running"
    echo ""

    if command -v gum &> /dev/null; then
        if gum confirm "Delete these lock files and continue?"; then
            SHOULD_DELETE=true
        else
            SHOULD_DELETE=false
        fi
    else
        read -p "Delete these lock files and continue? (yes/no): " -r
        if [[ $REPLY =~ ^[Yy]es$ ]]; then
            SHOULD_DELETE=true
        else
            SHOULD_DELETE=false
        fi
    fi

    if [ "$SHOULD_DELETE" = true ]; then
        echo "Deleting lock files..."
        echo "$LOCK_FILES" | while IFS= read -r lock_file; do
            if [ -n "$lock_file" ]; then
                gsutil rm "$lock_file"
                echo "  ✓ Deleted: $lock_file"
            fi
        done
        echo -e "${GREEN}✓ All locks removed${NC}"
    else
        echo "Destruction cancelled - please resolve locks manually"
        exit 1
    fi
else
    echo -e "${GREEN}✓ No state locks found${NC}"
fi
echo ""

# ============================================
# Phase 1: Destroy Services
# ============================================

echo "==========================================="
echo "Phase 1: Destroying services..."
echo "==========================================="
echo "  (K8s, NEGs, Load Balancer, DNS)"
echo ""

terraform -chdir=02-services init \
    -backend-config="bucket=$TF_VAR_state_bucket_name"

# Note: postgres_password and other shared config come from remote state
# No need to pass manually - destroy will use remote state references
terraform -chdir=02-services destroy -auto-approve

echo -e "${GREEN}✓ Services destroyed${NC}"
echo ""

# ============================================
# Phase 2: Destroy Cluster
# ============================================

echo "==========================================="
echo "Phase 2: Destroying GKE cluster..."
echo "==========================================="
echo "  (This may take 5-10 minutes)"
echo ""

terraform -chdir=01-cluster init \
    -backend-config="bucket=$TF_VAR_state_bucket_name"

terraform -chdir=01-cluster destroy -auto-approve

echo -e "${GREEN}✓ Cluster destroyed${NC}"
echo ""

# ============================================
# Phase 3: Destroy Prerequisites
# ============================================

echo "==========================================="
echo "Phase 3: Destroying prerequisites..."
echo "==========================================="
echo "  (Artifact Registry, Static IP, Firewall)"
echo ""

terraform -chdir=00-prerequisites init -backend-config="bucket=$TF_VAR_state_bucket_name"

terraform -chdir=00-prerequisites destroy -auto-approve

echo -e "${GREEN}✓ Prerequisites destroyed${NC}"
echo ""

# ============================================
# Phase 4: Cleanup Terraform Working Files
# ============================================

echo "==========================================="
echo "Phase 4: Cleaning up Terraform working files..."
echo "==========================================="
echo ""

for module in 00-prerequisites 01-cluster 02-services; do
    if [ -d "$module/.terraform" ] || [ -f "$module/.terraform.lock.hcl" ]; then
        echo "Cleaning $module..."
        rm -rf "$module/.terraform" 2>/dev/null || true
        rm "$module/.terraform.lock.hcl" 2>/dev/null || true
        echo "  ✓ Cleaned"
    fi
done

echo ""
echo -e "${GREEN}✓ Terraform working files cleaned${NC}"
echo ""

# ============================================
# Destruction Complete
# ============================================

echo "==========================================="
echo "Destruction Complete!"
echo "==========================================="
echo ""
echo "All Terraform-managed infrastructure has been destroyed."
echo ""
echo "Remaining resources (manual prerequisites):"
echo "  ✓ GCS state bucket: gs://$TF_VAR_state_bucket_name (~\$0.01/month)"
echo "  ✓ DNS zone: $TF_VAR_dns_zone_name (\$0.20/month)"
echo "  ✓ Proxy-only subnet: $TF_VAR_proxy_subnet_name (\$0)"
echo "  ✓ SSL certificates: $TF_VAR_ssl_cert_name (\$0)"
echo ""
echo "Total remaining cost: ~\$0.21/month"
echo ""
echo "To completely remove the project:"
echo "  1. Delete state bucket: gcloud storage buckets delete gs://$TF_VAR_state_bucket_name"
echo "  2. Delete DNS zone: gcloud dns managed-zones delete $TF_VAR_dns_zone_name"
echo "  3. Delete proxy subnet: gcloud compute networks subnets delete $TF_VAR_proxy_subnet_name --region=$TF_VAR_region"
echo "  4. Delete SSL cert: gcloud certificate-manager certificates delete $TF_VAR_ssl_cert_name --location=$TF_VAR_region"
echo ""
