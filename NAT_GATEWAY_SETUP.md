# NAT Gateway Setup for ECS Private Subnets

## Problem
ECS tasks in private subnets were unable to pull Docker images from Amazon ECR, causing the following error:
```
ResourceInitializationError: unable to pull secrets or registry auth: 
The task cannot pull registry auth from Amazon ECR: There is a connection issue 
between the task and Amazon ECR. operation error ECR: GetAuthorizationToken, 
exceeded maximum number of attempts, 3
```

This occurs because private subnets have no direct internet access to reach ECR API endpoints.

## Solution: NAT Gateway

A NAT Gateway allows resources in private subnets to initiate outbound connections to the internet while remaining unexposed to inbound connections.

## What Was Added

### 1. **Data Sources** (main.tf)
- `data.aws_subnet.private` - Fetches details of all private subnets
- `data.aws_subnet.public` - Fetches details of all public subnets  
- `data.aws_internet_gateway.selected` - Retrieves the VPC's Internet Gateway

### 2. **Local Values** (main.tf)
- `local.public_subnet_by_az` - Map of availability zones to public subnet IDs
- `local.private_subnets_by_az` - Map of availability zones to private subnet IDs

This ensures NAT Gateways and route tables are created per availability zone for high availability.

### 3. **Elastic IPs** (main.tf)
```hcl
resource "aws_eip" "nat"
```
- One Elastic IP per availability zone
- Used by NAT Gateways for outbound connections
- Named: `{project}-{env}-nat-eip-{availability_zone}`

### 4. **NAT Gateways** (main.tf)
```hcl
resource "aws_nat_gateway" "main"
```
- One NAT Gateway per public subnet (per AZ)
- Placed in public subnets to access Internet Gateway
- Named: `{project}-{env}-nat-{availability_zone}`

### 5. **Private Route Tables** (main.tf)
```hcl
resource "aws_route_table" "private"
```
- Custom route tables for private subnets
- Routes outbound traffic (0.0.0.0/0) through NAT Gateway in same AZ
- Association with private subnets via `aws_route_table_association.private`

### 6. **Outputs** (outputs.tf)
```hcl
output "nat_gateway_ids"
output "nat_gateway_eips"
```
- Display NAT Gateway IDs and their public IP addresses
- Useful for monitoring and debugging

## Deployment Steps

### 1. Review the Plan
```powershell
cd "C:\Users\qyang\code\study\claudeprj\xinvestment\deploy\terraform"
terraform plan -var-file terraform-dev.tfvars
```

### 2. Apply the Configuration
```powershell
terraform apply -var-file terraform-dev.tfvars -auto-approve
```

### 3. Verify NAT Gateways
```powershell
terraform output nat_gateway_ids
terraform output nat_gateway_eips
```

## Expected Results

After deployment:
- ✅ ECS tasks can reach ECR API endpoints
- ✅ Docker images will pull successfully
- ✅ CloudWatch logs will be sent successfully
- ✅ Any outbound HTTPS traffic from private subnets will work
- ✅ Private subnets remain isolated (no inbound access)

## Network Flow

```
┌─────────────────────────────────────────────┐
│         AWS VPC                             │
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │   Private Subnets (ECS Tasks)         │ │
│  │   ├─ task1 (10.0.2.x)                 │ │
│  │   └─ task2 (10.0.3.x)                 │ │
│  │   (Outbound: 0.0.0.0/0 → NAT GW)      │ │
│  └───────────────────────────────────────┘ │
│                   ↓                         │
│  ┌───────────────────────────────────────┐ │
│  │   NAT Gateways (in Public Subnets)    │ │
│  │   ├─ NAT-us-east-2a                   │ │
│  │   └─ NAT-us-east-2b                   │ │
│  └───────────────────────────────────────┘ │
│                   ↓                         │
│  ┌───────────────────────────────────────┐ │
│  │   Internet Gateway                    │ │
│  └───────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
          ↓
    Internet / ECR API
```

## Cost Considerations

NAT Gateway pricing:
- **Hourly charge**: ~$0.045/hour per NAT Gateway per region
- **Data transfer**: $0.045/GB for data processed through NAT Gateway
- For dev environment with low traffic: ~$33/month + data transfer

## Alternative: VPC Endpoints (Optional)

For cost optimization, consider adding VPC Endpoints for:
- **com.amazonaws.{region}.ecr.api** - ECR API calls
- **com.amazonaws.{region}.ecr.dkr** - Docker layer operations  
- **com.amazonaws.{region}.s3** - S3 access
- **com.amazonaws.{region}.logs** - CloudWatch Logs

VPC Endpoints are typically cheaper if you only need ECR, but NAT Gateway provides flexibility for all outbound services.

## Troubleshooting

### NAT Gateway not working?
1. Check security group allows outbound traffic on port 443 (HTTPS for ECR)
2. Verify route tables are associated with private subnets
3. Check CloudWatch logs in `/ecs/xinvestment-{env}`

### Terraform Apply Fails?
1. Ensure VPC and subnets exist with proper tagging
2. Verify Internet Gateway is attached to VPC
3. Run `terraform refresh` to sync state
4. Check AWS credentials have permissions for:
   - ec2:CreateNatGateway
   - ec2:AllocateAddress
   - ec2:CreateRouteTable
   - ec2:AssociateRouteTable

## Related Issues Fixed
- ECS task pull registry auth errors
- i/o timeout connecting to ECR API
- Private subnet outbound connectivity for ECS tasks
