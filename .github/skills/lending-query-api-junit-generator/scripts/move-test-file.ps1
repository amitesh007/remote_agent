# PowerShell script to move generated test file from temp folder to FLIQ-liqjava repo
# Usage: .\move-test-file.ps1 -BusinessObject "Deal" -Domain "deal"

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$BusinessObject,

    [Parameter(Mandatory=$false, Position=1)]
    [string]$Domain = "",

    [Parameter(Mandatory=$false)]
    [string]$RepoRoot = "C:\Users\asrivas3\git\7740_3\FLIQ-liqjava"
)

$ErrorActionPreference = "Stop"

if (-not $Domain) {
    $Domain = $BusinessObject.ToLower()
}

$testClassName = "LiqAPIQuery${BusinessObject}IntegrationTest.java"
$tempDir = Join-Path $RepoRoot "IntegrationAPITool\artifacts\temp_generated_class"
$targetDir = Join-Path $RepoRoot "LoanIQ\test\com\misys\liq\api\rest\executable\$Domain"

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Move Test File: $testClassName" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Source Dir: $tempDir" -ForegroundColor Green
Write-Host "Target Dir: $targetDir" -ForegroundColor Green
Write-Host ""

# Find the file in temp directory
$sourceFile = Get-ChildItem -Path $tempDir -Filter $testClassName -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $sourceFile) {
    Write-Host "File '$testClassName' not found in temp directory." -ForegroundColor Yellow
    Write-Host "Checking target directory..." -ForegroundColor Yellow
    
    $targetFile = Join-Path $targetDir $testClassName
    if (Test-Path $targetFile) {
        Write-Host "File already exists at target: $targetFile" -ForegroundColor Green
    }
    else {
        Write-Host "File not found in either location. Will need to create new." -ForegroundColor Yellow
    }
    exit 0
}

# Create target directory if it doesn't exist
if (-not (Test-Path $targetDir)) {
    Write-Host "Creating target directory: $targetDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

# Check if target already exists
$targetFile = Join-Path $targetDir $testClassName
if (Test-Path $targetFile) {
    Write-Host "Target file already exists. Creating backup..." -ForegroundColor Yellow
    $backupFile = Join-Path $targetDir "$testClassName.bak"
    Copy-Item -Path $targetFile -Destination $backupFile -Force
    Write-Host "Backup created: $backupFile" -ForegroundColor DarkGray
}

# Move the file
Write-Host "Moving: $($sourceFile.FullName)" -ForegroundColor White
Write-Host "    To: $targetFile" -ForegroundColor White
Copy-Item -Path $sourceFile.FullName -Destination $targetFile -Force

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  File moved successfully!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
