# PowerShell script to deploy static assets to S3 and invalidate CloudFront
# Usage: .\deploy-static.ps1 -Environment <env>
# Example: .\deploy-static.ps1 -Environment qa

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev','qa','uat','stg','prd')]
    [string]$Environment
)

# Colors for output
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Warn-Custom {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

Write-Info "Deploying static assets for environment: $Environment"

# Change to project root
$ProjectRoot = Join-Path $PSScriptRoot "..\..\"
Set-Location $ProjectRoot

# Check if dist folder exists
if (-not (Test-Path "dist")) {
    Write-Error-Custom "dist folder not found. Please run 'npm run build' first."
    exit 1
}

# Get S3 bucket and CloudFront distribution ID from Terraform output
$TerraformDir = Join-Path $ProjectRoot "deploy\terraform"
Set-Location $TerraformDir

Write-Info "Getting infrastructure info from Terraform..."
$TerraformOutput = terraform output -json | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Failed to get Terraform outputs. Make sure infrastructure is deployed."
    exit 1
}

$S3Bucket = $TerraformOutput.s3_static_assets_bucket.value
$CloudFrontDistId = $TerraformOutput.cloudfront_distribution_id.value
$CdnUrl = $TerraformOutput.cdn_url.value

if ([string]::IsNullOrEmpty($S3Bucket) -or [string]::IsNullOrEmpty($CloudFrontDistId)) {
    Write-Error-Custom "Could not retrieve S3 bucket or CloudFront distribution ID from Terraform."
    exit 1
}

Write-Info "S3 Bucket: $S3Bucket"
Write-Info "CloudFront Distribution: $CloudFrontDistId"
Write-Info "CDN URL: $CdnUrl"

# Return to project root
Set-Location $ProjectRoot

# Sync dist folder to S3
Write-Info "Uploading static assets to S3..."
aws s3 sync dist/ "s3://$S3Bucket/" `
    --delete `
    --cache-control "public,max-age=31536000,immutable" `
    --exclude "*.html" `
    --exclude "*.map"

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Failed to sync assets to S3"
    exit 1
}

# Upload HTML files with shorter cache duration
Write-Info "Uploading HTML files with shorter cache..."
aws s3 sync dist/ "s3://$S3Bucket/" `
    --exclude "*" `
    --include "*.html" `
    --cache-control "public,max-age=300"

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Failed to upload HTML files to S3"
    exit 1
}

Write-Info "Static assets uploaded successfully!"

# Create CloudFront invalidation
Write-Info "Creating CloudFront invalidation..."
$InvalidationId = (aws cloudfront create-invalidation `
    --distribution-id $CloudFrontDistId `
    --paths "/*" `
    --query 'Invalidation.Id' `
    --output text)

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Failed to create CloudFront invalidation"
    exit 1
}

Write-Info "CloudFront invalidation created: $InvalidationId"
Write-Info "Invalidation may take a few minutes to complete."

Write-Host ""
Write-Info "Deployment complete!"
Write-Host ""
Write-Info "CDN URL: $CdnUrl"
Write-Info "You can check invalidation status with:"
Write-Host "  aws cloudfront get-invalidation --distribution-id $CloudFrontDistId --id $InvalidationId"
