#!/usr/bin/env bash
set -Eeuo pipefail

# Trap to handle errors properly
trap 'rc=$?; cmd=$BASH_COMMAND; pcs=("${PIPESTATUS[@]}"); file="${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}"; line="${BASH_LINENO[0]}"; [[ $line -eq 0 ]] && line="$LINENO"; echo "ERROR $rc at $file:$line: $cmd  PIPESTATUS=${pcs[*]}" >&2' ERR

###########################################
# Plants Project - One-Time Prerequisites Setup
###########################################
# This script sets up all manual prerequisites needed
# BEFORE running Terraform for the first time.
#
# Prerequisites created:
# 1. GCS state bucket (for Terraform state)
# 2. Cloud DNS managed zone (for domain management)
# 3. Proxy-only subnet (for load balancer)
# 4. SSL certificates (optional, saves 20-60 min per deployment)
# 5. Required GCP APIs enabled
#
# Cost: ~$0.21/month (persists when all Terraform resources destroyed)
###########################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD_BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo ""
    echo "=========================================="
    echo -e "${BLUE}$1${NC}"
    echo "=========================================="
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_section() {
    echo ""
    echo -e "${BLUE}━━━ $1 ━━━${NC}"
    echo ""
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if a resource exists (returns 0 if exists, 1 if not)
resource_exists() {
    "$@" &>/dev/null
    return $?
}

# Check DNS delegation status
# Validates by checking both dig exit code and non-empty SOA output
# Returns 0 if delegation is active, 1 if not
# Sets VERIFIED_NS global variable with responding nameserver
check_dns_delegation() {
    local domain="$1"
    local nameservers="$2"

    # Check if dig is available
    if ! command_exists dig; then
        return 1
    fi

    # Try querying each nameserver directly
    VERIFIED_NS=""

    while IFS= read -r ns; do
        # Skip empty lines
        [ -z "$ns" ] && continue

        # Remove trailing dot if present for display
        local ns_clean=$(echo "$ns" | sed 's/\.$//')

        # Query the nameserver directly to check if it's authoritative
        # Check both exit code and non-empty output for robust validation
        if output=$(dig @"$ns" SOA "$domain" +short +time=2 +tries=1 2>/dev/null) && [[ -n "$output" ]]; then
            VERIFIED_NS="$ns_clean"
            return 0
        fi
    done <<< "$nameservers"

    return 1
}

# Check public DNS delegation status
# Validates by querying public DNS (no direct nameserver query)
# Returns 0 if NS records exist in public DNS and match expected nameservers, 1 if not
# Sets PUBLIC_NS_COUNT global variable with count of matching Google nameservers
check_public_dns_delegation() {
    local domain="$1"
    local expected_nameservers="$2"

    # Check if dig is available
    if ! command_exists dig; then
        return 1
    fi

    # Query public DNS for NS records (no @nameserver = follows DNS hierarchy)
    PUBLIC_NS_COUNT=0

    # Get NS records from public DNS
    if ! public_ns=$(dig NS "$domain" +short 2>/dev/null); then
        return 1
    fi

    # Check if we got any results
    if [ -z "$public_ns" ]; then
        return 1
    fi

    # Count how many of the returned nameservers match our expected Google nameservers
    while IFS= read -r returned_ns; do
        # Skip empty lines
        [ -z "$returned_ns" ] && continue

        # Normalize: remove trailing dot for comparison
        returned_ns_clean=$(echo "$returned_ns" | sed 's/\.$//')

        # Check if this nameserver is in our expected list
        while IFS= read -r expected_ns; do
            [ -z "$expected_ns" ] && continue
            expected_ns_clean=$(echo "$expected_ns" | sed 's/\.$//')

            if [ "$returned_ns_clean" = "$expected_ns_clean" ]; then
                ((++PUBLIC_NS_COUNT))
                break
            fi
        done <<< "$expected_nameservers"
    done <<< "$public_ns"

    # Success if we found at least one matching nameserver
    [ "$PUBLIC_NS_COUNT" -gt 0 ]
}

# Poll certificate status until ACTIVE, FAILED, or timeout
# Parameters: cert_name, region
poll_certificate_status() {
    local cert_name="$1"
    local region="$2"

    TIMEOUT_MINUTES=60
    POLL_INTERVAL_SECONDS=180  # 3 minutes

    print_info "Polling certificate status (timeout: $TIMEOUT_MINUTES minutes)..."
    print_info "Checking every $((POLL_INTERVAL_SECONDS / 60)) minutes..."
    echo ""

    START_TIME=$(date +%s)
    TIMEOUT_SECONDS=$((TIMEOUT_MINUTES * 60))

    while true; do
        CURRENT_TIME=$(date +%s)
        ELAPSED=$((CURRENT_TIME - START_TIME))

        if [ $ELAPSED -ge $TIMEOUT_SECONDS ]; then
            print_warning "Timeout reached after $TIMEOUT_MINUTES minutes"
            echo ""
            echo "Certificate may still be provisioning. Check status with:"
            echo "  gcloud certificate-manager certificates describe $cert_name --location=$region"
            break
        fi

        STATUS=$(gcloud certificate-manager certificates describe "$cert_name" \
            --location="$region" \
            --format="value(managed.state)" 2>/dev/null || echo "UNKNOWN")

        MINUTES_ELAPSED=$((ELAPSED / 60))
        echo "[${MINUTES_ELAPSED}m] Certificate status: $STATUS"

        if [ "$STATUS" = "ACTIVE" ]; then
            echo ""
            print_success "Certificate is ACTIVE and ready to use!"
            break
        elif [ "$STATUS" = "FAILED" ]; then
            echo ""
            print_error "Certificate provisioning failed"
            echo ""
            echo "Check details:"
            echo "  gcloud certificate-manager certificates describe $cert_name --location=$region"
            break
        fi

        sleep "$POLL_INTERVAL_SECONDS"
    done
}

# Prompt user and optionally poll certificate status
# Parameters: cert_name, region
prompt_and_poll_certificate() {
    local cert_name="$1"
    local region="$2"

    read -p "Would you like to wait for the certificate to become ACTIVE? [y/N] " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        poll_certificate_status "$cert_name" "$region"
    else
        print_info "Skipping certificate polling"
        echo ""
        echo "Check certificate status later with:"
        echo "  gcloud certificate-manager certificates describe $cert_name --location=$region"
    fi
}

###########################################
# Load Environment Variables
###########################################

print_header "Plants Project - Prerequisites Setup"

# Source .env file if it exists
ENV_FILE="$(dirname "$0")/.env"
if [ -f "$ENV_FILE" ]; then
    print_info "Loading environment variables from .env file..."
    set -a
    source "$ENV_FILE"
    set +a
    print_success "Environment variables loaded"
else
    print_error ".env file not found at: $ENV_FILE"
    echo ""
    echo "Please copy .env.example to .env and fill in your values:"
    echo "  cp infra/.env.example infra/.env"
    echo "  # Edit infra/.env with your configuration"
    echo ""
    exit 1
fi

###########################################
# Validate Required Variables
###########################################

print_section "Validating Configuration"

REQUIRED_VARS=(
    "TF_VAR_project_id"
    "TF_VAR_region"
    "TF_VAR_base_domain"
    "TF_VAR_admin_domain"
    "TF_VAR_state_bucket_name"
    "TF_VAR_dns_zone_name"
    "TF_VAR_proxy_subnet_name"
    "TF_VAR_ssl_cert_name"
)

MISSING_VARS=()
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    print_error "Missing required environment variables:"
    for var in "${MISSING_VARS[@]}"; do
        echo "  - $var"
    done
    echo ""
    echo "Please update your .env file with all required variables."
    exit 1
fi

print_success "All required variables are set"

# Set convenience variables
PROJECT_ID="${TF_VAR_project_id}"
REGION="${TF_VAR_region}"
BASE_DOMAIN="${TF_VAR_base_domain}"
ADMIN_DOMAIN="${TF_VAR_admin_domain}"
STATE_BUCKET="${TF_VAR_state_bucket_name}"
DNS_ZONE="${TF_VAR_dns_zone_name}"
PROXY_SUBNET="${TF_VAR_proxy_subnet_name}"
SSL_CERT_NAME="${TF_VAR_ssl_cert_name}"

echo ""
echo "Configuration:"
echo "  Project ID:     $PROJECT_ID"
echo "  Region:         $REGION"
echo "  Base Domain:    $BASE_DOMAIN"
echo "  Admin Domain:   $ADMIN_DOMAIN"
echo "  State Bucket:   $STATE_BUCKET"
echo "  DNS Zone:       $DNS_ZONE"
echo "  Proxy Subnet:   $PROXY_SUBNET"
echo "  SSL Cert Name:  $SSL_CERT_NAME"

###########################################
# Pre-flight Checks
###########################################

print_section "Pre-flight Checks"

# Check if gcloud is installed
if ! command_exists gcloud; then
    print_error "gcloud CLI is not installed"
    echo "Please install gcloud: https://cloud.google.com/sdk/docs/install"
    exit 1
fi
print_success "gcloud CLI is installed"

# Check authentication
CURRENT_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null || echo "")
if [ -z "$CURRENT_ACCOUNT" ]; then
    print_error "Not authenticated with gcloud"
    echo ""
    echo "Please authenticate:"
    echo "  gcloud auth login"
    echo "  gcloud auth application-default login"
    exit 1
