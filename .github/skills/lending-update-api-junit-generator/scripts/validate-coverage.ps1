# PowerShell script to validate that all spreadsheet attributes have test coverage
# in the generated test class.
#
# Usage: .\validate-coverage.ps1 -AttributesFile "attributes.json" -TestClassFile "path/to/TestClass.java"
# Example: .\validate-coverage.ps1 -AttributesFile "attributes.json" -TestClassFile "LoanIQ/test/com/misys/liq/api/rest/executable/upfrontfee/LiqAPIUpdateUpfrontFeeIntegrationTest.java"
#
# Output: Coverage report to console + coverage-report.json

param(
    [Parameter(Mandatory=$true)]
    [string]$AttributesFile,

    [Parameter(Mandatory=$true)]
    [string]$TestClassFile
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $AttributesFile)) {
    Write-Error "Error: Attributes file not found at '$AttributesFile'"
    exit 1
}

if (-not (Test-Path $TestClassFile)) {
    Write-Error "Error: Test class file not found at '$TestClassFile'"
    exit 1
}

# Load attributes
$attributeData = Get-Content $AttributesFile -Raw | ConvertFrom-Json
$testContent = Get-Content $TestClassFile -Raw

Write-Host "=== Update Test Coverage Validation ===" -ForegroundColor Cyan
Write-Host "Business Object: $($attributeData.businessObject)" -ForegroundColor Green
Write-Host "Total Attributes: $($attributeData.attributes.Count)" -ForegroundColor Green
Write-Host ""

$coveredAttributes = @()
$uncoveredAttributes = @()
$mandatoryMissing = @()
$optionalMissing = @()

foreach ($attr in $attributeData.attributes) {
    $fieldName = $attr.name
    $fieldNamePascal = $fieldName.Substring(0,1).ToUpper() + $fieldName.Substring(1)

    # Check if any test method references this field
    $isCovered = $false

    # Check various patterns
    $patterns = @(
        "test.*${fieldNamePascal}",
        "set${fieldNamePascal}\(",
        "get${fieldNamePascal}\(",
        "\.${fieldName}\s*=",
        "\.${fieldName}\(",
        """${fieldName}"""
    )

    foreach ($pattern in $patterns) {
        if ($testContent -match $pattern) {
            $isCovered = $true
            break
        }
    }

    if ($isCovered) {
        $coveredAttributes += $attr
    }
    else {
        $uncoveredAttributes += $attr
        if ($attr.required -eq $true) {
            $mandatoryMissing += $attr
        }
        else {
            $optionalMissing += $attr
        }
    }
}

# Check for standard test categories
$standardChecks = @{
    "Identifier Validation" = "testUpdateWithout.*Identifier|testUpdateWithNonExistent"
    "If-Match Timestamp" = "testUpdateWithoutIfMatch|testUpdateWithStaleIfMatch|testUpdateWithCurrentIfMatch"
    "Class Mapping - nonPrimitiveFieldMappings" = "testNonPrimitiveFieldMappings"
    "Class Mapping - primitiveFieldMappings" = "testPrimitiveFieldMappings"
    "Class Mapping - securityAccessSymbol" = "testSecurityAccessSymbol"
    "Class Mapping - isRest" = "testIsRest"
    "Class Mapping - basicNew" = "testBasicNew"
    "Class Mapping - getJavaClass" = "testGetJavaClass"
    "Class Mapping - getStSuperclass" = "testGetStSuperclass|testGetStClass"
}

$missingStandard = @()
foreach ($check in $standardChecks.GetEnumerator()) {
    if ($testContent -notmatch $check.Value) {
        $missingStandard += $check.Key
    }
}

# Report
Write-Host "─── Coverage Summary ───────────────────────────────────────" -ForegroundColor Cyan
$coveragePercent = if ($attributeData.attributes.Count -gt 0) {
    [Math]::Round(($coveredAttributes.Count / $attributeData.attributes.Count) * 100, 1)
} else { 0 }

Write-Host "Attribute Coverage: $($coveredAttributes.Count)/$($attributeData.attributes.Count) ($coveragePercent%)" -ForegroundColor $(if ($coveragePercent -ge 90) { "Green" } elseif ($coveragePercent -ge 70) { "Yellow" } else { "Red" })
Write-Host ""

if ($mandatoryMissing.Count -gt 0) {
    Write-Host "⚠️  MANDATORY attributes WITHOUT test coverage:" -ForegroundColor Red
    foreach ($m in $mandatoryMissing) {
        Write-Host "  ✗ $($m.name) [$($m.type)] - REQUIRED" -ForegroundColor Red
    }
    Write-Host ""
}

if ($optionalMissing.Count -gt 0) {
    Write-Host "⚠️  Optional attributes WITHOUT test coverage:" -ForegroundColor Yellow
    foreach ($m in $optionalMissing) {
        Write-Host "  ○ $($m.name) [$($m.type)]" -ForegroundColor Yellow
    }
    Write-Host ""
}

if ($missingStandard.Count -gt 0) {
    Write-Host "⚠️  Missing standard test categories:" -ForegroundColor Yellow
    foreach ($s in $missingStandard) {
        Write-Host "  ○ $s" -ForegroundColor Yellow
    }
    Write-Host ""
}

if ($uncoveredAttributes.Count -eq 0 -and $missingStandard.Count -eq 0) {
    Write-Host "✅ FULL COVERAGE — All attributes and standard tests are present!" -ForegroundColor Green
}

# Write report JSON
$report = @{
    businessObject = $attributeData.businessObject
    totalAttributes = $attributeData.attributes.Count
    coveredCount = $coveredAttributes.Count
    uncoveredCount = $uncoveredAttributes.Count
    coveragePercent = $coveragePercent
    mandatoryMissing = $mandatoryMissing | ForEach-Object { $_.name }
    optionalMissing = $optionalMissing | ForEach-Object { $_.name }
    missingStandardTests = $missingStandard
    status = if ($coveragePercent -ge 95 -and $mandatoryMissing.Count -eq 0) { "PASS" } else { "NEEDS_WORK" }
}

$reportPath = Join-Path (Get-Location) "coverage-report.json"
$report | ConvertTo-Json -Depth 3 | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host ""
Write-Host "Coverage report written to: $reportPath" -ForegroundColor Cyan

# Exit with non-zero if mandatory attributes are missing
if ($mandatoryMissing.Count -gt 0) {
    Write-Host ""
    Write-Host "RESULT: FAIL — Mandatory attributes missing coverage" -ForegroundColor Red
    exit 1
}
elseif ($coveragePercent -lt 90) {
    Write-Host ""
    Write-Host "RESULT: WARNING — Coverage below 90%" -ForegroundColor Yellow
    exit 0
}
else {
    Write-Host ""
    Write-Host "RESULT: PASS" -ForegroundColor Green
    exit 0
}
