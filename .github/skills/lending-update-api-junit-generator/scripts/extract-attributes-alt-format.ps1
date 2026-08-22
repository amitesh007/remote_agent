# PowerShell script to extract attributes from alternative spreadsheet layouts
# This handles spreadsheets where the Update sheet has a different naming convention
# or the columns are organized differently.
#
# Usage: .\extract-attributes-alt-format.ps1 "<SpreadsheetPath>"
# Example: .\extract-attributes-alt-format.ps1 "C:\Auto\API\Facility v9.xlsx"
#
# Output: attributes.json in the current directory

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$ExcelFilePath
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ExcelFilePath)) {
    Write-Error "Error: Excel file not found at '$ExcelFilePath'"
    exit 1
}

try {
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false

    $workbook = $excel.Workbooks.Open($ExcelFilePath)

    # Search through all sheets for Update-related content
    $updateSheet = $null
    $sheetPriority = @("Update", "UPDATE", "Modify", "PATCH", "PUT", "UpdateAdditionalFieldDetail", "UpdateDetail")

    foreach ($priority in $sheetPriority) {
        foreach ($ws in $workbook.Worksheets) {
            if ($ws.Name -eq $priority -or $ws.Name -like "*$priority*") {
                $updateSheet = $ws
                break
            }
        }
        if ($null -ne $updateSheet) { break }
    }

    if ($null -eq $updateSheet) {
        # Last resort: scan all sheets for one containing "Update" in cell content
        foreach ($ws in $workbook.Worksheets) {
            $cellA1 = $ws.Cells.Item(1, 1).Text
            $cellA2 = $ws.Cells.Item(2, 1).Text
            if ($cellA1 -like "*Update*" -or $cellA2 -like "*Update*") {
                $updateSheet = $ws
                break
            }
        }
    }

    if ($null -eq $updateSheet) {
        Write-Error "Error: Could not find any Update-related sheet in '$ExcelFilePath'"
        Write-Host "Available sheets:" -ForegroundColor Yellow
        foreach ($ws in $workbook.Worksheets) {
            Write-Host "  - $($ws.Name)" -ForegroundColor Yellow
        }
        $workbook.Close($false)
        $excel.Quit()
        exit 1
    }

    Write-Host "Processing sheet: $($updateSheet.Name)" -ForegroundColor Green

    # Try multiple header detection strategies
    $attributes = @()
    $lastRow = $updateSheet.UsedRange.Rows.Count
    $lastCol = $updateSheet.UsedRange.Columns.Count

    # Strategy 1: Look for a row with "Attribute Name" or "Field Name" pattern
    $headerRow = -1
    for ($row = 1; $row -le [Math]::Min(20, $lastRow); $row++) {
        for ($col = 1; $col -le $lastCol; $col++) {
            $cell = $updateSheet.Cells.Item($row, $col).Text.Trim()
            if ($cell -eq "Attribute Name" -or $cell -eq "ATTRIBUTE_NAME" -or
                $cell -eq "Field Name" -or $cell -eq "FIELD_NAME" -or
                $cell -eq "Attribute" -or $cell -eq "attribute_name") {
                $headerRow = $row
                break
            }
        }
        if ($headerRow -gt 0) { break }
    }

    # Strategy 2: If no header found, try first row with multiple non-empty cells
    if ($headerRow -lt 0) {
        for ($row = 1; $row -le [Math]::Min(10, $lastRow); $row++) {
            $nonEmptyCount = 0
            for ($col = 1; $col -le $lastCol; $col++) {
                if (-not [string]::IsNullOrWhiteSpace($updateSheet.Cells.Item($row, $col).Text)) {
                    $nonEmptyCount++
                }
            }
            if ($nonEmptyCount -ge 4) {
                $headerRow = $row
                break
            }
        }
    }

    if ($headerRow -lt 0) { $headerRow = 1 }

    Write-Host "Using header row: $headerRow" -ForegroundColor Cyan

    # Map columns by scanning headers
    $colName = -1; $colType = -1; $colRequired = -1; $colUpdatable = -1
    $colCodeTable = -1; $colDescription = -1

    for ($col = 1; $col -le $lastCol; $col++) {
        $h = $updateSheet.Cells.Item($headerRow, $col).Text.Trim().ToLower()
        if ($h -match "attribute|field.?name|^name$") { $colName = $col }
        elseif ($h -match "type|data.?type") { $colType = $col }
        elseif ($h -match "required|mandatory|mand") { $colRequired = $col }
        elseif ($h -match "updatable|update|modif") { $colUpdatable = $col }
        elseif ($h -match "code.?table|table|lookup") { $colCodeTable = $col }
        elseif ($h -match "description|desc|comment") { $colDescription = $col }
    }

    if ($colName -lt 0) { $colName = 1 }
    if ($colType -lt 0) { $colType = 2 }

    Write-Host "Column indices - Name:$colName Type:$colType Required:$colRequired Updatable:$colUpdatable" -ForegroundColor Cyan

    # Extract data rows
    for ($row = ($headerRow + 1); $row -le $lastRow; $row++) {
        $name = $updateSheet.Cells.Item($row, $colName).Text.Trim()
        if ([string]::IsNullOrWhiteSpace($name)) { continue }
        if ($name -like "#*" -or $name -like "//*") { continue } # Skip comments

        $type = if ($colType -gt 0) { $updateSheet.Cells.Item($row, $colType).Text.Trim() } else { "String" }
        $required = $false
        if ($colRequired -gt 0) {
            $r = $updateSheet.Cells.Item($row, $colRequired).Text.Trim().ToUpper()
            $required = ($r -eq "Y" -or $r -eq "YES" -or $r -eq "TRUE" -or $r -eq "M" -or $r -eq "MANDATORY")
        }
        $updatable = $true
        if ($colUpdatable -gt 0) {
            $u = $updateSheet.Cells.Item($row, $colUpdatable).Text.Trim().ToUpper()
            $updatable = ($u -ne "N" -and $u -ne "NO" -and $u -ne "FALSE" -and $u -ne "READ-ONLY")
        }
        $codeTable = $null
        if ($colCodeTable -gt 0) {
            $ct = $updateSheet.Cells.Item($row, $colCodeTable).Text.Trim()
            if (-not [string]::IsNullOrWhiteSpace($ct)) { $codeTable = $ct }
        }
        $description = ""
        if ($colDescription -gt 0) {
            $description = $updateSheet.Cells.Item($row, $colDescription).Text.Trim()
        }

        $isPrimitive = $true
        $isCollection = $false
        if ($type -like "*List*" -or $type -like "*Collection*" -or $type -like "*[]*") {
            $isPrimitive = $false
            $isCollection = $true
        }
        elseif ($type -like "*Object*" -or $type -like "*Complex*") {
            $isPrimitive = $false
        }

        $attributes += @{
            name = $name
            type = $type
            required = $required
            updatable = $updatable
            codeTable = $codeTable
            description = $description
            isPrimitive = $isPrimitive
            isCollection = $isCollection
        }
    }

    # Derive business object name
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($ExcelFilePath)
    $businessObject = $fileName -replace '\s*v[\d.]+$', '' -replace '\s*V[\d.]+$', '' -replace '\s+API$', '' -replace '\s+REST$', '' -replace '\s+', ''

    $output = @{
        businessObject = $businessObject
        attributes = $attributes
    }

    $jsonOutput = $output | ConvertTo-Json -Depth 5
    $outputPath = Join-Path (Get-Location) "attributes.json"
    $jsonOutput | Out-File -FilePath $outputPath -Encoding UTF8

    Write-Host ""
    Write-Host "Successfully extracted $($attributes.Count) attributes for '$businessObject'" -ForegroundColor Green
    Write-Host "Output: $outputPath" -ForegroundColor Cyan

    $workbook.Close($false)
    $excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
}
catch {
    Write-Error "Failed to parse spreadsheet with alt format: $_"
    if ($null -ne $excel) {
        try { $workbook.Close($false) } catch {}
        try { $excel.Quit() } catch {}
    }
    exit 1
}