fi
print_success "Authenticated as: $CURRENT_ACCOUNT"

# Verify project exists FIRST
if ! gcloud projects describe "$PROJECT_ID" &>/dev/null; then
    print_warning "Project $PROJECT_ID does not exist or you don't have access"
    echo ""
    read -p "Would you like to create this project? [Y/n] " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        print_info "Creating project: $PROJECT_ID"
        if ! project_output=$(gcloud projects create "$PROJECT_ID" 2>&1); then
            print_error "Failed to create project"
            echo "$project_output"
            exit 1
        fi
        print_success "Project created: $PROJECT_ID"
    else
        print_error "Project $PROJECT_ID is required to proceed"
        exit 1
    fi
fi
print_success "Project $PROJECT_ID is accessible"

# NOW set it as active if needed
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
    print_info "Setting active project to: $PROJECT_ID"

    # Capture output to detect quota project warnings
    SET_PROJECT_OUTPUT=$(gcloud config set project "$PROJECT_ID" 2>&1)
    echo "$SET_PROJECT_OUTPUT"

    print_success "Active project updated"

    # Check if ADC quota project warning appeared
    if echo "$SET_PROJECT_OUTPUT" | grep -q "does not match the quota project"; then
        echo ""
        print_warning "ADC quota project mismatch detected"
        read -p "Would you like to update ADC quota project to $PROJECT_ID? [Y/n] " -n 1 -r
        echo ""

        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            gcloud auth application-default set-quota-project "$PROJECT_ID"
            print_success "ADC quota project updated"
        else
            print_info "ADC quota project not updated"
        fi
    fi
