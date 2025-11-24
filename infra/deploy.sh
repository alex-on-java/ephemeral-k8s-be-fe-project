#!/usr/bin/env bash
set -e

# ============================================
# Plants Project - Full Deployment Script
# ============================================
# This script deploys the complete infrastructure using environment variables
# for secrets and Terraform remote state for inter-module communication.
#
# Prerequisites:
# - Manual resources created
# - Environment variables set (see .env.example)
# - Docker images built and tagged
# ============================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================
# Command-Line Argument Parsing
# ============================================

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Deploy the Plants Project infrastructure to GCP.

Options:
    --java-be-image IMAGE      Java backend Docker image (tag or ID)
    --client-fe-image IMAGE    Client frontend Docker image (tag or ID)
    --admin-fe-image IMAGE     Admin frontend Docker image (tag or ID)
    --help                     Show this help message

Environment Variables:
    All configuration can be set via environment variables.
    See .env.example for the complete list.

Examples:
    # Using environment variables from .env file
    $(basename "$0")

    # Override specific images
    $(basename "$0") --java-be-image d76sa78f6ds --client-fe-image plants_frontend:v1.2.0

    # Using only command-line arguments (all images required)
    $(basename "$0") --java-be-image plants_backend --client-fe-image plants_frontend --admin-fe-image plants_admin

EOF
    exit 0
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --java-be-image)
            JAVA_BE_IMAGE="$2"
            shift 2
            ;;
        --client-fe-image)
            CLIENT_FE_IMAGE="$2"
            shift 2
            ;;
        --admin-fe-image)
            ADMIN_FE_IMAGE="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}ERROR: Unknown option: $1${NC}"
            echo "Run '$(basename "$0") --help' for usage information."
            exit 1
            ;;
    esac
done

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

# Required Docker images
if [ -z "$JAVA_BE_IMAGE" ]; then MISSING_VARS+=("JAVA_BE_IMAGE"); fi
if [ -z "$CLIENT_FE_IMAGE" ]; then MISSING_VARS+=("CLIENT_FE_IMAGE"); fi
if [ -z "$ADMIN_FE_IMAGE" ]; then MISSING_VARS+=("ADMIN_FE_IMAGE"); fi

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

echo -e "${GREEN}✓ All required environment variables are set${NC}"
echo ""
echo "Configuration Summary:"
echo "  Project ID: $TF_VAR_project_id"
echo "  Region: $TF_VAR_region"
echo "  State Bucket: $TF_VAR_state_bucket_name"
echo "  Base Domain: $TF_VAR_base_domain"
echo "  Admin Domain: $TF_VAR_admin_domain"
echo "  DNS Zone: $TF_VAR_dns_zone_name"
echo "  SSL Cert: $TF_VAR_ssl_cert_name"
echo "  Docker Images:"
echo "    Java BE: $JAVA_BE_IMAGE"
echo "    Client FE: $CLIENT_FE_IMAGE"
echo "    Admin FE: $ADMIN_FE_IMAGE"
echo ""

# ============================================
# .env Format Validation
# ============================================

# Validate that all image variables contain tags (have a colon)
echo "Validating .env image format..."
VALIDATION_FAILED=false

if [[ ! "$JAVA_BE_IMAGE" == *:* ]]; then
    echo -e "${RED}ERROR: JAVA_BE_IMAGE must include a tag (e.g., plants_backend:latest)${NC}"
    echo "Current value: $JAVA_BE_IMAGE"
    VALIDATION_FAILED=true
fi

if [[ ! "$CLIENT_FE_IMAGE" == *:* ]]; then
    echo -e "${RED}ERROR: CLIENT_FE_IMAGE must include a tag (e.g., plants_frontend:latest)${NC}"
    echo "Current value: $CLIENT_FE_IMAGE"
    VALIDATION_FAILED=true
fi

if [[ ! "$ADMIN_FE_IMAGE" == *:* ]]; then
    echo -e "${RED}ERROR: ADMIN_FE_IMAGE must include a tag (e.g., plants_admin:latest)${NC}"
    echo "Current value: $ADMIN_FE_IMAGE"
    VALIDATION_FAILED=true
