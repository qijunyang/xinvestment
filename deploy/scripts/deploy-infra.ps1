# PowerShell infrastructure deploy pipeline script
# MUST be run from the deploy/ folder
# Usage: cd deploy && .\scripts\deploy-infra.ps1 -Environment <env>
# Example: cd deploy && .\scripts\deploy-infra.ps1 -Environment qa

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

# Get the deploy folder (one level up from scripts folder)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DeployDir = Split-Path -Parent $ScriptDir
$ProjectRoot = Split-Path -Parent $DeployDir

# Validate paths
if (-not (Test-Path "$DeployDir\terraform")) {
    Write-Error-Custom "Terraform directory not found. Please run from deploy folder: cd deploy && .\scripts\deploy-infra.ps1"
    exit 1
}

$TerraformDir = "$DeployDir\terraform"
$BackendConfig = "$TerraformDir\backend-$Environment.hcl"
$VarFile = "$TerraformDir\terraform-$Environment.tfvars"

Write-Info "Infra deploy pipeline starting for environment: $Environment"
Write-Host ""

# Step 1: Ensure Terraform backend S3 bucket exists
Write-Info "Step 1: Ensure Terraform backend S3 bucket exists"
& "$DeployDir\scripts\setup-terraform-backend.ps1"
# Ignore errors - bucket may already exist

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

& "$DeployDir\scripts\setup-ecr.ps1" -Region $AwsRegion
# Ignore errors - repository may already exist

# Step 3: Terraform apply (infra)
Write-Info "Step 3: Deploy infrastructure with Terraform"
if (-not (Test-Path $BackendConfig)) {
    Write-Error-Custom "Backend config not found: $BackendConfig"
    exit 1
}

Set-Location $TerraformDir
terraform init -reconfigure "-backend-config=$BackendConfig"
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Terraform init failed"
    exit $LASTEXITCODE
}

terraform apply -auto-approve "-var-file=$VarFile"
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Terraform apply failed"
    exit $LASTEXITCODE
}

Write-Host ""
Write-Info "Infra deploy pipeline complete!"
Write-Host ""
Write-Info "Get URLs with:"
Write-Host "  cd deploy\terraform"
Write-Host "  terraform output cdn_url"
Write-Host "  terraform output api_url"
Write-Host ""
Write-Warn-Custom "TLS note: CloudFront custom cert must be in us-east-1; ALB cert is in backend_region."