fi

###########################################
# Check and Enable Billing
###########################################

print_section "Checking Billing Configuration"

# Check if billing is enabled for the project
BILLING_ACCOUNT=$(gcloud billing projects describe "$PROJECT_ID" --format="value(billingAccountName)" 2>/dev/null || echo "")

if [ -z "$BILLING_ACCOUNT" ]; then
    print_warning "Billing is not enabled for project: $PROJECT_ID"
    echo ""
    echo "GCP requires billing to be enabled for most services (Compute, GKE, etc.)"
    echo ""

    # List available billing accounts
    print_info "Checking for available billing accounts..."
    BILLING_ACCOUNTS=$(gcloud billing accounts list --filter="open=true" --format="value(name)" 2>/dev/null)

    if [ -z "$BILLING_ACCOUNTS" ]; then
        print_error "No active billing accounts found"
        echo ""
        echo "You need to create a billing account first:"
        echo "  1. Go to: https://console.cloud.google.com/billing"
        echo "  2. Create a new billing account"
        echo "  3. Re-run this script"
        echo ""
        exit 1
    fi

    # Show available billing accounts
    echo "Available billing accounts:"
    echo ""
    gcloud billing accounts list --filter="open=true" --format="table(name,displayName,open)"
    echo ""

    # Ask user if they want to link billing
    read -p "Would you like to link a billing account to this project? [Y/n] " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        # Count billing accounts
        ACCOUNT_COUNT=$(echo "$BILLING_ACCOUNTS" | wc -l | tr -d ' ')

        if [ "$ACCOUNT_COUNT" -eq 1 ]; then
            # Only one account, use it automatically
            SELECTED_ACCOUNT="$BILLING_ACCOUNTS"
            print_info "Using billing account: $SELECTED_ACCOUNT"
        else
            # Multiple accounts, ask user to choose
            echo "Enter the billing account ID from the list above:"
            read -r SELECTED_ACCOUNT

            # Validate the account exists
            if ! echo "$BILLING_ACCOUNTS" | grep -q "^$SELECTED_ACCOUNT$"; then
                print_error "Invalid billing account ID: $SELECTED_ACCOUNT"
                exit 1
            fi
        fi

        # Link the billing account
        print_info "Linking billing account to project..."
        if ! billing_output=$(gcloud billing projects link "$PROJECT_ID" \
            --billing-account="$SELECTED_ACCOUNT" 2>&1); then
            print_error "Failed to link billing account"
            echo "$billing_output"
            exit 1
        fi

        print_success "Billing account linked successfully"
        echo ""
    else
        print_error "Billing is required to proceed with deployment"
        echo ""
        echo "To manually enable billing:"
        echo "  gcloud billing projects link $PROJECT_ID --billing-account=BILLING_ACCOUNT_ID"
        echo ""
        exit 1
    fi
else
    print_success "Billing is enabled: $BILLING_ACCOUNT"
fi

echo ""

###########################################
# Enable Required GCP APIs
###########################################

print_section "Enabling Required GCP APIs"

REQUIRED_APIS=(
    "compute.googleapis.com"
    "container.googleapis.com"
    "dns.googleapis.com"
    "artifactregistry.googleapis.com"
    "certificatemanager.googleapis.com"
    "storage.googleapis.com"
    "iam.googleapis.com"
)

