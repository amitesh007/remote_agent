<#
.SYNOPSIS
    Extracts an .xlsx spreadsheet to XML files for parsing.

.DESCRIPTION
    Copies the .xlsx file to .zip, extracts it, and removes the temporary zip.
    The extracted folder contains xl/workbook.xml, xl/sharedStrings.xml, and xl/worksheets/*.xml.

.PARAMETER SpreadsheetPath
    Full path to the .xlsx file (e.g., "C:\Auto\API\Upfront Fee v2.1.xlsx")

.PARAMETER OutputPath
    (Optional) Output directory for extracted files. Defaults to same directory with _extracted suffix.

.EXAMPLE
    .\extract-spreadsheet.ps1 -SpreadsheetPath "C:\Auto\API\Upfront Fee v2.1.xlsx"
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$SpreadsheetPath,

    [Parameter(Mandatory=$false)]
    [string]$OutputPath
)

# Validate input file exists
if (-not (Test-Path $SpreadsheetPath)) {
    Write-Error "Spreadsheet not found: $SpreadsheetPath"
    exit 1
}

# Derive output path if not specified
if (-not $OutputPath) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($SpreadsheetPath) -replace '\s+', '_'
    $parentDir = [System.IO.Path]::GetDirectoryName($SpreadsheetPath)
    $OutputPath = Join-Path $parentDir "${baseName}_extracted"
}

# Clean previous extraction
if (Test-Path $OutputPath) {
    Remove-Item -Recurse -Force $OutputPath
    Write-Host "Cleaned previous extraction: $OutputPath"
}

# Copy to .zip and extract
$tempZip = Join-Path ([System.IO.Path]::GetDirectoryName($SpreadsheetPath)) ("_temp_extract_" + [guid]::NewGuid().ToString("N") + ".zip")
Copy-Item $SpreadsheetPath $tempZip
Expand-Archive -Path $tempZip -DestinationPath $OutputPath -Force
Remove-Item $tempZip

Write-Host "Extracted to: $OutputPath"
Write-Host ""
Write-Host "Contents:"
Get-ChildItem $OutputPath -Recurse -File | Select-Object -First 20 | ForEach-Object {
    Write-Host "  $($_.FullName.Replace($OutputPath, '.'))"
}

# Return the output path for piping
return $OutputPath
