# Cedar Row live ERP showcase

[![Live ERP Deployed Access](assets/live-erp-access.svg)](https://erp.spiraml.com/)

The Cedar Row ERP is live on Azure. Staff, customers, and vendors sign in with assigned accounts. [Azure landing zone](architecture/01-overview.png) · [Azure deployment evidence](../README.md#deployment-evidence)

[Sales and payments](#sales-and-payments) · [Purchasing and inventory](#purchasing-and-inventory) · [Customer and vendor accounts](#customer-and-vendor-accounts) · [Projects, people, and support](#projects-people-and-support)

## Sales and payments

**Account dashboard.** Staff review customer payments, vendor payments, and expenses. The browser connects to the ERP on Azure Container Apps over HTTPS. The app reads the records from MySQL over a private network. [Network diagram](architecture/02-network.png) · [Staff entry page](assets/live-erp/staff-workspace.jpg)

![Staff finance dashboard with payment totals and monthly trends](assets/live-erp/account-dashboard.jpg)

**Sales register and invoice detail.** Staff see posted sales and outstanding balances. The ERP saves the invoice, stock change, accounting entries, and notification event in one MySQL transaction. [Invoice flow](architecture/03-event.png)

![Sales register with invoice totals, balances, and payment statuses](assets/live-erp/sales-invoices.jpg)

![Paid sales invoice showing four line items and a zero balance](assets/live-erp/paid-sales-invoice.jpg)

**Notifications.** A scheduled job sends invoice events from MySQL to Azure Service Bus. The worker records receipts in Azure Table Storage. During the outage drill, the ERP posted an invoice while the worker was stopped. After the restart, Log Analytics showed the same event ID on the invoice and receipt. [Azure outage evidence](../README.md#notification-outage-and-recovery)

**Payments and ledger.** The payment register shows money received from customers. The ledger shows how each payment affects the customer’s balance. Both views read financial records from MySQL. [MySQL recovery evidence](../README.md#data-recovery-drills)

![Customer payment register showing cleared payments](assets/live-erp/customer-payments.jpg)

![Ledger showing the customer payment and the related sales and inventory entries](assets/live-erp/ledger.jpg)

## Purchasing and inventory

**Purchase invoices and inventory.** Purchase invoices record what the warehouse bought. The item catalog shows stock on hand for those products. Both types of records are stored in MySQL on the Azure virtual network. [Network diagram](architecture/02-network.png)

![Purchase invoice register with vendor balances and statuses](assets/live-erp/purchase-invoices.jpg)

![Paid vendor invoice showing the replenishment items and warehouse](assets/live-erp/paid-purchase-invoice.jpg)

![Inventory catalog showing office supplies, SKUs, prices, and available quantities](assets/live-erp/inventory.jpg)

**Data recovery.** The ERP stores business records in MySQL and uploads in Blob Storage. I restored isolated database records from a logical backup and recovered a deleted file from an earlier blob version. [Recovery procedure](architecture/07-recovery.png) · [Restore evidence](../README.md#data-recovery-drills)

## Customer and vendor accounts

**Customer and vendor views.** Each account shows its own invoices. Azure workloads use managed identities with permissions scoped to their roles. [Identity diagram](architecture/04-access.png) · [Customer payment dashboard](assets/live-erp/customer-dashboard.jpg)

![Customer invoice cards showing a paid invoice and a partially paid invoice](assets/live-erp/customer-invoices.jpg)

![Vendor invoice card showing the paid replenishment invoice](assets/live-erp/vendor-invoices.jpg)

## Projects, people, and support

Projects, people, and support run inside the ERP web app. In Azure, I used Log Analytics to inspect app logs and configured alerts for application errors, MySQL CPU, and messages that failed processing. [Monitoring diagram](architecture/06-operations.png) · [Alert evidence](../README.md#azure-monitor-alerts)

**Project board.** Staff track customer work, deadlines, and task progress.

![Project board showing three projects and task completion progress](assets/live-erp/projects.jpg)

**HRM dashboard.** Staff review staffing and leave requests across branches.

![People dashboard with departments, branch counts, calendar, and leave requests](assets/live-erp/people-dashboard.jpg)

**Support queue.** Staff track customer requests and follow up on delivery issues.

![Support ticket register with closed, in-progress, and on-hold customer requests](assets/live-erp/support-tickets.jpg)