print_info "Enabling APIs (this may take a few minutes)..."
echo ""

for api in "${REQUIRED_APIS[@]}"; do
    if gcloud services list --enabled --filter="name:$api" --format="value(name)" 2>/dev/null | grep -q "$api"; then
        print_success "$api (already enabled)"
    else
        echo -n "  Enabling $api... "
        if ! enable_output=$(gcloud services enable "$api" --project="$PROJECT_ID" 2>&1); then
            echo ""  # New line before error
            print_error "Failed to enable $api"
            echo "gcloud output:"
            echo "$enable_output"
            exit 1
        fi
        echo -ne "\r"  # Return to start of line
        print_success "$api (enabled)"
    fi
done

print_success "All required APIs are enabled"

# Configure Docker to authenticate with Artifact Registry
print_info "Configuring Docker authentication for Artifact Registry..."
if gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet 2>/dev/null; then
    print_success "Docker authentication configured for ${REGION}-docker.pkg.dev"
else
    print_error "Failed to configure Docker authentication"
    echo "Please run manually: gcloud auth configure-docker ${REGION}-docker.pkg.dev"
    exit 1
fi
echo ""

# Check if region is valid
if ! gcloud compute regions describe "$REGION" &>/dev/null; then
    print_error "Region $REGION is not valid"
    echo "List valid regions: gcloud compute regions list"
    exit 1
fi
print_success "Region $REGION is valid"

###########################################
# Create GCS State Bucket
###########################################

print_section "Creating GCS State Bucket"

echo "Bucket: gs://$STATE_BUCKET/"
echo "Purpose: Store Terraform state for all infrastructure phases"
echo "Cost: ~\$0.01/month"
echo ""

if gsutil ls -b "gs://$STATE_BUCKET/" &>/dev/null; then
    print_warning "Bucket already exists: gs://$STATE_BUCKET/"

    # Check if versioning is enabled
    VERSIONING=$(gsutil versioning get "gs://$STATE_BUCKET/" | grep -i "enabled" || echo "")
    if [ -z "$VERSIONING" ]; then
        print_info "Enabling versioning on existing bucket..."
        if ! versioning_output=$(gsutil versioning set on "gs://$STATE_BUCKET/" 2>&1); then
            print_error "Failed to enable versioning"
            echo "$versioning_output"
            exit 1
        fi
        print_success "Versioning enabled"
    else
        print_success "Versioning already enabled"
    fi
else
    print_info "Creating bucket..."
    if ! bucket_output=$(gcloud storage buckets create "gs://$STATE_BUCKET/" \
        --location="$REGION" \
        --project="$PROJECT_ID" 2>&1); then
        print_error "Failed to create bucket"
        echo "$bucket_output"
        exit 1
    fi

    print_info "Enabling versioning..."
    if ! versioning_output=$(gsutil versioning set on "gs://$STATE_BUCKET/" 2>&1); then
        print_error "Failed to enable versioning"
        echo "$versioning_output"
        exit 1
    fi

    print_success "Bucket created: gs://$STATE_BUCKET/"
fi

# Verify
BUCKET_LOCATION=$(gcloud storage buckets describe "gs://$STATE_BUCKET/" --format="value(location)" 2>/dev/null)
echo ""
echo "Bucket details:"
echo "  Location: $BUCKET_LOCATION"
echo "  Versioning: Enabled"

###########################################
# Create Cloud DNS Managed Zone
###########################################

print_section "Creating Cloud DNS Managed Zone"

echo "Zone Name: $DNS_ZONE"
echo "Domain: $BASE_DOMAIN"
echo "Purpose: DNS management for your domains"
echo "Cost: \$0.20/month"
echo ""

if gcloud dns managed-zones describe "$DNS_ZONE" &>/dev/null; then
    print_warning "DNS zone already exists: $DNS_ZONE"
else
    print_info "Creating DNS managed zone..."
    if ! dns_output=$(gcloud dns managed-zones create "$DNS_ZONE" \
        --dns-name="${BASE_DOMAIN}." \
        --description="Persistent DNS zone for plants project" \
        --visibility=public \
        --project="$PROJECT_ID" 2>&1); then
        print_error "Failed to create DNS zone"
        echo "$dns_output"
        exit 1
    fi

    print_success "DNS zone created: $DNS_ZONE"
fi

# Get nameservers
print_info "Retrieving nameservers..."
NAMESERVERS=$(gcloud dns managed-zones describe "$DNS_ZONE" --format="value(nameServers)" | tr ';' '\n')

# Check DNS configuration status (two-tier check)
echo ""
print_info "Checking DNS configuration..."
echo ""