fi

if [ "$VALIDATION_FAILED" = true ]; then
    echo ""
    echo -e "${YELLOW}Please update your .env file to include image tags.${NC}"
    echo "Example format:"
    echo "  JAVA_BE_IMAGE=\"plants_backend:latest\""
    echo "  CLIENT_FE_IMAGE=\"plants_frontend:latest\""
    echo "  ADMIN_FE_IMAGE=\"plants_admin:latest\""
    exit 1
fi

echo -e "${GREEN}✓ Image format validated${NC}"
echo ""

# ============================================
# Image Verification and Type Detection
# ============================================

# Check Docker daemon
if ! docker info &>/dev/null; then
    echo -e "${RED}ERROR: Docker daemon is not running${NC}"
    exit 1
fi

echo "Verifying Docker images..."
echo ""

# Helper function to verify image exists locally
verify_image() {
    local image="$1"
    local name="$2"

    # Check if image exists in docker image ls (more reliable than inspect due to Docker bug)
    local image_id
    image_id=$(docker image ls --format '{{.Repository}}:{{.Tag}} {{.ID}}' | grep "^${image} " | awk '{print $2}')

    if [ -z "$image_id" ]; then
        echo -e "${RED}ERROR: Docker image not found: $image${NC}"
        echo "Please verify the image exists locally by running: docker image ls"
        exit 1
    fi

    echo "  $name: $image (ID: $image_id) ✓"
}

# Verify each image exists locally
verify_image "$JAVA_BE_IMAGE" "Java Backend"
verify_image "$CLIENT_FE_IMAGE" "Client Frontend"
verify_image "$ADMIN_FE_IMAGE" "Admin Frontend"

echo -e "${GREEN}✓ All images verified${NC}"
echo ""

# ============================================
# Phase 0: Check/Create GCS State Bucket
# ============================================

echo "==========================================="
echo "Phase 0: Checking Terraform state bucket..."
echo "==========================================="

if gsutil ls -b gs://$TF_VAR_state_bucket_name &>/dev/null; then
    echo -e "${GREEN}✓ State bucket already exists: gs://$TF_VAR_state_bucket_name${NC}"
else
    echo "Creating state bucket: gs://$TF_VAR_state_bucket_name"
    gcloud storage buckets create gs://$TF_VAR_state_bucket_name/ --location=$TF_VAR_region
    gcloud storage buckets update gs://$TF_VAR_state_bucket_name/ --versioning
    echo -e "${GREEN}✓ State bucket created with versioning enabled${NC}"
fi
echo ""

# ============================================
# Phase 1: Deploy Prerequisites
# ============================================

echo "==========================================="
echo "Phase 1: Deploying prerequisites..."
echo "==========================================="
echo "  (Artifact Registry, Static IP, Firewall)"
echo ""

terraform -chdir=00-prerequisites init \
    -backend-config="bucket=$TF_VAR_state_bucket_name"

terraform -chdir=00-prerequisites apply -auto-approve

echo -e "${GREEN}✓ Prerequisites deployed${NC}"
echo ""

# ============================================
# Phase 2: Tag and Push Docker Images
# ============================================

echo "==========================================="
echo "Phase 2: Tagging and pushing Docker images..."
echo "==========================================="

# Get registry URL from remote state
REGISTRY_URL=$(terraform -chdir=00-prerequisites output -raw artifact_registry_url)
echo "Registry: $REGISTRY_URL"
echo ""

