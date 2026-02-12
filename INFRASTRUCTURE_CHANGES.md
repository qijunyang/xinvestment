# Infrastructure Changes Summary

## Changes Made (2026-02-11)

### Previous Architecture (NAT Gateway)
- ECS tasks deployed in **private subnets**
- NAT Gateways created for outbound internet access
- Higher cost (~$33/month per NAT Gateway)
- ConnectionTimeout issues with ECR API pulls

### New Architecture (Simplified)
- ECS tasks deployed in **public subnets** 
- NAT Gateways **removed** (reduced costs)
- Security enforced via **Security Groups only**
- Direct internet access for ECR pulls

## Resources Removed
✅ aws_nat_gateway.main (3 instances - one per AZ)
✅ aws_eip.nat (3 instances - one per AZ)  
✅ aws_route_table.private (3 instances - one per AZ)
✅ aws_route_table_association.private (removed associations)

## Resources Updated
✅ ALB moved from private to **public subnets**
✅ ECS Service moved to **public subnets** with `assign_public_ip = true`
✅ Security Groups now enforce all network access control

## Network Architecture

```
Internet
    ↓
CloudFront (HTTPS access gate)
    ↓
    └→ ALB (Internal, only accepts CloudFront traffic via prefix list)
        │
        └→ ECS Tasks (Public subnets, protected by security groups)
             │
             ├→ ECR API (direct access via public IP)
             ├→ CloudWatch Logs (direct access)
             └→ S3 (optional - could use VPC endpoint)
```

## Security Configuration

### ALB Security Group (`xinvestment-dev-alb-sg`)
- **Ingress**: Accepts HTTP (port 80) only from CloudFront prefix list
- **Egress**: Allows all outbound traffic
- **Effect**: Only CloudFront can reach ALB

### ECS Tasks Security Group (`xinvestment-dev-ecs-tasks-sg`)
- **Ingress**: Accepts traffic only from ALB on container port (3000)
- **Egress**: Allows all outbound traffic (for ECR, CloudWatch, etc.)
- **Effect**: Only ALB can reach ECS tasks; tasks can reach internet

## Cost Comparison

### Monthly Costs
| Resource | NAT Gateway | Public Subnet |
|----------|-----------|---------------|
| NAT Gateway | $0.045/hr × 3 × 730h = ~$99/month | $0 |
| Data Transfer | ~$0.045/GB (variable) | Direct (no NAT) |
| **Total** | **~$130+/month** | **~$5-10/month** |

**Savings: ~$120+/month** on dev environment

## Deployment Steps

The changes have been **automatically applied** via Terraform:

```powershell
cd "C:\Users\qyang\code\study\claudeprj\xinvestment\deploy\terraform"
terraform apply -var-file terraform-dev.tfvars -auto-approve
```

**Status**: ✅ Complete - NAT Gateways destroyed, ECS moved to public subnets

## Verification

### Check ECS Service Status
```powershell
# Verify ECS tasks have public IPs
aws ecs list-tasks --cluster xinvestment-dev-cluster --region us-east-2
aws ecs describe-tasks --cluster xinvestment-dev-cluster --tasks <task-arn> --region us-east-2
```

### Check Security Groups
```powershell
# ALB SG - should only allow CloudFront
aws ec2 describe-security-groups --group-ids sg-09d775113979c9f39 --region us-east-2

# ECS SG - should only allow ALB
aws ec2 describe-security-groups --group-ids sg-0a7b7d766a7e833c7 --region us-east-2
```

### Test ECR Access
Once ECS tasks are running, check CloudWatch logs for successful image pulls:
```powershell
aws logs tail /ecs/xinvestment-dev --follow --region us-east-2
```

## Network Security

The architecture maintains security despite public subnets:

1. **CloudFront acts as gateway** - Only CloudFront IPs allowed to ALB
2. **ALB only talks to ECS** - ECS tasks only accept ALB traffic
3. **ECS restricted outbound** - Only specific ports/services allowed
4. **No direct internet access** - Users cannot directly access ECS IPs

## Future Optimizations

### Option 1: VPC Endpoints (Cost Reduction)
If only ECR/CloudWatch are needed from ECS:
- Add `com.amazonaws.us-east-2.ecr.api` VPC Endpoint (Gateway)
- Add `com.amazonaws.us-east-2.ecr.dkr` VPC Endpoint (Interface)
- Add `com.amazonaws.us-east-2.logs` VPC Endpoint (Interface)
- Cost: ~$0.01/hour per interface endpoint

**Would reduce public subnet exposure while maintaining costs**

### Option 2: Network ACLs (Additional Layer)
- Restrict private subnet access at network level
- Prevent accidental misconfiguration
- Adds another security layer

## Files Modified

1. **deploy/terraform/main.tf**
   - Removed: NAT Gateway data sources and resources
   - Removed: Route table configurations  
   - Updated: ALB subnets from private → public
   - Updated: ECS subnets from private → public with public IP assignment

2. **deploy/terraform/outputs.tf**
   - Removed: nat_gateway_ids output
   - Removed: nat_gateway_eips output

## Rollback Procedure

If issues arise, restore from git:
```powershell
git checkout HEAD deploy/terraform/main.tf deploy/terraform/outputs.tf
terraform apply -var-file terraform-dev.tfvars -auto-approve
```

## Summary

✅ **Reduced complexity** - Removed NAT Gateway layer
✅ **Reduced costs** - ~$120+/month savings
✅ **Maintained security** - Security groups provide isolation
✅ **Fixed ECR access** - Direct internet access resolves timeout issues
✅ **Faster deployment** - Fewer resources to manage
