# PowerShell application deploy pipeline script
# MUST be run from the deploy/ folder
# Usage: cd deploy && .\scripts\deploy-app.ps1 -Environment <env> [-ImageTag <tag>]
# Example: cd deploy && .\scripts\deploy-app.ps1 -Environment qa
# Example: cd deploy && .\scripts\deploy-app.ps1 -Environment prd -ImageTag v1.2.3

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev','qa','uat','stg','prd')]
    [string]$Environment,

    [Parameter(Mandatory=$false)]
    [string]$ImageTag
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
    Write-Error-Custom "Terraform directory not found. Please run from deploy folder: cd deploy && .\scripts\deploy-app.ps1"
    exit 1
}

$TerraformDir = "$DeployDir\terraform"
$BackendConfig = "$TerraformDir\backend-$Environment.hcl"
$VarFile = "$TerraformDir\terraform-$Environment.tfvars"

Write-Info "App deploy pipeline starting for environment: $Environment"
Write-Host ""

# Step 0: Run unit tests
Write-Info "Step 0: Run unit tests"
Set-Location $ProjectRoot
npm test
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Unit tests failed"
    exit $LASTEXITCODE
}

# Step 1: Build and push API image
Write-Info "Step 1: Build and push API image"
if ([string]::IsNullOrEmpty($ImageTag)) {
    & "$DeployDir\scripts\deploy-image.ps1" -Environment $Environment
} else {
    & "$DeployDir\scripts\deploy-image.ps1" -Environment $Environment -ImageTag $ImageTag
}

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Failed to deploy API image"
    exit $LASTEXITCODE
}

# Step 2: Force ECS service deployment to pull latest image and set desired count
Write-Info "Step 2: Update ECS service to use latest image and set desired count to 1"
if (-not (Test-Path $BackendConfig)) {
    Write-Error-Custom "Backend config not found: $BackendConfig"
    exit 1
}
if (-not (Test-Path $VarFile)) {
    Write-Error-Custom "Var file not found: $VarFile"
    exit 1
}

$AwsRegion = (Select-String -Path $VarFile -Pattern 'aws_region\s*=\s*"([^"]+)"').Matches.Groups[1].Value
if ([string]::IsNullOrEmpty($AwsRegion)) {
    Write-Error-Custom "aws_region not found in $VarFile"
    exit 1
}

Set-Location $TerraformDir
terraform init -reconfigure "-backend-config=$BackendConfig"
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Terraform init failed"
    exit $LASTEXITCODE
}

$ClusterName = (terraform output -raw ecs_cluster_name 2>$null)
$ServiceName = (terraform output -raw ecs_service_name 2>$null)

if ([string]::IsNullOrEmpty($ClusterName) -or [string]::IsNullOrEmpty($ServiceName)) {
    Write-Error-Custom "Could not read ecs_cluster_name or ecs_service_name from Terraform outputs."
    Write-Error-Custom "Ensure infrastructure is deployed and outputs are available."
    exit 1
}

aws ecs update-service --cluster $ClusterName --service $ServiceName --force-new-deployment --desired-count 1 --region $AwsRegion | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "ECS service update failed"
    exit $LASTEXITCODE
}

# Step 3: Deploy static assets to S3/CloudFront
Write-Info "Step 3: Deploy static assets to S3/CloudFront (public/dist)"
Set-Location $ProjectRoot

$BuildScript = "build"
if ($Environment -in @('dev','qa','stg','uat')) {
    $BuildScript = "build:dev"
}

npm run $BuildScript
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Frontend build failed"
    exit $LASTEXITCODE
}

& "$DeployDir\scripts\deploy-static.ps1" -Environment $Environment
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Failed to deploy static assets"
    exit $LASTEXITCODE
}

Write-Host ""
Write-Info "App deploy pipeline complete!"
Write-Info "Cluster: $ClusterName"
Write-Info "Service: $ServiceName"