# PowerShell script — Raw spreadsheet reader (last resort)
# Dumps all content from the spreadsheet for manual inspection
# Usage: .\read-spreadsheet-raw.ps1 -ExcelFilePath "<path>"

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
Write-Host "  LoanIQ Query API — Raw Spreadsheet Reader" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "File: $ExcelFilePath" -ForegroundColor Green
Write-Host ""

try {
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
    
    try {
        $workbook = $excel.Workbooks.Open($ExcelFilePath)
        
        Write-Host "Workbook has $($workbook.Sheets.Count) sheets:" -ForegroundColor Green
        $sheetIndex = 1
        $workbook.Sheets | ForEach-Object { 
            Write-Host "  [$sheetIndex] $($_.Name)" -ForegroundColor White
            $sheetIndex++
        }
        Write-Host ""
        
        # Dump each sheet
        foreach ($sheet in $workbook.Sheets) {
            $sheetName = $sheet.Name
            
            # Skip sheets unlikely to have GetByID data
            if ($sheetName -match "(?i)create|update|delete|template|config|readme") {
                Write-Host "Skipping sheet: $sheetName" -ForegroundColor DarkGray
                continue
            }
            
            Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Yellow
            Write-Host "  SHEET: $sheetName" -ForegroundColor Yellow
            Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Yellow
            
            $usedRange = $sheet.UsedRange
            $rowCount = $usedRange.Rows.Count
            $colCount = $usedRange.Columns.Count
            
            Write-Host "  Dimensions: $rowCount rows x $colCount columns" -ForegroundColor Green
            Write-Host ""
            
            # Dump all rows (up to 200)
            $maxRows = [Math]::Min($rowCount, 200)
            $maxCols = [Math]::Min($colCount, 12)
            
            for ($row = 1; $row -le $maxRows; $row++) {
                $line = ""
                $hasContent = $false
                for ($col = 1; $col -le $maxCols; $col++) {
                    $cellValue = $sheet.Cells.Item($row, $col).Text
                    if ($cellValue) { 
                        $hasContent = $true
                        $truncated = if ($cellValue.Length -gt 40) { $cellValue.Substring(0, 40) + "..." } else { $cellValue }
                        $line += "$truncated | "
                    }
                    else {
                        $line += " | "
                    }
                }
                if ($hasContent) {
                    Write-Host "  R$($row.ToString().PadLeft(3,'0')): $line"
                }
            }
            
            if ($rowCount -gt $maxRows) {
                Write-Host "  ... ($($rowCount - $maxRows) more rows truncated)" -ForegroundColor DarkGray
            }
            Write-Host ""
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
    Write-Error "Raw read failed: $_"
    Write-Host ""
    Write-Host "Ensure Microsoft Excel is installed or use ImportExcel PowerShell module." -ForegroundColor Yellow
    Write-Host "Install: Install-Module ImportExcel -Scope CurrentUser" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Raw read complete!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
