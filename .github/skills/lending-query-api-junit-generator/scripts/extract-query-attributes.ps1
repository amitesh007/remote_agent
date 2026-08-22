# PowerShell script to extract query (GetByID) attributes from a requirement spreadsheet
# Usage: .\extract-query-attributes.ps1 -ExcelFilePath "<path>" -SheetName "GetByID"

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$ExcelFilePath,

    [Parameter(Mandatory=$false, Position=1)]
    [string]$SheetName = "GetByID"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ExcelFilePath)) {
    Write-Error "Error: Excel file not found at '$ExcelFilePath'"
    exit 1
}

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  LoanIQ Query API — Attribute Extractor (Primary)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "File: $ExcelFilePath" -ForegroundColor Green
Write-Host "Sheet: $SheetName" -ForegroundColor Green
Write-Host ""

try {
    # Try using ImportExcel module first
    if (Get-Module -ListAvailable -Name ImportExcel) {
        Import-Module ImportExcel
        
        $data = Import-Excel -Path $ExcelFilePath -WorksheetName $SheetName -ErrorAction Stop
        
        Write-Host "Successfully loaded $($data.Count) rows from sheet '$SheetName'" -ForegroundColor Green
        Write-Host ""
        
        # Extract INPUT attributes
        Write-Host "══════ INPUT ATTRIBUTES ══════" -ForegroundColor Yellow
        $inputSection = $false
        $outputSection = $false
        
        foreach ($row in $data) {
            $props = $row.PSObject.Properties
            $firstCol = ($props | Select-Object -First 1).Value
            
            if ($firstCol -match "(?i)input|request") {
                $inputSection = $true
                $outputSection = $false
                continue
            }
            if ($firstCol -match "(?i)output|response") {
                $inputSection = $false
                $outputSection = $true
                Write-Host ""
                Write-Host "══════ OUTPUT ATTRIBUTES ══════" -ForegroundColor Yellow
                continue
            }
            
            if ($inputSection -or $outputSection) {
                $attributeName = ($props | Where-Object { $_.Name -match "(?i)attribute|field|name" } | Select-Object -First 1).Value
                $dataType = ($props | Where-Object { $_.Name -match "(?i)type|datatype" } | Select-Object -First 1).Value
                $required = ($props | Where-Object { $_.Name -match "(?i)required|mandatory" } | Select-Object -First 1).Value
                $description = ($props | Where-Object { $_.Name -match "(?i)description|desc" } | Select-Object -First 1).Value
                
                if ($attributeName) {
                    $reqFlag = if ($required -match "(?i)y|yes|true|mandatory") { "MANDATORY" } else { "OPTIONAL" }
                    $mappingType = if ($dataType -match "(?i)list|collection|array") { "NON_PRIMITIVE_COLLECTION" }
                                   elseif ($dataType -match "(?i)object|identifier|details") { "NON_PRIMITIVE" }
                                   else { "PRIMITIVE" }
                    
                    Write-Host "  [$reqFlag][$mappingType] $attributeName ($dataType) — $description" -ForegroundColor White
                }
            }
        }
    }
    else {
        # Fallback: Use COM object (Windows only)
        Write-Host "ImportExcel module not found. Using COM automation..." -ForegroundColor Yellow
        
        $excel = New-Object -ComObject Excel.Application
        $excel.Visible = $false
        $excel.DisplayAlerts = $false
        
        try {
            $workbook = $excel.Workbooks.Open($ExcelFilePath)
            $sheet = $workbook.Sheets | Where-Object { $_.Name -eq $SheetName }
            
            if (-not $sheet) {
                # Try partial match
                $sheet = $workbook.Sheets | Where-Object { $_.Name -match $SheetName } | Select-Object -First 1
            }
            
            if (-not $sheet) {
                Write-Error "Sheet '$SheetName' not found. Available sheets: $($workbook.Sheets | ForEach-Object { $_.Name })"
                exit 1
            }
            
            $usedRange = $sheet.UsedRange
            $rowCount = $usedRange.Rows.Count
            $colCount = $usedRange.Columns.Count
            
            Write-Host "Sheet has $rowCount rows and $colCount columns" -ForegroundColor Green
            Write-Host ""
            
            for ($row = 1; $row -le $rowCount; $row++) {
                $line = ""
                for ($col = 1; $col -le [Math]::Min($colCount, 10); $col++) {
                    $cellValue = $sheet.Cells.Item($row, $col).Text
                    if ($cellValue) {
                        $line += "$cellValue`t"
                    }
                }
                if ($line.Trim()) {
                    Write-Host $line
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
}
catch {
    Write-Error "Failed to extract attributes: $_"
    Write-Host ""
    Write-Host "Try using the fallback script: extract-query-attributes-fallback.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Extraction complete!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
