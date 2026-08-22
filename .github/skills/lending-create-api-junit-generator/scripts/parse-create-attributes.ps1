<#
.SYNOPSIS
    Parses all attribute rows from the Create sheet of an extracted spreadsheet.

.DESCRIPTION
    Reads sharedStrings.xml and the specified worksheet XML to extract attribute definitions.
    Outputs structured data: Category, FieldName, DataType, Required, Description, DefaultValue.

    Supports two common column layouts:
    - Layout A (columns B,G,H,I,J): Category=B, Field=G, Type=H, Required=I, Desc=J
    - Layout B (columns B,F,G,H,I,J): Category=B, Field=F, Type=G, Required=H, Desc=I, Default=J

.PARAMETER ExtractedPath
    Path to the extracted spreadsheet directory

.PARAMETER SheetFile
    The worksheet XML filename (e.g., "sheet4.xml"). Use find-create-sheet.ps1 to determine this.

.PARAMETER Layout
    Column layout: "A" (Facility-style: Field=G) or "B" (UserProfile-style: Field=F). Default: auto-detect.

.PARAMETER StartRow
    Row number to start parsing from (0-indexed into row array). Default: 5 (skips header rows).

.PARAMETER EndRow
    Row number to stop parsing at (0-indexed into row array). Default: 150.

.EXAMPLE
    .\parse-create-attributes.ps1 -ExtractedPath "C:\Auto\API\User_Profile_V2_extracted" -SheetFile "sheet4.xml"

.EXAMPLE
    .\parse-create-attributes.ps1 -ExtractedPath "C:\Auto\API\Facility_v9_extracted" -SheetFile "sheet2.xml" -Layout A -StartRow 8
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$ExtractedPath,

    [Parameter(Mandatory=$true)]
    [string]$SheetFile,

    [Parameter(Mandatory=$false)]
    [ValidateSet("A", "B", "Auto")]
    [string]$Layout = "Auto",

    [Parameter(Mandatory=$false)]
    [int]$StartRow = 5,

    [Parameter(Mandatory=$false)]
    [int]$EndRow = 150
)

$sharedStringsPath = Join-Path $ExtractedPath "xl\sharedStrings.xml"
$sheetPath = Join-Path $ExtractedPath "xl\worksheets\$SheetFile"

if (-not (Test-Path $sharedStringsPath)) {
    Write-Error "sharedStrings.xml not found: $sharedStringsPath"
    exit 1
}
if (-not (Test-Path $sheetPath)) {
    Write-Error "Sheet file not found: $sheetPath"
    exit 1
}

# Parse shared strings
[xml]$ss = Get-Content $sharedStringsPath
$strings = $ss.sst.si | ForEach-Object {
    if ($_.t -is [string]) { $_.t }
    elseif ($_.t.'#text') { $_.t.'#text' }
    else { ($_.r | ForEach-Object { $_.t }) -join '' }
}

# Parse sheet
[xml]$sheet = Get-Content $sheetPath
$rows = $sheet.worksheet.sheetData.row

# Auto-detect layout by checking header row
if ($Layout -eq "Auto") {
    $headerRow = $rows[$StartRow - 1]
    $headerCells = @{}
    foreach ($c in $headerRow.c) {
        $col = ($c.r -replace '\d+','')
        $val = if ($c.t -eq 's') { $strings[[int]$c.v] } else { $c.v }
        $headerCells[$col] = $val
    }
    
    if ($headerCells['G'] -match 'Data Type|DataType|Type') {
        $Layout = "B"  # Field is in column F, Type in G
        Write-Host "Auto-detected Layout B (Field=F, Type=G, Required=H)"
    } elseif ($headerCells['H'] -match 'Data Type|DataType|Type') {
        $Layout = "A"  # Field is in column G, Type in H
        Write-Host "Auto-detected Layout A (Field=G, Type=H, Required=I)"
    } else {
        $Layout = "B"  # Default to B
        Write-Host "Could not auto-detect layout, defaulting to B (Field=F)"
    }
}

Write-Host ""
Write-Host "Parsing rows $StartRow to $EndRow from $SheetFile (Layout $Layout)"
Write-Host "=" * 80

$attributes = @()
$maxRow = [Math]::Min($EndRow, $rows.Count - 1)

foreach ($row in $rows[$StartRow..$maxRow]) {
    $cells = @{}
    foreach ($c in $row.c) {
        $col = ($c.r -replace '\d+','')
        $val = if ($c.t -eq 's') { $strings[[int]$c.v] } else { $c.v }
        $cells[$col] = $val
    }
    
    # Extract based on layout
    if ($Layout -eq "A") {
        $category = $cells['B']
        $field = $cells['G']
        $type = $cells['H']
        $required = $cells['I']
        $desc = $cells['J']
        $default = $cells['K']
    } else {
        # Layout B
        $category = $cells['B']
        $field = $cells['F']
        $type = $cells['G']
        $required = $cells['H']
        $desc = $cells['I']
        $default = $cells['J']
    }
    
    if ($field) {
        $field = $field.Trim()
        $attr = [PSCustomObject]@{
            Row = $row.r
            Category = if ($category) { $category.Trim() } else { "" }
            FieldName = $field
            DataType = if ($type) { $type.Trim() } else { "" }
            Required = if ($required) { $required.Trim() } else { "" }
            Description = if ($desc) { $desc.Trim().Substring(0, [Math]::Min(100, $desc.Trim().Length)) } else { "" }
            DefaultValue = if ($default) { $default.Trim() } else { "" }
        }
        $attributes += $attr
        
        # Print to console
        $reqFlag = switch ($attr.Required) {
            "Y" { "[MANDATORY]" }
            "CR" { "[CONDITIONAL]" }
            default { "[OPTIONAL]" }
        }
        Write-Host "Row$($row.r): $reqFlag $($attr.FieldName) ($($attr.DataType)) $(if($attr.Category){"[$($attr.Category)]"})"
    }
}

Write-Host ""
Write-Host "=" * 80
Write-Host "Summary:"
Write-Host "  Total attributes: $($attributes.Count)"
Write-Host "  Mandatory (Y): $(($attributes | Where-Object { $_.Required -eq 'Y' }).Count)"
Write-Host "  Conditional (CR): $(($attributes | Where-Object { $_.Required -eq 'CR' }).Count)"
Write-Host "  Optional (N): $(($attributes | Where-Object { $_.Required -eq 'N' -or $_.Required -eq '' }).Count)"
Write-Host ""

# Group by category
$categories = $attributes | Group-Object Category
Write-Host "Categories:"
foreach ($cat in $categories) {
    $catName = if ($cat.Name) { $cat.Name } else { "(root-level)" }
    Write-Host "  $catName : $($cat.Count) fields"
}

return $attributes