# Step 1: Check if Google Cloud DNS is ready (query Google nameservers directly)
GOOGLE_DNS_READY=false
if check_dns_delegation "$BASE_DOMAIN" "$NAMESERVERS"; then
    GOOGLE_DNS_READY=true
    print_success "Cloud DNS zone is authoritative (verified via $VERIFIED_NS)"
else
    print_error "Cloud DNS zone is not responding correctly"
    echo ""
    echo "This indicates a configuration problem with the Cloud DNS zone."
    echo "Please check the zone configuration:"
    echo "  gcloud dns managed-zones describe $DNS_ZONE"
    exit 1
fi

# Step 2: Check if public DNS delegation is configured (query public DNS hierarchy)
PUBLIC_DNS_DELEGATED=false
if check_public_dns_delegation "$BASE_DOMAIN" "$NAMESERVERS"; then
    PUBLIC_DNS_DELEGATED=true
    print_success "Public DNS delegation is active ($PUBLIC_NS_COUNT nameserver(s) found)"
else
    print_warning "Public DNS delegation not configured yet"
fi

# Show DNS status summary
echo ""
echo "DNS Configuration Status:"
echo "  Cloud DNS Zone:       ✓ Ready"
if [ "$PUBLIC_DNS_DELEGATED" = true ]; then
    echo "  Public Delegation:    ✓ Active"
else
    echo "  Public Delegation:    ✗ Not configured"
fi
echo ""

