# PowerShell script to run the application with Docker
# Usage: .\docker-run.ps1 [command]
# Commands: up, down, build, logs, restart

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('up','down','build','logs','restart','ps','clean')]
    [string]$Command = 'up'
)

$ProjectName = "xinvestment"

Write-Host "Docker Management for $ProjectName" -ForegroundColor Cyan
Write-Host "Command: $Command" -ForegroundColor Yellow
Write-Host ""

switch ($Command) {
    'up' {
        Write-Host "Starting application with Docker Compose..." -ForegroundColor Green
        docker-compose up --build
    }
    'down' {
        Write-Host "Stopping application..." -ForegroundColor Yellow
        docker-compose down
    }
    'build' {
        Write-Host "Building Docker image..." -ForegroundColor Green
        docker-compose build
    }
    'logs' {
        Write-Host "Showing logs (Ctrl+C to exit)..." -ForegroundColor Green
        docker-compose logs -f app
    }
    'restart' {
        Write-Host "Restarting application..." -ForegroundColor Yellow
        docker-compose restart app
    }
    'ps' {
        Write-Host "Container status:" -ForegroundColor Green
        docker-compose ps
    }
    'clean' {
        Write-Host "Cleaning up containers and volumes..." -ForegroundColor Red
        docker-compose down -v
        Write-Host "Cleanup complete!" -ForegroundColor Green
    }
}

if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
    Write-Host ""
    Write-Host "Error occurred. Exit code: $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}
