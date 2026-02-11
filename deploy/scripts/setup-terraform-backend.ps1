# PowerShell script to create Terraform backend S3 bucket
# This only needs to be run once
# Usage: .\setup-terraform-backend.ps1

$BucketName = "xinvestment-terraform-state"
$Region = "us-east-1"

Write-Host "Setting up Terraform backend S3 bucket..." -ForegroundColor Green
Write-Host "Bucket: $BucketName" -ForegroundColor Cyan
Write-Host "Region: $Region" -ForegroundColor Cyan
Write-Host ""

# Create S3 bucket
Write-Host "Creating S3 bucket..." -ForegroundColor Yellow
aws s3 mb "s3://$BucketName" --region $Region

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ S3 bucket created successfully" -ForegroundColor Green
    
    # Enable versioning
    Write-Host "Enabling versioning on S3 bucket..." -ForegroundColor Yellow
    aws s3api put-bucket-versioning --bucket $BucketName --versioning-configuration Status=Enabled
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Versioning enabled" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to enable versioning" -ForegroundColor Red
    }
} else {
    Write-Host "✗ Failed to create S3 bucket (it may already exist)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host ""
Write-Host "Backend setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Note: State locking is disabled (no DynamoDB table). Fine for solo/demo work." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. cd deploy\terraform"
Write-Host "  2. terraform init -backend-config=backend-dev.hcl"
Write-Host "  3. terraform plan -var-file=terraform-dev.tfvars"