# If public DNS delegation is missing, show instructions
if [ "$PUBLIC_DNS_DELEGATED" = false ]; then
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  IMPORTANT: DNS Delegation Required${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Your DNS zone has been created with these nameservers:"
    echo ""
    echo "$NAMESERVERS" | while IFS= read -r ns; do
        echo "  $ns"
    done
    echo ""
    echo "You MUST delegate your domain to these nameservers at your domain registrar."
    echo ""
    echo "Instructions:"
    echo "  1. Log in to your domain registrar (e.g., Digital Ocean, GoDaddy, etc.)"
    echo -e "  2. Find DNS/${BOLD_BLUE}Nameserver${NC} settings for your domain"
    echo ""

    # Determine if it's a subdomain or root domain
    if [[ "$BASE_DOMAIN" == *.*.* ]] || [[ "$BASE_DOMAIN" == *.*-*.* ]]; then
        # Likely a subdomain (e.g., plants.example.com)
        PARENT_DOMAIN=$(echo "$BASE_DOMAIN" | cut -d'.' -f2-)
        SUBDOMAIN=$(echo "$BASE_DOMAIN" | cut -d'.' -f1)

        echo "  3. For subdomain delegation ($BASE_DOMAIN):"
        echo -e "     Add ${BOLD_BLUE}NS${NC} records for subdomain '$SUBDOMAIN' pointing to:"
        echo "$NAMESERVERS" | while IFS= read -r ns; do
            echo "       - $ns"
        done
        echo ""
        echo -e "     Example ${BOLD_BLUE}NS${NC} records in $PARENT_DOMAIN zone:"
        echo "$NAMESERVERS" | while IFS= read -r ns; do
            echo -e "       $SUBDOMAIN  IN  ${BOLD_BLUE}NS${NC}  $ns"
        done
    else
        # Root domain
        echo -e "  3. Replace your domain's ${BOLD_BLUE}nameservers${NC} with these 4 Google nameservers"
    fi

    echo ""
    echo "  4. Wait 5-30 minutes for DNS propagation"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    read -p "Press ENTER after you have completed DNS delegation at your registrar..."
fi

# Optional: Verify public DNS delegation (only if not already verified)
if [ "$PUBLIC_DNS_DELEGATED" = false ]; then
    echo ""
    read -p "Would you like to verify public DNS delegation now? [y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Checking public DNS delegation..."

        if ! command_exists dig; then
            print_warning "dig command not found, skipping verification"
            echo "Install dig: brew install bind"
            echo ""
            read -p "Press ENTER to continue..."
        else
            echo ""

            # Check Google Cloud DNS (should still be OK)
            if check_dns_delegation "$BASE_DOMAIN" "$NAMESERVERS"; then
                print_success "Cloud DNS zone is still authoritative (verified via $VERIFIED_NS)"
            else
                print_warning "Cloud DNS zone check failed"
            fi

            # Check public DNS delegation
            if check_public_dns_delegation "$BASE_DOMAIN" "$NAMESERVERS"; then
                print_success "Public DNS delegation verified! ($PUBLIC_NS_COUNT nameserver(s) found)"
                echo ""
                echo "Your domain is now properly delegated to Google Cloud DNS."
                echo ""
            else
                print_warning "Public DNS delegation not yet active"
                echo ""
                echo "Expected nameservers:"
                echo "$NAMESERVERS" | while IFS= read -r ns; do
                    [ -n "$ns" ] && echo "  $ns"
                done
                echo ""
                echo "DNS delegation hasn't propagated yet. This can take 5-60 minutes."
                echo ""
                echo "You can verify manually with:"
                echo "  dig NS $BASE_DOMAIN +short"
                echo ""
                echo "You can continue anyway and verify later, or wait and retry."
                echo ""
                read -p "Press ENTER to continue..."
            fi
        fi
    fi
fi

print_success "DNS zone setup complete"

###########################################
# Create Proxy-Only Subnet
###########################################

print_section "Creating Proxy-Only Subnet"

echo "Subnet Name: $PROXY_SUBNET"
echo "Region: $REGION"
echo "Purpose: Required for Regional External Application Load Balancer"
echo "Cost: \$0.00 (subnets are free)"
echo ""

if gcloud compute networks subnets describe "$PROXY_SUBNET" --region="$REGION" &>/dev/null; then
    print_warning "Proxy-only subnet already exists: $PROXY_SUBNET"

    # Verify it's actually a proxy-only subnet
    PURPOSE=$(gcloud compute networks subnets describe "$PROXY_SUBNET" --region="$REGION" --format="value(purpose)" 2>/dev/null)
    if [ "$PURPOSE" != "REGIONAL_MANAGED_PROXY" ]; then
        print_error "Subnet exists but is not a proxy-only subnet (purpose: $PURPOSE)"
        echo "Please use a different subnet name or delete the existing subnet."
        exit 1
    fi
    print_success "Verified as proxy-only subnet"
else
    print_info "Creating proxy-only subnet..."
    echo ""

    # Detect VPC mode to choose appropriate IP ranges
    print_info "Detecting VPC configuration..."
    VPC_AUTO_MODE=$(gcloud compute networks describe default --format="value(autoCreateSubnetworks)" --project="$PROJECT_ID" 2>/dev/null)

    if [ "$VPC_AUTO_MODE" = "True" ]; then
        print_info "VPC is in AUTO mode (GCP reserves 10.128.0.0/9)"
        # Auto mode: Avoid 10.128.0.0/9 reserved range
        CANDIDATE_RANGES=(
            "10.0.0.0/23" "10.2.0.0/23" "10.4.0.0/23" "10.6.0.0/23" "10.8.0.0/23"
            "10.10.0.0/23" "10.12.0.0/23" "10.14.0.0/23" "10.16.0.0/23" "10.18.0.0/23"
            "192.168.0.0/23" "192.168.2.0/23" "172.16.0.0/23"
        )
    else
        print_info "VPC is in CUSTOM mode"
        # Custom mode: Can use any private ranges
        CANDIDATE_RANGES=(
            "10.129.0.0/23" "10.130.0.0/23" "10.131.0.0/23" "10.200.0.0/23" "10.201.0.0/23"
            "192.168.0.0/23" "192.168.2.0/23" "172.16.0.0/23"
        )
    fi

    echo ""
    print_info "Trying ${#CANDIDATE_RANGES[@]} candidate IP ranges..."

    # Try each candidate range
    MAX_ATTEMPTS=${#CANDIDATE_RANGES[@]}
    ATTEMPT=1
    CREATED=false

    for IP_RANGE in "${CANDIDATE_RANGES[@]}"; do
        echo -n "  Attempt $ATTEMPT/$MAX_ATTEMPTS: $IP_RANGE... "

        if subnet_output=$(gcloud compute networks subnets create "$PROXY_SUBNET" \
            --purpose=REGIONAL_MANAGED_PROXY \
            --role=ACTIVE \
            --region="$REGION" \
            --network=default \
            --range="$IP_RANGE" \
            --project="$PROJECT_ID" 2>&1); then
            echo -e "${GREEN}✓${NC}"
            print_success "Proxy-only subnet created: $PROXY_SUBNET"
            CREATED=true
            break
        else
            echo -e "${RED}✗${NC}"
        fi

        ((++ATTEMPT))
    done

    if [ "$CREATED" = false ]; then
        print_error "Failed to create proxy-only subnet after $MAX_ATTEMPTS attempts"
        echo ""
        echo "Last error from gcloud:"
        echo "$subnet_output"
        echo ""
        echo "VPC mode: $VPC_AUTO_MODE"
        if [ "$VPC_AUTO_MODE" = "True" ]; then
            echo "Note: Auto mode VPCs reserve 10.128.0.0/9 for regional subnets"
        fi
        echo ""
        echo "Please manually create the subnet with a non-conflicting IP range:"
        echo ""
        echo "gcloud compute networks subnets create $PROXY_SUBNET \\"
        echo "  --purpose=REGIONAL_MANAGED_PROXY \\"
        echo "  --role=ACTIVE \\"
        echo "  --region=$REGION \\"
        echo "  --network=default \\"
        echo "  --range=<YOUR_IP_RANGE>"
        echo ""
        echo "List existing subnets to find available ranges:"
        echo "  gcloud compute networks subnets list --network=default --project=$PROJECT_ID"
        exit 1
    fi
fi

# Verify and show details
SUBNET_RANGE=$(gcloud compute networks subnets describe "$PROXY_SUBNET" --region="$REGION" --format="value(ipCidrRange)" 2>/dev/null)
echo ""
echo "Subnet details:"
echo "  Name: $PROXY_SUBNET"
echo "  Region: $REGION"
echo "  IP Range: $SUBNET_RANGE"
echo "  Purpose: REGIONAL_MANAGED_PROXY"

###########################################
# Create SSL Certificates
###########################################

print_section "Creating SSL Certificates"

echo "Certificate Name: $SSL_CERT_NAME"
echo "Domains: $BASE_DOMAIN, $ADMIN_DOMAIN"
echo "Purpose: SSL certificates for HTTPS load balancer"
echo "Cost: \$0.00 (Google-managed certificates are free)"
echo ""

print_info "Creating SSL certificates..."
echo ""

# Create DNS authorizations
AUTH_BASE="${DNS_ZONE%-zone}-auth"
AUTH_ADMIN="admin-${AUTH_BASE}"

echo "Creating DNS authorizations..."

# Base domain authorization
if gcloud certificate-manager dns-authorizations describe "$AUTH_BASE" --location="$REGION" &>/dev/null; then
    print_warning "DNS authorization already exists: $AUTH_BASE"
else
    print_info "Creating authorization for $BASE_DOMAIN..."
    gcloud certificate-manager dns-authorizations create "$AUTH_BASE" \
        --domain="$BASE_DOMAIN" \
        --location="$REGION" \
        --project="$PROJECT_ID"
    print_success "Created: $AUTH_BASE"
fi

# Admin domain authorization
if gcloud certificate-manager dns-authorizations describe "$AUTH_ADMIN" --location="$REGION" &>/dev/null; then
    print_warning "DNS authorization already exists: $AUTH_ADMIN"
else
    print_info "Creating authorization for $ADMIN_DOMAIN..."
    gcloud certificate-manager dns-authorizations create "$AUTH_ADMIN" \
        --domain="$ADMIN_DOMAIN" \
        --location="$REGION" \
        --project="$PROJECT_ID"
    print_success "Created: $AUTH_ADMIN"
fi

echo ""
print_info "Retrieving CNAME validation records..."

# Get CNAME details for base domain
BASE_CNAME_NAME=$(gcloud certificate-manager dns-authorizations describe "$AUTH_BASE" \
    --location="$REGION" \
    --format="value(dnsResourceRecord.name)")
BASE_CNAME_DATA=$(gcloud certificate-manager dns-authorizations describe "$AUTH_BASE" \
    --location="$REGION" \
    --format="value(dnsResourceRecord.data)")

# Get CNAME details for admin domain
ADMIN_CNAME_NAME=$(gcloud certificate-manager dns-authorizations describe "$AUTH_ADMIN" \
    --location="$REGION" \
    --format="value(dnsResourceRecord.name)")
ADMIN_CNAME_DATA=$(gcloud certificate-manager dns-authorizations describe "$AUTH_ADMIN" \
    --location="$REGION" \
    --format="value(dnsResourceRecord.data)")

echo ""
print_info "Creating CNAME records in DNS zone..."

# Create CNAME for base domain
if gcloud dns record-sets list --zone="$DNS_ZONE" --name="$BASE_CNAME_NAME" --type=CNAME 2>/dev/null | grep -q "$BASE_CNAME_NAME"; then
    print_warning "CNAME record already exists: $BASE_CNAME_NAME"
else
    gcloud dns record-sets create "$BASE_CNAME_NAME" \
        --zone="$DNS_ZONE" \
        --type=CNAME \
        --ttl=300 \
        --rrdatas="$BASE_CNAME_DATA" \
        --project="$PROJECT_ID"
    print_success "Created CNAME: $BASE_CNAME_NAME"
fi

# Create CNAME for admin domain
if gcloud dns record-sets list --zone="$DNS_ZONE" --name="$ADMIN_CNAME_NAME" --type=CNAME 2>/dev/null | grep -q "$ADMIN_CNAME_NAME"; then
    print_warning "CNAME record already exists: $ADMIN_CNAME_NAME"
else
    gcloud dns record-sets create "$ADMIN_CNAME_NAME" \
        --zone="$DNS_ZONE" \
        --type=CNAME \
        --ttl=300 \
        --rrdatas="$ADMIN_CNAME_DATA" \
        --project="$PROJECT_ID"
    print_success "Created CNAME: $ADMIN_CNAME_NAME"
fi

echo ""
print_info "Creating Certificate Manager certificate..."

# Create certificate
if gcloud certificate-manager certificates describe "$SSL_CERT_NAME" --location="$REGION" &>/dev/null; then
    print_warning "Certificate already exists: $SSL_CERT_NAME"
    CERT_EXISTS=true
else
    gcloud certificate-manager certificates create "$SSL_CERT_NAME" \
        --domains="$BASE_DOMAIN,$ADMIN_DOMAIN" \
        --dns-authorizations="$AUTH_BASE,$AUTH_ADMIN" \
        --location="$REGION" \
        --project="$PROJECT_ID"
    print_success "Certificate created: $SSL_CERT_NAME"
    CERT_EXISTS=false
fi

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  Certificate Provisioning${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Google needs to validate domain ownership and provision the certificate."
echo "This process takes 20-60 minutes."
echo ""

if [ "$CERT_EXISTS" = false ]; then
    prompt_and_poll_certificate "$SSL_CERT_NAME" "$REGION"
else
    # Certificate already existed, check its status
    STATUS=$(gcloud certificate-manager certificates describe "$SSL_CERT_NAME" \
        --location="$REGION" \
        --format="value(managed.state)" 2>/dev/null || echo "UNKNOWN")
    echo "Current status: $STATUS"

    if [ "$STATUS" != "ACTIVE" ] && [ "$STATUS" != "FAILED" ]; then
        echo ""
        prompt_and_poll_certificate "$SSL_CERT_NAME" "$REGION"
    elif [ "$STATUS" = "FAILED" ]; then
        echo ""
        echo "Check details:"
        echo "  gcloud certificate-manager certificates describe $SSL_CERT_NAME --location=$REGION"
    fi
fi

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

print_success "SSL certificate setup complete"

###########################################
# Summary
###########################################

print_header "Prerequisites Setup Complete!"

echo "The following one-time prerequisites have been configured:"
echo ""
echo "✓ GCS State Bucket:      gs://$STATE_BUCKET/"
echo "✓ Cloud DNS Zone:        $DNS_ZONE"
echo "✓ Proxy-Only Subnet:     $PROXY_SUBNET"
echo "✓ SSL Certificates:      $SSL_CERT_NAME"
echo "✓ Required GCP APIs:     All enabled"
echo ""

echo "Persistent Cost (when all Terraform resources destroyed):"
echo "  GCS Bucket:     ~\$0.01/month"
echo "  DNS Zone:       ~\$0.20/month"
echo "  Proxy Subnet:    \$0.00/month"
echo "  SSL Certs:       \$0.00/month"
echo "  ─────────────────────────────"
echo "  Total:          ~\$0.21/month"
echo ""

echo "Environment variables configured in .env:"
echo "  TF_VAR_project_id=$PROJECT_ID"
echo "  TF_VAR_region=$REGION"
echo "  TF_VAR_state_bucket_name=$STATE_BUCKET"
echo "  TF_VAR_dns_zone_name=$DNS_ZONE"
echo "  TF_VAR_proxy_subnet_name=$PROXY_SUBNET"
echo "  TF_VAR_ssl_cert_name=$SSL_CERT_NAME"
echo ""

print_section "Next Steps"

echo "1. Build Docker images (in project root):"
echo "   cd backend && docker build -t plants-backend ."
echo "   cd frontend && docker build -t plants-frontend ."
echo "   cd admin && docker build -t plants-admin ."
echo ""

echo "2. Run the deployment script:"
echo "   cd infra"
echo "   ./deploy.sh --java-be-image plants-backend --client-fe-image plants-frontend --admin-fe-image plants-admin"
echo ""

echo "3. Deployment will:"
echo "   - Create Artifact Registry and push images (~2-3 min)"
echo "   - Create GKE Autopilot cluster (~10-15 min)"
echo "   - Deploy applications and load balancer (~5-10 min)"
echo "   - Configure DNS records"
echo "   Total: ~30-45 minutes"
echo ""

STATUS=$(gcloud certificate-manager certificates describe "$SSL_CERT_NAME" \
    --location="$REGION" \
    --format="value(managed.state)" 2>/dev/null || echo "UNKNOWN")

if [ "$STATUS" != "ACTIVE" ]; then
    print_warning "IMPORTANT: Wait for SSL certificate to become ACTIVE before deploying!"
    echo ""
    echo "Check status:"
    echo "  gcloud certificate-manager certificates describe $SSL_CERT_NAME --location=$REGION"
    echo ""
    echo "Or list all certificates:"
    echo "  gcloud certificate-manager certificates list --location=$REGION"
    echo ""
fi

print_success "Prerequisites setup completed successfully!"
echo ""
