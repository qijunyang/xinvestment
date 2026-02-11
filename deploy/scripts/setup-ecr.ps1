# PowerShell script to create ECR repository
# This only needs to be run once
# Usage: .\setup-ecr.ps1 [-Region <region>]

param(
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1"
)

$RepositoryName = "xinvestment"

Write-Host "Creating ECR repository..." -ForegroundColor Green
Write-Host "Repository: $RepositoryName" -ForegroundColor Cyan
Write-Host "Region: $Region" -ForegroundColor Cyan
Write-Host ""

# Create ECR repository
aws ecr create-repository `
    --repository-name $RepositoryName `
    --image-scanning-configuration scanOnPush=true `
    --encryption-configuration encryptionType=AES256 `
    --region $Region

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ ECR repository created successfully" -ForegroundColor Green
    
    # Get repository URI
    $RepoUri = (aws ecr describe-repositories `
        --repository-names $RepositoryName `
        --region $Region `
        --query 'repositories[0].repositoryUri' `
        --output text)
    
    Write-Host ""
    Write-Host "Repository URI: $RepoUri" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Update your terraform-*.tfvars files with:" -ForegroundColor Yellow
    Write-Host "  ecr_repository_url = `"$RepoUri`"" -ForegroundColor White
    
    # Set lifecycle policy to keep only last 10 images
    Write-Host ""
    Write-Host "Setting lifecycle policy (keep last 10 images)..." -ForegroundColor Yellow
    
    $LifecyclePolicy = @'
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 10 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
'@
    
    $LifecyclePolicy | aws ecr put-lifecycle-policy `
        --repository-name $RepositoryName `
        --lifecycle-policy-text file:///dev/stdin `
        --region $Region
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Lifecycle policy set" -ForegroundColor Green
    }
    
} else {
    Write-Host "✗ Failed to create ECR repository (it may already exist)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To get existing repository URI:" -ForegroundColor Cyan
    Write-Host "  aws ecr describe-repositories --repository-names $RepositoryName --region $Region" -ForegroundColor White
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Update terraform-*.tfvars with the repository URI"
Write-Host "  2. Run .\deploy-image.ps1 -Environment dev to build and push the first image"
