# PowerShell deploy pipeline script
# Usage: .\deploy-pipeline.ps1 -Environment <env>
# Example: .\deploy-pipeline.ps1 -Environment qa

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev','qa','uat','stg','prd')]
    [string]$Environment
)

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

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Join-Path $ScriptDir "..\.."
$TerraformDir = Join-Path $ProjectRoot "deploy\terraform"
$BackendConfig = Join-Path $TerraformDir "backend-$Environment.hcl"
$VarFile = Join-Path $TerraformDir "terraform-$Environment.tfvars"

Write-Info "Deploy pipeline starting for environment: $Environment"
Write-Host ""

# Step 1: Ensure Terraform backend S3 bucket exists
Write-Info "Step 1: Ensure Terraform backend S3 bucket exists"
& (Join-Path $ScriptDir "setup-terraform-backend.ps1")
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Failed to set up Terraform backend"
    exit $LASTEXITCODE
}

# Step 2: Ensure ECR repository exists
Write-Info "Step 2: Ensure ECR repository exists"
if (-not (Test-Path $VarFile)) {
    Write-Error-Custom "Var file not found: $VarFile"
    exit 1
}

$AwsRegion = (Select-String -Path $VarFile -Pattern 'aws_region\s*=\s*"([^"]+)"').Matches.Groups[1].Value
if ([string]::IsNullOrEmpty($AwsRegion)) {
    Write-Error-Custom "aws_region not found in $VarFile"
    exit 1
}

& (Join-Path $ScriptDir "setup-ecr.ps1") -Region $AwsRegion
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Failed to set up ECR repository"
    exit $LASTEXITCODE
}

# Step 3: Build and push API image
Write-Info "Step 3: Build and push API image"
& (Join-Path $ScriptDir "deploy-image.ps1") -Environment $Environment
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Failed to deploy API image"
    exit $LASTEXITCODE
}

# Step 4: Terraform apply (infra)
Write-Info "Step 4: Deploy infrastructure with Terraform"
if (-not (Test-Path $BackendConfig)) {
    Write-Error-Custom "Backend config not found: $BackendConfig"
    exit 1
}

Set-Location $TerraformDir
terraform init -backend-config=$BackendConfig
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Terraform init failed"
    exit $LASTEXITCODE
}

terraform apply -var-file=$VarFile
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Terraform apply failed"
    exit $LASTEXITCODE
}

# Step 5: Deploy static assets to S3/CloudFront
Write-Info "Step 5: Deploy static assets to S3/CloudFront"
Set-Location $ProjectRoot
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Frontend build failed"
    exit $LASTEXITCODE
}

& (Join-Path $ScriptDir "deploy-static.ps1") -Environment $Environment
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Failed to deploy static assets"
    exit $LASTEXITCODE
}

Write-Host ""
Write-Info "Deploy pipeline complete!"
Write-Host ""
Write-Info "Get URLs with:"
Write-Host "  cd deploy\terraform"
Write-Host "  terraform output cdn_url"
Write-Host "  terraform output api_url"
Write-Host ""
Write-Warn-Custom "TLS note: CloudFront custom cert must be in us-east-1; ALB cert is in backend_region."
