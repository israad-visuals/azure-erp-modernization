# Azure deployment architecture

[Project overview](../../README.md) · [Editable draw.io file](Azure-ERP-Architecture.drawio) · [Seven-page PDF](Azure-ERP-Architecture.pdf)

## Resource ownership

| Resource group | Purpose |
| --- | --- |
| `rg-erp-state` | Azure Blob Storage for Terraform state and the access assignments for deployment operators. |
| `rg-erp-platform` | Virtual network, private DNS, Container Apps environment, MySQL, Service Bus, storage, Container Registry, Key Vault, and monitoring. |
| `rg-erp-app` | ERP web app, outbox relay job, migration job, and their runtime identities. |
| `rg-erp-notification` | .NET notification worker, receipt verifier job, and their runtime identities. |

## Network and identity

I deployed the ERP in one Azure region with separate virtual network subnets for Container Apps, MySQL, and private endpoints. Only the ERP web app exposes HTTPS ingress, limited to approved source IPs in the Terraform configuration. MySQL uses private network access. The Blob and Table storage accounts use separate private endpoints and private DNS.

Service Bus, Container Registry, and Key Vault use authenticated public endpoints over TLS. The relay can send to Service Bus and update outbox rows. The worker can receive from the queue and write notification receipts. The ERP app and migration job have separate database credentials. Deployment and image pull access are separate from workload access.

## Invoice and notification flow

1. The ERP posts the invoice, updates stock and the accounting records, and saves an invoice event in the same MySQL transaction. The saved event is the outbox record.
2. The scheduled relay publishes pending events to the Service Bus queue. It retries with the same event ID if publishing fails.
3. The .NET worker receives the event and stores a receipt in Azure Table Storage before acknowledging the message. It uses the event ID to avoid creating another receipt if the same message arrives again.
4. The verifier can check receipts. Failed messages that reach their delivery limit go to a dead-letter queue for investigation and controlled replay.

The notification worker records a synthetic receipt. The ERP stays responsible for invoice posting and can continue to do so while the worker is paused, as long as the ERP and database are healthy. An outage in the shared Container Apps environment or the database remains a separate failure scenario.

## Releases and recovery

I bootstrapped the Terraform backend, applied the shared platform, published both images to Azure Container Registry, and deployed the applications and jobs. The ERP and worker use separate image versions and can be released independently. Log Analytics traced an invoice from posting through publishing and receipt processing. [Monitoring and outage evidence](../../README.md#notification-outage-and-recovery)

The recovery drills restored a deleted upload from an earlier blob version and isolated MySQL records from a logical backup. The recovery diagram also documents the separate-server point-in-time restore and cutover procedure. [Recovery evidence](../../README.md#data-recovery-drills) · [Recovery diagram](07-recovery.png)

[Microsoft Azure architecture icons](https://learn.microsoft.com/en-us/azure/architecture/icons/)
