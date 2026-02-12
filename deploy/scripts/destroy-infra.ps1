# PowerShell infrastructure destroy pipeline script
# MUST be run from the deploy/ folder
# Usage: cd deploy && .\scripts\destroy-infra.ps1 -Environment <env>
# Example: cd deploy && .\scripts\destroy-infra.ps1 -Environment dev

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

function Remove-S3BucketVersions {
    param([string]$BucketName)

    $response = aws s3api list-object-versions --bucket $BucketName | ConvertFrom-Json
    $items = @()

    if ($response.Versions) {
        $items += $response.Versions
    }
    if ($response.DeleteMarkers) {
        $items += $response.DeleteMarkers
    }

    if ($items.Count -eq 0) {
        Write-Info "Bucket already empty."
        return
    }

    $chunkSize = 1000
    $index = 0
    while ($index -lt $items.Count) {
        $chunk = $items[$index..([Math]::Min($index + $chunkSize - 1, $items.Count - 1))]
        $payload = @{
            Objects = $chunk | ForEach-Object { @{ Key = $_.Key; VersionId = $_.VersionId } }
            Quiet   = $true
        } | ConvertTo-Json -Depth 4

        $tempFile = [System.IO.Path]::GetTempFileName()
        $payload | Out-File -Encoding ascii $tempFile
        aws s3api delete-objects --bucket $BucketName --delete "file://$tempFile" | Out-Null
        Remove-Item $tempFile -ErrorAction SilentlyContinue

        $index += $chunkSize
    }

    Write-Info "Deleted $($items.Count) object versions/delete markers from $BucketName"
}

# Get the deploy folder (one level up from scripts folder)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DeployDir = Split-Path -Parent $ScriptDir

# Validate paths
if (-not (Test-Path "$DeployDir\terraform")) {
    Write-Error-Custom "Terraform directory not found. Please run from deploy folder: cd deploy && .\scripts\destroy-infra.ps1 -Environment $Environment"
    exit 1
}

$TerraformDir = "$DeployDir\terraform"
$BackendConfig = "$TerraformDir\backend-$Environment.hcl"
$VarFile = "$TerraformDir\terraform-$Environment.tfvars"

Write-Info "Destroy infra pipeline starting for environment: $Environment"
Write-Host ""

if (-not (Test-Path $BackendConfig)) {
    Write-Error-Custom "Backend config not found: $BackendConfig"
    exit 1
}
if (-not (Test-Path $VarFile)) {
    Write-Error-Custom "Var file not found: $VarFile"
    exit 1
}

Set-Location $TerraformDir

# Ensure state is available
terraform init -reconfigure "-backend-config=$BackendConfig"
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Terraform init failed"
    exit $LASTEXITCODE
}

# Empty static assets bucket (if it exists) to avoid destroy errors
Write-Info "Checking static assets bucket..."
$BucketName = (terraform output -raw s3_static_assets_bucket 2>$null)

if ([string]::IsNullOrEmpty($BucketName)) {
    Write-Warn-Custom "S3 bucket output not found (skipping empty step)"
} else {
    Write-Info "Emptying S3 bucket: $BucketName"
    Remove-S3BucketVersions -BucketName $BucketName
}

# Destroy Terraform-managed resources
Write-Info "Destroying Terraform-managed resources..."
terraform destroy "-var-file=$VarFile"
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Terraform destroy failed"
    exit $LASTEXITCODE
}

Write-Host ""
Write-Info "Destroy infra pipeline complete!"
Write-Host ""
Write-Warn-Custom "Note: ECR repository and Terraform state bucket are NOT deleted."