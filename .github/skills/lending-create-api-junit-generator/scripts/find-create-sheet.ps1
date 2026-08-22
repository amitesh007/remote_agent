<#
.SYNOPSIS
    Locates the "Create" sheet in an extracted .xlsx workbook.

.DESCRIPTION
    Reads workbook.xml and workbook.xml.rels to find the sheet named "Create" (case-insensitive).
    Returns the worksheet XML filename (e.g., "sheet4.xml").

.PARAMETER ExtractedPath
    Path to the extracted spreadsheet directory (e.g., "C:\Auto\API\User_Profile_V2_extracted")

.EXAMPLE
    .\find-create-sheet.ps1 -ExtractedPath "C:\Auto\API\User_Profile_V2_extracted"
    # Output: sheet4.xml
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$ExtractedPath
)

$workbookPath = Join-Path $ExtractedPath "xl\workbook.xml"
$relsPath = Join-Path $ExtractedPath "xl\_rels\workbook.xml.rels"

if (-not (Test-Path $workbookPath)) {
    Write-Error "workbook.xml not found at: $workbookPath"
    exit 1
}
if (-not (Test-Path $relsPath)) {
    Write-Error "workbook.xml.rels not found at: $relsPath"
    exit 1
}

[xml]$wb = Get-Content $workbookPath
[xml]$rels = Get-Content $relsPath

# List all sheets
Write-Host "Available sheets:"
$wb.workbook.sheets.sheet | ForEach-Object {
    Write-Host "  $($_.sheetId): $($_.name)"
}
Write-Host ""

# Find the Create sheet (case-insensitive)
$createSheet = $wb.workbook.sheets.sheet | Where-Object { $_.name -match '^create$' }

if (-not $createSheet) {
    Write-Error "No 'Create' sheet found in workbook. Available sheets listed above."
    exit 1
}

$rId = $createSheet.id
Write-Host "Create sheet found: '$($createSheet.name)' (rId=$rId)"

# Resolve the relationship to get the target file
$rel = $rels.Relationships.Relationship | Where-Object { $_.Id -eq $rId }

if (-not $rel) {
    Write-Error "Could not resolve relationship for rId=$rId"
    exit 1
}

$target = $rel.Target
$sheetFile = [System.IO.Path]::GetFileName($target)
$fullPath = Join-Path $ExtractedPath "xl\$target"

Write-Host "Sheet XML file: $sheetFile"
Write-Host "Full path: $fullPath"

if (-not (Test-Path $fullPath)) {
    Write-Error "Sheet file not found: $fullPath"
    exit 1
}

Write-Host ""
Write-Host "Use this in parse-create-attributes.ps1:"
Write-Host "  .\parse-create-attributes.ps1 -ExtractedPath `"$ExtractedPath`" -SheetFile `"$sheetFile`""

return $sheetFile
