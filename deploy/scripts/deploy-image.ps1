# PowerShell deployment script for building and pushing Docker images to ECR
# MUST be run from the deploy/ folder
# Usage: cd deploy && .\scripts\deploy-image.ps1 -Environment <env> [-ImageTag <tag>]
# Example: cd deploy && .\scripts\deploy-image.ps1 -Environment qa
# Example: cd deploy && .\scripts\deploy-image.ps1 -Environment prd -ImageTag v1.2.3

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev','qa','uat','stg','prd')]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [string]$ImageTag
)

# Set default image tag if not provided
if ([string]::IsNullOrEmpty($ImageTag)) {
    $ImageTag = "$Environment-latest"
}

# Function to print colored messages
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

Write-Info "Environment: $Environment"
Write-Info "Image Tag: $ImageTag"

# Get the deploy folder (one level up from scripts folder)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DeployDir = Split-Path -Parent $ScriptDir
$ProjectRoot = Split-Path -Parent $DeployDir

$BranchName = "unknown"
$Sequence = "0"

try {
    $BranchName = (git rev-parse --abbrev-ref HEAD).Trim()
} catch {
    $BranchName = "unknown"
}

try {
    $Sequence = (git rev-list --count HEAD).Trim()
} catch {
    $Sequence = "0"
}

$BranchName = $BranchName -replace '/', '-'
$BranchTag = "$BranchName-$Sequence"

Write-Info "Branch Tag: $BranchTag"

# Validate deploy folder structure exists
if (-not (Test-Path "$DeployDir\terraform")) {
    Write-Error-Custom "Expected deploy/terraform folder not found"
    Write-Error-Custom "Please run from deploy folder: cd deploy && .\scripts\deploy-image.ps1 -Environment $Environment"
    exit 1
}

# Read terraform variables
$TerraformDir = "$DeployDir\terraform"
$TfvarsFile = "$TerraformDir\terraform-$Environment.tfvars"

if (-not (Test-Path $TfvarsFile)) {
    Write-Error-Custom "Terraform variables file not found: $TfvarsFile"
    exit 1
}

# Extract ECR repository URL and AWS region
$EcrRepo = (Select-String -Path $TfvarsFile -Pattern 'ecr_repository_url\s*=\s*"([^"]+)"').Matches.Groups[1].Value
$AwsRegion = (Select-String -Path $TfvarsFile -Pattern 'aws_region\s*=\s*"([^"]+)"').Matches.Groups[1].Value

if ([string]::IsNullOrEmpty($EcrRepo) -or [string]::IsNullOrEmpty($AwsRegion)) {
    Write-Error-Custom "Could not extract ECR repository URL or AWS region from $TfvarsFile"
    exit 1
}

Write-Info "ECR Repository: $EcrRepo"
Write-Info "AWS Region: $AwsRegion"

# Change to project root for build/docker operations
Set-Location $ProjectRoot

# Build client assets locally first
Write-Info "Building client assets locally..."
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Local asset build failed"
    exit 1
}
Write-Info "Client assets built successfully"

# Build Docker image
Write-Info "Building Docker image..."
docker build --no-cache -t "xinvestment:$ImageTag" .

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Docker build failed"
    exit 1
}

Write-Info "Docker image built successfully"

# Tag image for ECR
Write-Info "Tagging image for ECR..."
docker tag "xinvestment:$ImageTag" "${EcrRepo}:$ImageTag"
docker tag "xinvestment:$ImageTag" "${EcrRepo}:$BranchTag"

# Login to ECR
Write-Info "Logging in to ECR..."
$EcrRegistry = $EcrRepo.Split('/')[0]
aws ecr get-login-password --region $AwsRegion | docker login --username AWS --password-stdin $EcrRegistry

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "ECR login failed"
    exit 1
}

# Push image to ECR
Write-Info "Pushing image to ECR..."
docker push "${EcrRepo}:$ImageTag"
docker push "${EcrRepo}:$BranchTag"

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Docker push failed"
    exit 1
}

Write-Info "Image pushed successfully!"
Write-Info "Image: ${EcrRepo}:$ImageTag"
Write-Info "Image: ${EcrRepo}:$BranchTag"

# Update reminder
if ($ImageTag -eq "$Environment-latest") {
    Write-Warn-Custom "Remember to update the image_tag in $TfvarsFile if needed"
    $CurrentTag = (Select-String -Path $TfvarsFile -Pattern 'image_tag\s*=\s*"([^"]+)"').Matches.Groups[1].Value
    Write-Warn-Custom "Current value: $CurrentTag"
}

Write-Info "Deployment complete!"
Write-Host ""
Write-Info "Next steps:"
Write-Host "  1. cd deploy\terraform"
Write-Host "  2. terraform plan -var-file=terraform-$Environment.tfvars"
Write-Host "  3. terraform apply -var-file=terraform-$Environment.tfvars"
