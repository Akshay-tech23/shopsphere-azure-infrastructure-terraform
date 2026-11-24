# ShopSphere infrastructure architecture

The Terraform root configuration describes the following Azure resources in Central India:

```mermaid
flowchart TB
    subgraph RG[Resource Group: rg-shopsphere-dev]
        subgraph VNET[Virtual Network: 10.0.0.0/16]
            subgraph FRONT[Frontend subnet: 10.0.1.0/24]
                FNSG[NSG: nsg-frontend\nInbound TCP 80 and 443]
            end
            subgraph BACK[Backend subnet: 10.0.2.0/24]
                BNSG[NSG: nsg-backend\nTCP 8080 from frontend subnet]
                NIC[Backend network interface\nPrivate IP]
                VM[Ubuntu 24.04 Linux VM\nNo public IP]
            end
        end
        FNSG --- FRONT
        BNSG --- BACK
        NIC --> VM
    end
    FRONT -. permitted API source .-> BACK
    STATE[Separate remote state storage\nAzure Blob Storage] -. Terraform state and lease .- RG
```

## Network rules

- Frontend subnet: `10.0.1.0/24`.
- Backend subnet: `10.0.2.0/24`.
- Frontend NSG: inbound TCP 80 and 443 are allowed from any IPv4 source.
- Backend NSG: inbound TCP 8080 is allowed only from `10.0.1.0/24`.
- The backend VM has no public IP. The configuration does not create a frontend VM, public IP, load balancer, NAT gateway, or application deployment.

## Remote state

Terraform state is stored in an Azure Blob container in a separate resource group. The backend configuration is supplied locally through `backend.hcl`; the actual storage account details are intentionally not included in this repository.
