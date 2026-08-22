# PowerShell script — Fallback attribute extractor for non-standard spreadsheet formats
# Usage: .\extract-query-attributes-fallback.ps1 -ExcelFilePath "<path>"

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$ExcelFilePath
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ExcelFilePath)) {
    Write-Error "Error: Excel file not found at '$ExcelFilePath'"
    exit 1
}

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  LoanIQ Query API — Attribute Extractor (Fallback)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "File: $ExcelFilePath" -ForegroundColor Green
Write-Host ""

# Try multiple sheet name patterns for GetByID
$sheetNamePatterns = @("GetByID", "GetbyId", "GetById", "Get", "Query", "GET", "Read", "Retrieve")

try {
    # Method 1: Use IntegrationAPITool JAR to extract
    $repoRoot = Split-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) -Parent
    $jarFile = Join-Path $repoRoot "IntegrationAPITool\artifacts\executable\IntegrationAPITool-1.0-exec.jar"
    
    if (Test-Path $jarFile) {
        Write-Host "Using IntegrationAPITool JAR for extraction..." -ForegroundColor Yellow
        $integrationApiToolDir = Join-Path $repoRoot "IntegrationAPITool"
        $currentDir = Get-Location
        
        try {
            Set-Location $integrationApiToolDir
            $output = java -jar "$jarFile" "$ExcelFilePath" 2>&1
            Write-Host $output
        }
        finally {
            Set-Location $currentDir
        }
        
        # Check if temp_generated_class has output
        $tempDir = Join-Path $integrationApiToolDir "artifacts\temp_generated_class"
        if (Test-Path $tempDir) {
            $generatedFiles = Get-ChildItem -Path $tempDir -Filter "*.java" -Recurse
            if ($generatedFiles) {
                Write-Host ""
                Write-Host "Generated files found:" -ForegroundColor Green
                $generatedFiles | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
            }
        }
    }
    else {
        Write-Host "IntegrationAPITool JAR not found at: $jarFile" -ForegroundColor Yellow
    }
    
    # Method 2: Try COM Object with multiple sheet names
    Write-Host ""
    Write-Host "Attempting COM-based extraction with sheet name discovery..." -ForegroundColor Yellow
    
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
    
    try {
        $workbook = $excel.Workbooks.Open($ExcelFilePath)
        
        Write-Host "Available sheets:" -ForegroundColor Green
        $workbook.Sheets | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor White }
        Write-Host ""
        
        $targetSheet = $null
        foreach ($pattern in $sheetNamePatterns) {
            $targetSheet = $workbook.Sheets | Where-Object { $_.Name -match $pattern } | Select-Object -First 1
            if ($targetSheet) {
                Write-Host "Matched sheet: '$($targetSheet.Name)' using pattern '$pattern'" -ForegroundColor Green
                break
            }
        }
        
        if (-not $targetSheet) {
            Write-Host "No matching sheet found. Dumping first sheet..." -ForegroundColor Yellow
            $targetSheet = $workbook.Sheets.Item(1)
        }
        
        $usedRange = $targetSheet.UsedRange
        $rowCount = $usedRange.Rows.Count
        $colCount = $usedRange.Columns.Count
        
        Write-Host "Sheet '$($targetSheet.Name)' has $rowCount rows, $colCount columns" -ForegroundColor Green
        Write-Host ""
        
        # Scan for attribute-like columns
        $headerRow = 1
        $attributeCol = -1
        $typeCol = -1
        $requiredCol = -1
        $descCol = -1
        
        for ($col = 1; $col -le $colCount; $col++) {
            $headerValue = $targetSheet.Cells.Item($headerRow, $col).Text.ToLower()
            if ($headerValue -match "attribute|field|name|parameter") { $attributeCol = $col }
            if ($headerValue -match "type|datatype|data type") { $typeCol = $col }
            if ($headerValue -match "required|mandatory|req") { $requiredCol = $col }
            if ($headerValue -match "description|desc|comment") { $descCol = $col }
        }
        
        if ($attributeCol -gt 0) {
            Write-Host "══════ EXTRACTED ATTRIBUTES ══════" -ForegroundColor Yellow
            
            for ($row = 2; $row -le $rowCount; $row++) {
                $attrName = $targetSheet.Cells.Item($row, $attributeCol).Text
                $attrType = if ($typeCol -gt 0) { $targetSheet.Cells.Item($row, $typeCol).Text } else { "Unknown" }
                $attrReq = if ($requiredCol -gt 0) { $targetSheet.Cells.Item($row, $requiredCol).Text } else { "" }
                $attrDesc = if ($descCol -gt 0) { $targetSheet.Cells.Item($row, $descCol).Text } else { "" }
                
                if ($attrName) {
                    $reqFlag = if ($attrReq -match "(?i)y|yes|true|mandatory") { "MANDATORY" } else { "OPTIONAL" }
                    $mappingType = if ($attrType -match "(?i)list|collection|array") { "NON_PRIMITIVE_COLLECTION" }
                                   elseif ($attrType -match "(?i)object|identifier|details") { "NON_PRIMITIVE" }
                                   else { "PRIMITIVE" }
                    
                    Write-Host "  [$reqFlag][$mappingType] $attrName ($attrType) — $attrDesc" -ForegroundColor White
                }
            }
        }
        else {
            # Raw dump if no recognized structure
            Write-Host "No recognized column headers. Raw dump:" -ForegroundColor Yellow
            for ($row = 1; $row -le [Math]::Min($rowCount, 50); $row++) {
                $line = ""
                for ($col = 1; $col -le [Math]::Min($colCount, 8); $col++) {
                    $cellValue = $targetSheet.Cells.Item($row, $col).Text
                    if ($cellValue) { $line += "$cellValue | " }
                }
                if ($line.Trim()) { Write-Host "  Row $row`: $line" }
            }
        }
    }
    finally {
        if ($workbook) { $workbook.Close($false) }
        if ($excel) {
            $excel.Quit()
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
        }
    }
}
catch {
    Write-Error "Fallback extraction failed: $_"
    Write-Host ""
    Write-Host "Try using the raw reader script: read-spreadsheet-raw.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Fallback extraction complete!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
