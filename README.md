# Azure Cloud Enterprise Resource Planning Modernization for a Wholesale Distributor

## Executive summary

Cedar Row Office Supply is a fictional wholesaler whose offices share one on-premises ERP server. If that server goes down, invoicing stops and shipments can be delayed. I designed a move to Azure using Container Apps, managed MySQL, and Service Bus to keep invoicing available during a notification outage and recover records from backup after a database failure. Implementation and Azure validation are planned.

![Azure Cloud ERP · Enterprise Resource Planning Platform for Cedar Row Office Supply](docs/assets/cedar-row-erp-banner.png)

![Project at a glance. Architecture with seven views, Azure layout with four resource groups, release design with two paths, and planned Azure validation.](docs/assets/project-path.svg)

[![Deployment evidence. Azure deployment is planned.](docs/assets/deployment-evidence.svg)](#deployment-evidence)

[Business context](#business-context) · [Business problem](#business-problem) · [My contribution](#my-contribution) · [Landing zone](#landing-zone) · [Architecture diagrams](#architecture-diagrams) · [Validation plan](#validation-plan) · [Deployment evidence](#deployment-evidence)

## Business context

Cedar Row Office Supply is a fictional Toronto wholesaler with several sales offices and a shared warehouse. It sells paper, toner, and other office supplies to local businesses. Staff across the company rely on one ERP to check what is in stock, post invoices, and keep sales and accounting records in sync.

## Business problem

In this scenario, Cedar Row runs its ERP and database on one physical server at the warehouse. A hardware failure, a power outage at the warehouse, or maintenance on that server can cut off every office at once. Sales staff lose access to live stock counts, the warehouse can miss shipments, and delayed invoices can slow down payments.

Cedar Row needs the ERP to stay available during business hours and a way to recover its records after a serious outage. I designed the move to Azure to take the ERP off the warehouse hardware, keep invoicing running if the notification worker fails, and use managed database backups. The disaster recovery plan restores the database to a separate server and checks invoices, stock, and accounting records before staff resume work.

## My contribution

- **Application design.** I mapped the invoice flow from posting through stock and accounting updates to a separate notification worker.
- **Azure architecture.** I grouped the Terraform state, shared platform, ERP app, and notification service. I designed private access to MySQL and storage, scoped identities, and monitoring for each step of the invoice flow.
- **Delivery and recovery.** I planned separate releases and rollbacks for the ERP and worker, an isolated database restore, and the checks needed to verify them.

## Landing zone

The ERP web app has restricted HTTPS access. The worker runs in the same Container Apps environment without public ingress. Both have their own release paths. The network, data services, registry, secrets, and monitoring live in the shared platform resource group.

[![High-level Azure landing zone for Cedar Row Office Supply](docs/architecture/01-overview.png)](docs/architecture/01-overview.png)

[Editable draw.io file](docs/architecture/Azure-ERP-Architecture.drawio) · [Seven-page PDF](docs/architecture/Azure-ERP-Architecture.pdf) · [Design notes](docs/architecture/README.md)

## Architecture diagrams

| View | What it shows |
| --- | --- |
| [Landing zone](docs/architecture/01-overview.png) | The subscription, four resource groups, and invoice notification path. |
| [Network and ingress](docs/architecture/02-network.png) | HTTPS entry, delegated subnets, and private data paths. |
| [Invoice notifications](docs/architecture/03-event.png) | The invoice transaction, queue, receipt, and failure handling. |
| [Identity and ownership](docs/architecture/04-access.png) | The permissions each workload needs and the identities used for releases. |
| [Terraform and releases](docs/architecture/05-delivery.png) | The infrastructure build order, separate releases, and rollback points. |
| [Monitoring and alerts](docs/architecture/06-operations.png) | Container logs, invoice tracing, and operational alerts. |
| [Recovery and cleanup](docs/architecture/07-recovery.png) | Isolated database restore, file recovery, and teardown. |

## Validation plan

1. Post an invoice for two cartons at $15 each. Verify a $30 invoice, eight cartons remaining from ten, and the corresponding accounting entries.
2. Pause the notification worker in Azure. Post another invoice and verify it succeeds. Restart the worker and trace the event to its receipt.
3. Deliver the same event twice and verify that it produces one receipt.
4. Roll back the ERP and worker independently. Restore MySQL to a separate server and verify the restored records before teardown.

## Deployment evidence

Azure deployment is planned. This section will hold the Terraform apply output, Azure resource screenshots, and results from the invoice and recovery checks after the deployment is verified.
