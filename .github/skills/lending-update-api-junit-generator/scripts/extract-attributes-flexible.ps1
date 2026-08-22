# PowerShell script to extract attributes from a spreadsheet with flexible column-header detection
# This is a fallback when the primary run-excel-reader.ps1 fails due to non-standard format.
#
# Usage: .\extract-attributes-flexible.ps1 "<SpreadsheetPath>" "<SheetName>"
# Example: .\extract-attributes-flexible.ps1 "C:\Auto\API\Deal REST API_V1.xlsx" "Update"
#
# Output: attributes.json in the current directory

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$ExcelFilePath,

    [Parameter(Mandatory=$false, Position=1)]
    [string]$SheetName = "Update"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ExcelFilePath)) {
    Write-Error "Error: Excel file not found at '$ExcelFilePath'"
    exit 1
}

# Try to load the Excel COM object
try {
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false

    $workbook = $excel.Workbooks.Open($ExcelFilePath)

    # Find the target sheet
    $sheet = $null
    foreach ($ws in $workbook.Worksheets) {
        if ($ws.Name -like "*$SheetName*") {
            $sheet = $ws
            break
        }
    }

    if ($null -eq $sheet) {
        # Try common alternate names
        $alternateNames = @("Update", "UPDATE", "Modify", "PATCH", "Put")
        foreach ($altName in $alternateNames) {
            foreach ($ws in $workbook.Worksheets) {
                if ($ws.Name -like "*$altName*") {
                    $sheet = $ws
                    break
                }
            }
            if ($null -ne $sheet) { break }
        }
    }

    if ($null -eq $sheet) {
        Write-Error "Error: Could not find sheet matching '$SheetName' in the workbook"
        $workbook.Close($false)
        $excel.Quit()
        exit 1
    }

    Write-Host "Found sheet: $($sheet.Name)" -ForegroundColor Green

    # Detect header row by searching for common column names
    $headerKeywords = @("Attribute", "Field", "Name", "Type", "Required", "Mandatory", "Updatable", "Description")
    $headerRow = 1
    $maxSearchRows = 10

    for ($row = 1; $row -le $maxSearchRows; $row++) {
        $matchCount = 0
        $lastCol = $sheet.UsedRange.Columns.Count
        for ($col = 1; $col -le $lastCol; $col++) {
            $cellValue = $sheet.Cells.Item($row, $col).Text
            foreach ($keyword in $headerKeywords) {
                if ($cellValue -like "*$keyword*") {
                    $matchCount++
                    break
                }
            }
        }
        if ($matchCount -ge 3) {
            $headerRow = $row
            Write-Host "Detected header row at row $headerRow (matched $matchCount keywords)" -ForegroundColor Cyan
            break
        }
    }

    # Map column indices
    $columnMap = @{}
    $lastCol = $sheet.UsedRange.Columns.Count
    for ($col = 1; $col -le $lastCol; $col++) {
        $headerText = $sheet.Cells.Item($headerRow, $col).Text.Trim()
        if ($headerText -like "*Attribute*" -or $headerText -like "*Field*Name*" -or $headerText -eq "Name") {
            $columnMap["name"] = $col
        }
        elseif ($headerText -like "*Type*" -or $headerText -like "*Data*Type*") {
            $columnMap["type"] = $col
        }
        elseif ($headerText -like "*Required*" -or $headerText -like "*Mandatory*") {
            $columnMap["required"] = $col
        }
        elseif ($headerText -like "*Updatable*" -or $headerText -like "*Update*") {
            $columnMap["updatable"] = $col
        }
        elseif ($headerText -like "*Code*Table*" -or $headerText -like "*Table*") {
            $columnMap["codeTable"] = $col
        }
        elseif ($headerText -like "*Description*" -or $headerText -like "*Desc*") {
            $columnMap["description"] = $col
        }
    }

    Write-Host "Column mapping: $($columnMap | ConvertTo-Json -Compress)" -ForegroundColor Cyan

    # Extract attributes
    $attributes = @()
    $lastRow = $sheet.UsedRange.Rows.Count
    $dataStartRow = $headerRow + 1

    for ($row = $dataStartRow; $row -le $lastRow; $row++) {
        $nameCol = if ($columnMap.ContainsKey("name")) { $columnMap["name"] } else { 1 }
        $name = $sheet.Cells.Item($row, $nameCol).Text.Trim()

        if ([string]::IsNullOrWhiteSpace($name)) { continue }

        $type = ""
        if ($columnMap.ContainsKey("type")) {
            $type = $sheet.Cells.Item($row, $columnMap["type"]).Text.Trim()
        }

        $required = $false
        if ($columnMap.ContainsKey("required")) {
            $reqVal = $sheet.Cells.Item($row, $columnMap["required"]).Text.Trim()
            $required = ($reqVal -eq "Y" -or $reqVal -eq "Yes" -or $reqVal -eq "TRUE" -or $reqVal -eq "Mandatory")
        }

        $updatable = $true
        if ($columnMap.ContainsKey("updatable")) {
            $updVal = $sheet.Cells.Item($row, $columnMap["updatable"]).Text.Trim()
            $updatable = ($updVal -ne "N" -and $updVal -ne "No" -and $updVal -ne "FALSE")
        }

        $codeTable = $null
        if ($columnMap.ContainsKey("codeTable")) {
            $ct = $sheet.Cells.Item($row, $columnMap["codeTable"]).Text.Trim()
            if (-not [string]::IsNullOrWhiteSpace($ct)) { $codeTable = $ct }
        }

        $description = ""
        if ($columnMap.ContainsKey("description")) {
            $description = $sheet.Cells.Item($row, $columnMap["description"]).Text.Trim()
        }

        # Determine if primitive or non-primitive
        $isPrimitive = $true
        $isCollection = $false
        $primitiveTypes = @("String", "Alphanumeric", "Numeric", "Integer", "BigDecimal", "Date", "Boolean", "LocalDate", "LiqDate")
        if ($type -like "*List*" -or $type -like "*Collection*" -or $type -like "*[]") {
            $isPrimitive = $false
            $isCollection = $true
        }
        elseif ($type -notin $primitiveTypes -and -not [string]::IsNullOrWhiteSpace($type)) {
            $knownTypes = $primitiveTypes + @("", "Y", "N")
            if ($type -notin $knownTypes) {
                $isPrimitive = $false
            }
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

    # Derive business object name from file name
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($ExcelFilePath)
    $businessObject = $fileName -replace '\s*v[\d.]+$', '' -replace '\s*V[\d.]+$', '' -replace '\s+API$', '' -replace '\s+REST$', '' -replace '\s+', ''

    # Build output JSON
    $output = @{
        businessObject = $businessObject
        attributes = $attributes
    }

    $jsonOutput = $output | ConvertTo-Json -Depth 5
    $outputPath = Join-Path (Get-Location) "attributes.json"
    $jsonOutput | Out-File -FilePath $outputPath -Encoding UTF8

    Write-Host ""
    Write-Host "Successfully extracted $($attributes.Count) attributes for '$businessObject'" -ForegroundColor Green
    Write-Host "Output written to: $outputPath" -ForegroundColor Cyan

    $workbook.Close($false)
    $excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
}
catch {
    Write-Error "Failed to parse spreadsheet: $_"
    if ($null -ne $excel) {
        try { $workbook.Close($false) } catch {}
        try { $excel.Quit() } catch {}
    }
    exit 1
}