# Helper function to tag and push image to registry
tag_and_push_image() {
    local local_image="$1"
    local display_name="$2"

    echo "Processing $display_name..." >&2

    # Get image ID from docker image ls (more reliable than inspect due to Docker bug)
    local image_id
    image_id=$(docker image ls --format '{{.Repository}}:{{.Tag}} {{.ID}}' | grep "^${local_image} " | awk '{print $2}')

    if [ -z "$image_id" ]; then
        echo -e "${RED}ERROR: Could not find image ID for $local_image${NC}" >&2
        echo "Please verify the image exists: docker image ls | grep ${local_image}" >&2
        exit 1
    fi

    echo "  Local image: $local_image" >&2
    echo "  Image ID: $image_id" >&2

    # Construct remote tag using the local image name
    local remote_tag="${REGISTRY_URL}/${local_image}"
    echo "  Remote tag: $remote_tag" >&2

    # Tag the image using image ID (more reliable than tag name)
    if ! tag_output=$(docker tag "$image_id" "$remote_tag" 2>&1); then
        echo -e "${RED}ERROR: Failed to tag image $image_id${NC}" >&2
        echo "Docker output:" >&2
        echo "$tag_output" >&2
        exit 1
    fi

    # Push the image
    if ! push_output=$(docker push "$remote_tag" 2>&1); then
        echo -e "${RED}ERROR: Failed to push image $remote_tag${NC}" >&2
        echo "Docker output:" >&2
        echo "$push_output" >&2
        exit 1
    fi

    # Remove registry tag from local Docker to avoid name resolution issues
    # (keeps only local tag, clears RepoDigests that interfere with inspect)
    docker rmi "$remote_tag" &>/dev/null || true

    # Re-tag using image ID to restore local tag (workaround for Docker name resolution bug)
    docker tag "$image_id" "$local_image" &>/dev/null || true

    echo -e "${GREEN}  ✓ Pushed successfully${NC}" >&2
    echo "" >&2

    # Return the full remote tag for Terraform
    echo "$remote_tag"
}

# Tag and push each image
JAVA_BE_REMOTE_TAG=$(tag_and_push_image "$JAVA_BE_IMAGE" "Java Backend")
CLIENT_FE_REMOTE_TAG=$(tag_and_push_image "$CLIENT_FE_IMAGE" "Client Frontend")
ADMIN_FE_REMOTE_TAG=$(tag_and_push_image "$ADMIN_FE_IMAGE" "Admin Frontend")

echo -e "${GREEN}✓ All images tagged and pushed${NC}"
echo ""

# Export full image paths for Terraform
export TF_VAR_java_be_full_image_path="$JAVA_BE_REMOTE_TAG"
export TF_VAR_client_fe_full_image_path="$CLIENT_FE_REMOTE_TAG"
export TF_VAR_admin_fe_full_image_path="$ADMIN_FE_REMOTE_TAG"

echo "Terraform full image paths:"
echo "  java-be: $TF_VAR_java_be_full_image_path"
echo "  client-fe: $TF_VAR_client_fe_full_image_path"
echo "  admin-fe: $TF_VAR_admin_fe_full_image_path"
echo ""

# ============================================
# Phase 3: Deploy GKE Cluster
# ============================================

echo "==========================================="
echo "Phase 3: Deploying GKE cluster..."
echo "==========================================="
echo "  (This may take 10-15 minutes)"
echo ""

terraform -chdir=01-cluster init \
    -backend-config="bucket=$TF_VAR_state_bucket_name"

terraform -chdir=01-cluster apply -auto-approve

echo -e "${GREEN}✓ Cluster deployed${NC}"
echo ""

# ============================================
# Phase 4: Deploy Services
# ============================================

echo "==========================================="
echo "Phase 4: Deploying services..."
echo "==========================================="
echo "  (K8s resources, NEGs, Load Balancer, DNS)"
echo ""

terraform -chdir=02-services init \
    -backend-config="bucket=$TF_VAR_state_bucket_name"

# Note: postgres_password and other shared config now come from remote state
# Image tags are passed via environment variables (set above from Docker images)
terraform -chdir=02-services apply -auto-approve

echo -e "${GREEN}✓ Services deployed${NC}"
echo ""

# ============================================
# Deployment Complete
# ============================================

echo "==========================================="
echo "Deployment Complete!"
echo "==========================================="
echo ""
terraform -chdir=02-services output next_steps
