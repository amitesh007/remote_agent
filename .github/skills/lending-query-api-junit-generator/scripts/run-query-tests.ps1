# PowerShell script to run query integration tests
# Usage: .\run-query-tests.ps1 -TestClass "LiqAPIQueryDealIntegrationTest"

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$TestClass,

    [Parameter(Mandatory=$false)]
    [string]$DbConfig = "C:/Server7651_226/dbconfig_junit_135.ini",

    [Parameter(Mandatory=$false)]
    [string]$RepoRoot = "C:\Users\asrivas3\git\7740_3\FLIQ-liqjava"
)

$ErrorActionPreference = "Stop"

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  LoanIQ Query Test Runner" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Test Class: $TestClass" -ForegroundColor Green
Write-Host "DB Config: $DbConfig" -ForegroundColor Green
Write-Host ""

$loanIQDir = Join-Path $RepoRoot "LoanIQ"
$jsqlOverride = Join-Path $RepoRoot "keyvault\src\main\resources\inprocJSQLOverride.xml"
$ls2Override = Join-Path $RepoRoot "keyvault\src\main\resources\inprocLS2APPOverride.xml"

if (-not (Test-Path $loanIQDir)) {
    Write-Error "LoanIQ directory not found at: $loanIQDir"
    exit 1
}

$currentDir = Get-Location

try {
    Set-Location $loanIQDir
    
    Write-Host "Running test: $TestClass" -ForegroundColor Yellow
    Write-Host ""
    
    # Run using Ant JUnit task
    $antArgs = @(
        "unittest",
        "-Ddbconfig=$DbConfig",
        "-Djsql=$jsqlOverride",
        "-Dls2=$ls2Override",
        "-Dtestclass=$TestClass"
    )
    
    Write-Host "Command: ant $($antArgs -join ' ')" -ForegroundColor DarkGray
    Write-Host ""
    
    & ant @antArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host "  TEST FAILED (exit code: $LASTEXITCODE)" -ForegroundColor Red
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Red
        exit $LASTEXITCODE
    }
    else {
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
        Write-Host "  ALL TESTS PASSED!" -ForegroundColor Green
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
    }
}
finally {
    Set-Location $currentDir
}
