## What's this
This repository contains infrastructure-as-code and configuration files for hosting a [CTFd](https://ctfd.io/) server on Google Cloud Run, including Terraform modules for all required datastores.

## CTFd server architecture

### CTFd on AWS (v1.0)

#### Single EC2 architecture
<img width=25%><img src="https://github.com/user-attachments/assets/6ef5a435-fac9-43a4-86a3-a060664b1efe" width=50%>

> **Datadog Sandbox (AWS):** AWS Config automatically deletes extensive security group rules. Adjust rules accordingly.

---

### CTFd on Google Cloud (v2.0)

Uses Cloud Run as the CTFd container host, Cloud SQL (MySQL) as the database, Cloud Memorystore (Redis) for session caching, and GCS FUSE for persistent image uploads.

> **Why Redis?** CTFd caches login sessions locally per container. Without Redis, scaling Cloud Run beyond a single instance causes 403 errors. Redis provides a shared session store across all instances.

#### Single container architecture
<img width=10%><img src="https://github.com/user-attachments/assets/f6ec4e1b-d65a-43dc-ab51-6437845d899b" width=80%>

#### Multiple container architecture
<img width=10%><img src="https://github.com/user-attachments/assets/6fafed9e-8aa7-4dcf-bd70-ef4ef77cd9f9" width=80%>

---

## Deploying with Terraform

The `infra/` directory provisions the full CTFd stack in one `terraform apply`.

| Resource | Config |
|---|---|
| **Cloud Run** | v2, gen2, Direct VPC Egress, `ctfd/ctfd:latest` |
| **Cloud SQL** | MySQL 8.0, `db-custom-8-16384` (8 vCPU / 16 GB RAM), single zone, no HA, private IP |
| **Cloud Memorystore** | Redis 7.0, Basic tier, 1 GB, Private Service Access |
| **GCS** | Bucket mounted via GCS FUSE at `/var/uploads` |
| **Service Account** | Cloud SQL client + GCS Object Admin + Secret Manager accessor |

### Prerequisites

- Terraform >= 1.5
- Google provider ~> 5.0
- A GCP project with billing enabled
- An existing VPC and subnet for Cloud Run Direct VPC Egress
- A GCS bucket for Terraform state (`ctf-nuttee-tfstate` — configured in `infra/main.tf` backend block)

### 1. Configure variables

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and fill in all `<placeholder>` values.

| Variable | Description | Default |
|---|---|---|
| `gcp_project_id` | GCP Project ID | — |
| `gcp_region` | GCP Region | — |
| `gcp_zone` | GCP Zone (single-zone resources) | — |
| `gcs_bucket` | GCS bucket name for image uploads | — |
| `gcs_bucket_region` | GCS bucket location | — |
| `cr_vpc` | VPC network name for Direct VPC Egress | — |
| `cr_subnet` | Subnetwork name for Direct VPC Egress | — |
| `cr_sa_name` | Service account `account_id` for Cloud Run | — |
| `cloud_sql_instance_name` | Cloud SQL instance name | `ctfd-mysql` |
| `db_name` | MySQL database name | `ctfd` |
| `db_user` | MySQL user | `ctfd` |
| `db_password` | MySQL password — set via env var, **never in tfvars** | — |
| `redis_instance_name` | Memorystore Redis instance name | `ctfd-redis` |

### 2. Set the database password

`db_password` is sensitive and must **not** be committed. Set it as an environment variable before every `terraform` command:

```bash
export TF_VAR_db_password="your-secure-password"
```

> **Password requirement:** avoid special URL characters (`@`, `/`, `#`, `?`, `&`).
> The password is embedded in the `DATABASE_URL` connection string using `urlencode()`,
> which handles most characters safely — but keeping the password alphanumeric avoids
> any edge-case encoding issues.

### 3. Deploy

```bash
terraform init   # authenticates to the GCS backend and downloads providers
terraform plan
terraform apply
```

### Gotchas

#### Private Service Access (PSA)
Terraform creates a `/20` PSA peering range on the VPC shared by Cloud SQL (private IP) and Memorystore Redis. If your VPC already has PSA configured, import the existing resources instead of creating new ones — see comments at the top of `infra/modules/ctfd/networking.tf`.

#### Datadog Sandbox — domain-restricted sharing
The org policy [Domain restricted sharing](https://cloud.google.com/resource-manager/docs/organization-policy/domain-restricted-sharing) blocks unauthenticated Cloud Run invocations by default. After `terraform apply`, run:

```bash
gcloud run services update ctfd-multi-containers \
  --region=asia-southeast1 \
  --update-labels=external-access:allowed
```

#### VPC name
Double-check that `cr_vpc` in `terraform.tfvars` matches the exact network name shown by:

```bash
gcloud compute networks list --project=<your-project-id>
```

---

## CTFd configuration reference

See the [CTFd configuration docs](https://docs.ctfd.io/docs/deployment/configuration/) for all supported environment variables.
