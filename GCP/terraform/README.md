# Student Registration - GCP Terraform

Flat, one-file-per-concern Terraform (same style as the AWS edition) for:

| File | Provisions | AWS edition equivalent |
|---|---|---|
| `apis.tf` | Required Google APIs, shared locals | - |
| `vpc.tf` | Custom VPC, VM subnet, GKE subnet (+ Pod/Service ranges), static IP for the Ingress | `vpc.tf` |
| `nat.tf` | Cloud Router + Cloud NAT for the private GKE nodes | `nat.tf` |
| `firewall.tf` | Jenkins/SonarQube/SSH (admin IP only), optional IAP SSH, load balancer health checks | security groups |
| `iam.tf` | Service accounts for Jenkins and the GKE nodes (no keys) | IAM roles |
| `artifact-registry.tf` | Docker repository (replaces Docker Hub) + push/pull permissions | - (Docker Hub) |
| `jenkins.tf` | Jenkins + SonarQube VM | manually created EC2 |
| `gke.tf` | Private zonal GKE cluster + autoscaling node pool | `eks.tf` |
| `cloudsql.tf` | Private Service Access + Cloud SQL for MySQL 8.4 + database + user | `rds.tf` |
| `monitoring.tf` | Email channel + alert policies (Jenkins CPU, Cloud SQL CPU/disk) | CloudWatch |
| `outputs.tf` | Everything you need for the next steps | `outputs.tf` |

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars    # edit: project_id, admin_cidr, db_password, alert_email
terraform init
terraform validate
terraform plan
terraform apply
```

Authentication: `gcloud auth application-default login` (no keys in files). A brand-new project first needs
`gcloud services enable serviceusage.googleapis.com cloudresourcemanager.googleapis.com`.

## Notes

- Cloud SQL has no MariaDB, so MySQL 8.4 is used (the backend switched to MySQL Connector/J).
- `sql_tier = "db-g1-small"` is a shared-core tier. If it is rejected in your project or region, use `db-custom-1-3840`.
- The GKE API endpoint is public but restricted to `admin_cidr` and the cluster's own ranges. Update `admin_cidr` if your IP changes.
- Confirm the verification email Google sends to `alert_email`, otherwise the alert channel stays unverified.
- Before `terraform destroy`, delete the Ingress (or the Argo CD application) and wait a few minutes: the load balancer, NEGs and
  firewall rules GKE created for it are not managed by Terraform and will block the VPC deletion.
- Cloud SQL and the Private Service Access peering can take 10-15 minutes to create.
