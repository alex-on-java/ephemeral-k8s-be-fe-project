# Infrastructure

Ephemeral GCP infrastructure for the Plants Project demo. Designed for easy deploy/destroy cycles.

**Cost after teardown**: ~$0.21/month (DNS zone + state bucket only)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         GCP PROJECT                             │
├─────────────────────────────────────────────────────────────────┤
│  00-prerequisites     01-cluster          02-services           │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────────┐   │
│  │ Artifact    │     │ GKE         │     │ K8s Deployments │   │
│  │ Registry    │────▶│ Autopilot   │────▶│ - java-be       │   │
│  │ Static IP   │     │ Cluster     │     │ - client-fe     │   │
│  │ Firewall    │     │             │     │ - admin-fe      │   │
│  └─────────────┘     └─────────────┘     │ - postgres      │   │
│                                          ├─────────────────┤   │
│                                          │ Regional LB     │   │
│                                          │ Cloud DNS       │   │
│                                          └─────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Traffic Flow

```
HTTPS → Static IP → URL Map → Backend Services → GKE Pods
         │
         ├─ base_domain/api/*  → java-be
         ├─ base_domain/*      → client-fe
         └─ admin_domain/*     → admin-fe
```

## One-Time Setup (manual prerequisites)

```bash
cp .env.example .env  # fill in values
./setup-prerequisites.sh
```

Creates resources that persist across deploy/destroy cycles:
- GCS state bucket, Cloud DNS zone, proxy subnet, SSL certificate

## Deploy

```bash
./deploy.sh  # ~30-45 min
```

Deploys all 3 Terraform modules (00 → 01 → 02)

## Destroy

```bash
./destroy.sh
```

Removes all Terraform-managed resources. Manual prerequisites remain.

## Environment Variables

Required in `.env`:
- `TF_VAR_project_id` - GCP project
- `TF_VAR_region` - Region (default: europe-west3)
- `TF_VAR_base_domain` - Main domain
- `TF_VAR_admin_domain` - Admin subdomain
- `TF_VAR_state_bucket_name` - Terraform state bucket
- `TF_VAR_dns_zone_name` - Cloud DNS zone name
- `TF_VAR_ssl_cert_name` - SSL certificate name
- `TF_VAR_proxy_subnet_name` - LB proxy subnet name
