# PowerShell script to extract attributes from a CSV export of the spreadsheet
# This is the last-resort fallback when .xlsx parsing fails entirely.
# The user should first export the Update sheet to CSV manually.
#
# Usage: .\extract-from-csv.ps1 "<CsvFilePath>"
# Example: .\extract-from-csv.ps1 "C:\Auto\API\Deal_Update.csv"
#
# If a .xlsx path is provided, this script will attempt to use ImportExcel module
# or prompt the user to export to CSV first.
#
# Output: attributes.json in the current directory

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$FilePath
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $FilePath)) {
    Write-Error "Error: File not found at '$FilePath'"
    exit 1
}

$extension = [System.IO.Path]::GetExtension($FilePath).ToLower()

# If xlsx provided, try ImportExcel module
if ($extension -eq ".xlsx" -or $extension -eq ".xls") {
    Write-Host "Attempting to use ImportExcel module for .xlsx file..." -ForegroundColor Yellow

    if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
        Write-Host "ImportExcel module not found. Attempting install..." -ForegroundColor Yellow
        try {
            Install-Module ImportExcel -Force -Scope CurrentUser -ErrorAction Stop
        }
        catch {
            Write-Error "Cannot parse .xlsx without Excel COM or ImportExcel module."
            Write-Host "Please export the Update sheet to CSV and re-run with the CSV path." -ForegroundColor Red
            Write-Host "In Excel: Open file -> Select 'Update' sheet -> File -> Save As -> CSV" -ForegroundColor Yellow
            exit 1
        }
    }

    Import-Module ImportExcel

    # Find Update sheet
    $sheetNames = Get-ExcelSheetInfo -Path $FilePath | Select-Object -ExpandProperty Name
    $updateSheet = $sheetNames | Where-Object { $_ -like "*Update*" } | Select-Object -First 1

    if ($null -eq $updateSheet) {
        $updateSheet = $sheetNames | Select-Object -First 1
        Write-Host "Warning: No 'Update' sheet found. Using first sheet: $updateSheet" -ForegroundColor Yellow
    }

    $data = Import-Excel -Path $FilePath -WorksheetName $updateSheet
    Write-Host "Loaded $($data.Count) rows from sheet '$updateSheet'" -ForegroundColor Green
}
elseif ($extension -eq ".csv") {
    $data = Import-Csv -Path $FilePath
    Write-Host "Loaded $($data.Count) rows from CSV" -ForegroundColor Green
}
else {
    Write-Error "Unsupported file type: $extension. Please provide .xlsx, .xls, or .csv"
    exit 1
}

# Detect column names (flexible matching)
$columns = $data[0].PSObject.Properties.Name
Write-Host "Detected columns: $($columns -join ', ')" -ForegroundColor Cyan

$nameCol = $columns | Where-Object { $_ -match "(?i)attribute|field.?name|^name$" } | Select-Object -First 1
$typeCol = $columns | Where-Object { $_ -match "(?i)type|data.?type" } | Select-Object -First 1
$requiredCol = $columns | Where-Object { $_ -match "(?i)required|mandatory" } | Select-Object -First 1
$updatableCol = $columns | Where-Object { $_ -match "(?i)updatable|update" } | Select-Object -First 1
$codeTableCol = $columns | Where-Object { $_ -match "(?i)code.?table|table|lookup" } | Select-Object -First 1
$descriptionCol = $columns | Where-Object { $_ -match "(?i)description|desc" } | Select-Object -First 1

if ($null -eq $nameCol) { $nameCol = $columns[0] }
if ($null -eq $typeCol) { $typeCol = $columns[1] }

Write-Host "Using columns - Name:'$nameCol' Type:'$typeCol' Required:'$requiredCol' Updatable:'$updatableCol'" -ForegroundColor Cyan

# Extract attributes
$attributes = @()

foreach ($row in $data) {
    $name = if ($null -ne $nameCol) { $row.$nameCol } else { "" }
    if ([string]::IsNullOrWhiteSpace($name)) { continue }

    $type = if ($null -ne $typeCol) { $row.$typeCol } else { "String" }
    $required = $false
    if ($null -ne $requiredCol) {
        $r = "$($row.$requiredCol)".Trim().ToUpper()
        $required = ($r -eq "Y" -or $r -eq "YES" -or $r -eq "TRUE" -or $r -eq "MANDATORY")
    }
    $updatable = $true
    if ($null -ne $updatableCol) {
        $u = "$($row.$updatableCol)".Trim().ToUpper()
        $updatable = ($u -ne "N" -and $u -ne "NO" -and $u -ne "FALSE")
    }
    $codeTable = $null
    if ($null -ne $codeTableCol) {
        $ct = "$($row.$codeTableCol)".Trim()
        if (-not [string]::IsNullOrWhiteSpace($ct)) { $codeTable = $ct }
    }
    $description = ""
    if ($null -ne $descriptionCol) {
        $description = "$($row.$descriptionCol)".Trim()
    }

    $isPrimitive = $true
    $isCollection = $false
    if ("$type" -like "*List*" -or "$type" -like "*Collection*" -or "$type" -like "*[]*") {
        $isPrimitive = $false
        $isCollection = $true
    }
    elseif ("$type" -like "*Object*" -or "$type" -like "*Complex*") {
        $isPrimitive = $false
    }

    $attributes += @{
        name = "$name".Trim()
        type = "$type".Trim()
        required = $required
        updatable = $updatable
        codeTable = $codeTable
        description = $description
        isPrimitive = $isPrimitive
        isCollection = $isCollection
    }
}

# Derive business object name from file name
$fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
$businessObject = $fileName -replace '\s*v[\d.]+$', '' -replace '\s*V[\d.]+$', '' -replace '\s+API$', '' -replace '\s+REST$', '' -replace '_Update$', '' -replace '_CSV$', '' -replace '\s+', ''

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
