# PowerShell application destroy pipeline script
# MUST be run from the deploy/ folder
# Usage: cd deploy && .\scripts\destroy-app.ps1 -Environment <env>
# Example: cd deploy && .\scripts\destroy-app.ps1 -Environment dev

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

# Get the deploy folder (one level up from scripts folder)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DeployDir = Split-Path -Parent $ScriptDir

# Validate paths
if (-not (Test-Path "$DeployDir\terraform")) {
    Write-Error-Custom "Terraform directory not found. Please run from deploy folder: cd deploy && .\scripts\destroy-app.ps1 -Environment $Environment"
    exit 1
}

$TerraformDir = "$DeployDir\terraform"
$BackendConfig = "$TerraformDir\backend-$Environment.hcl"
$VarFile = "$TerraformDir\terraform-$Environment.tfvars"

Write-Info "Destroy app pipeline starting for environment: $Environment"
Write-Host ""

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

aws ecs update-service --cluster $ClusterName --service $ServiceName --desired-count 0 --region $AwsRegion | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "ECS service update failed"
    exit $LASTEXITCODE
}

Write-Host ""
Write-Info "Destroy app pipeline complete!"
Write-Info "Cluster: $ClusterName"
Write-Info "Service: $ServiceName"