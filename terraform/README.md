# Terraform

I used these four roots to deploy the [Azure landing zone](../docs/architecture/01-overview.png). The deployment and recovery results are in the [project evidence](../README.md#deployment-evidence).

| Root | Resource group | What it creates |
| --- | --- | --- |
| `bootstrap` | `rg-erp-state` | Azure Blob state storage and container-scoped access for the operator |
| `platform` | `rg-erp-platform` | VNet, private DNS, shared Container Apps environment, MySQL, Blob, Table, Service Bus, ACR, Key Vault and monitoring |
| `erp` | `rg-erp-app` | ERP web app, manual migration job and scheduled outbox job |
| `notification` | `rg-erp-notification` | Notification worker and manual receipt verifier |

The platform root creates the app and notification groups and their runtime identities. The workload roots deploy into those groups and use separate state containers so the ERP and worker can be updated independently.

## Inputs

The examples target Canada Central. Copy each example to an ignored `.tfvars` file. Use the same short lowercase suffix in the bootstrap and platform inputs so globally named resources are unique. Pick the MySQL tier, storage redundancy and replica sizes supported by the account and region. A separate account or deployment needs its own state.

Use the Azure CLI sign-in and set `ARM_SUBSCRIPTION_ID` from the intended active account. The operator needs resource creation and role-assignment permissions. Register the following providers if missing: `Microsoft.Storage`, `Microsoft.Network`, `Microsoft.App`, `Microsoft.OperationalInsights`, `Microsoft.Insights`, `Microsoft.DBforMySQL`, `Microsoft.ServiceBus`, `Microsoft.ContainerRegistry`, `Microsoft.KeyVault`, and `Microsoft.ManagedIdentity`.

Supply the MySQL administrator password as `TF_VAR_mysql_admin_password` and the alert recipient as `TF_VAR_alert_email`. Keep credentials, local inputs, plans, and state private. The platform state contains the database administrator password, so its container is for authorized deployment operators only.

## Deployment steps

1. **State.** Run `terraform init` for `bootstrap`, save and review a plan, then apply it. Its `backends` output has the settings for the three remote state containers. Wait for the Blob role assignment to take effect.
2. **Platform.** Initialize with the platform backend settings. Save, review and apply the plan. Its `platform` output provides the non-secret values for both workload roots. Optional `github_subjects` values configure GitHub OIDC identities for registry publishing.
3. **Images and database.** Build both private images for `linux/amd64` and push them to the registry. Use an authorized client inside the VNet to create the ERP, relay and migration logins over TLS. Set their passwords and the Laravel app key in Key Vault before running `terraform plan` for the ERP root.
4. **ERP.** On the first run, save and apply a plan targeting `azurerm_role_assignment.secrets` so the job can read its Key Vault secrets. Once those roles take effect, save and apply a full plan with `enable_web = false` and `enable_relay = false` to create `erp-migrate`. Run the job, check its result, then grant the relay login access to the new outbox table. Add your approved source IPv4 CIDRs and set `enable_web = true` to deploy ERP HTTPS ingress. Check login, invoice posting and uploads.
5. **Notifications.** Apply the worker and receipt verifier using their own state. Then set `enable_relay = true` and apply the ERP root to start scheduled publishing.

After applying the bootstrap and platform roots, run these commands from the repository root to generate backend settings and shared workload inputs. They require `jq`.

```sh
mkdir -p .local
terraform -chdir=terraform/bootstrap output -json backends |
  jq -r '.platform | to_entries[] | "\(.key) = \(.value | tojson)"' > .local/platform.backend.hcl
terraform -chdir=terraform/platform init -backend-config=../../.local/platform.backend.hcl

terraform -chdir=terraform/platform output -json platform |
  jq '{platform: .}' > .local/platform.tfvars.json
```

Use the same backend extraction for `.erp` and `.notification`. Pass both workload roots the generated JSON with `-var-file=../../.local/platform.tfvars.json`, alongside their own inputs. Save the plan for each root with `terraform plan -out=...` and apply that reviewed file. GitHub OIDC can push images to the registry. Run Terraform with the operator’s Azure account.

## Image inputs

| Root | Inputs from the private build |
| --- | --- |
| ERP | `erp_image` as `erp@sha256:<digest>` and the image's `migration_command` and `relay_command`. Defaults use `erp_app`, `erp_relay` and `erp_migrate` for database users and `app-key`, `erp-db-password`, `relay-db-password` and `migration-db-password` for Key Vault secrets. The web container listens on port 8080 with `/health/live` and `/health/ready`. |
| Notification | `notification_image` as `notification@sha256:<digest>`. Its worker reads `SERVICE_BUS_FQDN`, `SERVICE_BUS_QUEUE_NAME`, `RECEIPTS_TABLE_URI` and `RECEIPTS_TABLE_NAME`. The same image runs a receipt verifier with `verifier_args`. |

The ERP image must include the invoice transaction, outbox and relay commands. The notification image must include the worker and verifier. Maintain these separately from the Terraform.

## Deployment evidence

The evidence includes the four resource groups, ERP readiness checks, Service Bus metrics, and the invoice event traced to the worker receipt. The recovery drills restored a deleted blob from its previous version and verified a logical MySQL restore against the original records. [Deployment evidence](../README.md#deployment-evidence) · [Recovery drills](../README.md#data-recovery-drills)

## Cleanup order

Destroy in reverse order. Remove the notification and ERP workloads before the shared platform. Review any temporary restore resources and remove the state storage last.
