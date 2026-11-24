# ShopSphere – Azure Infrastructure Automation with Terraform

A hands-on Infrastructure as Code (IaC) project that provisions a segmented Azure network and a private backend Linux virtual machine using Terraform and the AzureRM provider.

> **Scope:** This repository represents an infrastructure lab, not a complete or production-ready e-commerce application. It creates the network foundation and one backend VM. It does not deploy an application or provision a frontend compute tier, public IP, load balancer, or web entry point.

## Architecture overview

- Azure Resource Group in **Central India**.
- Virtual Network: `10.0.0.0/16`.
- Frontend subnet: `10.0.1.0/24`.
- Backend subnet: `10.0.2.0/24`.
- Frontend NSG allows inbound TCP 80 and 443.
- Backend NSG allows inbound TCP 8080 only from the frontend subnet.
- Backend network interface and Ubuntu 24.04 Linux VM with private networking and SSH public-key authentication.
- Azure Blob Storage remote state with Azure AD authentication and blob lease-based state locking.
- A separate example demonstrates Terraform `count`, locals, conditional expressions, functions, and modules using `terraform_data` only.

See [docs/architecture.md](docs/architecture.md) for the architecture diagram and network notes.

## Repository structure

```text
.
├── main.tf
├── variables.tf
├── outputs.tf
├── backend.hcl.example
├── terraform.tfvars.example
├── modules/
│   └── app/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── examples/
│   └── terraform-language/
│       └── main.tf
├── docs/
│   └── architecture.md
└── .github/workflows/terraform.yml
```

## Prerequisites

- Terraform `>= 1.5.0`.
- Azure CLI.
- An Azure subscription. The original lab was built using Azure for Students.
- An SSH key pair. Terraform reads only the public key (`.pub`) from your local machine.
- Access to the existing Azure Blob Storage account used for remote state, with **Storage Blob Data Contributor** or equivalent data-plane permissions on the state container/account.

## Authentication and configuration

1. Sign in to Azure CLI:

   ```powershell
   az login
   ```

2. Set the subscription ID in your current PowerShell session. Do not put it in source code:

   ```powershell
   $env:ARM_SUBSCRIPTION_ID = "<YOUR_SUBSCRIPTION_ID>"
   az account set --subscription $env:ARM_SUBSCRIPTION_ID
   ```

3. Create a local backend configuration from the example:

   ```powershell
   Copy-Item backend.hcl.example backend.hcl
   ```

   Edit `backend.hcl` and replace the state resource group and storage account placeholders with the **existing** remote backend values. Keep the existing container and state key if you are reconnecting to the state already used by this project. `backend.hcl` is ignored by Git.

4. Create your local variable file and update the SSH public-key path:

   ```powershell
   Copy-Item terraform.tfvars.example terraform.tfvars
   notepad terraform.tfvars
   ```

   The default public-key path is `~/.ssh/shopsphere_azure.pub`. Change it if your public key is stored elsewhere. Never point this variable to a private key.

## Initialize and validate

Run these commands from the repository root:

```powershell
terraform fmt -recursive
terraform init -backend-config=backend.hcl
terraform validate
terraform plan
```

The backend configuration is intentionally external to the tracked `.tf` files. When reconnecting to the already-migrated remote state, use the same storage account, container, and key. Do not use `-reconfigure`, change the state key, or create a new state backend casually. If Terraform reports that backend migration is required, stop and verify the displayed old and new backend settings before proceeding. Do not overwrite or discard the existing remote state.

Review the plan carefully. This repository is designed to describe the existing lab infrastructure; it is not a command to recreate resources blindly. Do not run `terraform apply` unless you have reviewed and explicitly intend to apply the proposed changes.

Useful state inspection commands:

```powershell
terraform state list
terraform output
```

## Terraform language examples

The `examples/terraform-language` directory is a separate, provider-free demonstration of:

- `count` and `count.index`.
- `locals` and conditional expressions.
- Built-in functions: `lower`, `upper`, `length`, `join`, and `split`.
- A reusable local module.

Run the example independently:

```powershell
Set-Location examples/terraform-language
terraform init
terraform validate
terraform plan
Set-Location ../..
```

These example resources use Terraform's built-in `terraform_data` resource. They do not provision Azure infrastructure.

## Remote state security

- State can contain sensitive infrastructure metadata. Keep the state in the private Azure Blob backend.
- Never commit `terraform.tfstate`, `terraform.tfstate.backup`, `.terraform/`, `backend.hcl`, or real `*.tfvars` files.
- Commit `.terraform.lock.hcl` after generating it locally so provider selections are reproducible.
- Do not commit subscription IDs, credentials, access keys, SSH private keys, or service-principal secrets.
- The backend storage account name and resource group are supplied locally rather than embedded in this repository.

## Cost and operational notes

- The original backend VM was deallocated to reduce compute charges. A deallocated VM's managed OS disk and other retained resources can still incur charges.
- The remote state storage account and its stored data can also incur storage/transaction charges.
- Check the Azure Cost Management view before leaving resources running. This project does not automatically enforce a spending limit.
- The frontend NSG's HTTP/HTTPS rules are a lab configuration. Restrict source ranges and add appropriate edge protection before adapting this design for production.

## CI validation

GitHub Actions runs Terraform formatting and validation without connecting to the Azure backend. It does not run `plan` or `apply` against your subscription.

## Learning outcomes

- Azure infrastructure provisioning with Terraform.
- Terraform providers, resources, variables, outputs, and dependency ordering.
- Azure virtual networks, subnets, NSGs, NICs, and Linux VMs.
- Remote state configuration and Azure Blob state locking.
- Terraform modules, meta-arguments, locals, conditional expressions, and built-in functions.
- Repository hygiene and automated Terraform validation.

## License

Add a license if you want others to reuse or redistribute this project. Until then, all rights are reserved by the repository owner by default.
