<#
.SYNOPSIS
    Locates the "Delete" sheet in an extracted .xlsx workbook.

.DESCRIPTION
    Reads workbook.xml and workbook.xml.rels to find the sheet named "Delete" (case-insensitive).
    Returns the worksheet XML filename (e.g., "sheet5.xml").

.PARAMETER ExtractedPath
    Path to the extracted spreadsheet directory (e.g., "C:\Auto\API\Upfront_Fee_v2.1_extracted")

.EXAMPLE
    .\find-delete-sheet.ps1 -ExtractedPath "C:\Auto\API\Upfront_Fee_v2.1_extracted"
    # Output: sheet5.xml
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

# Find the Delete sheet (case-insensitive)
$deleteSheet = $wb.workbook.sheets.sheet | Where-Object { $_.name -match '^delete$' }

if (-not $deleteSheet) {
    Write-Error "No 'Delete' sheet found in workbook. Available sheets listed above."
    Write-Host ""
    Write-Host "TIP: If the delete information is on a differently-named sheet, please provide the sheet name."
    exit 1
}

$rId = $deleteSheet.id
Write-Host "Delete sheet found: '$($deleteSheet.name)' (rId=$rId)"

# Resolve the relationship to get the target file
$rel = $rels.Relationships.Relationship | Where-Object { $_.Id -eq $rId }

if (-not $rel) {
    Write-Error "Could not resolve relationship for rId=$rId"
    exit 1
}

$targetFile = [System.IO.Path]::GetFileName($rel.Target)
Write-Host "Worksheet file: $targetFile"

# Verify the file exists
$sheetPath = Join-Path $ExtractedPath "xl\worksheets\$targetFile"
if (-not (Test-Path $sheetPath)) {
    Write-Error "Worksheet file not found at: $sheetPath"
    exit 1
}

return $targetFile
