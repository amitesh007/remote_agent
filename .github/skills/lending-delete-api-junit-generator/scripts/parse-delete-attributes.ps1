<#
.SYNOPSIS
    Parses all attribute rows from the Delete sheet of an extracted spreadsheet.

.DESCRIPTION
    Reads sharedStrings.xml and the specified worksheet XML to extract attribute definitions.
    Outputs structured data: Category, FieldName, DataType, Required, Description, DefaultValue, MappingType.

    Supports two common column layouts:
    - Layout A (columns B,G,H,I,J): Category=B, Field=G, Type=H, Required=I, Desc=J
    - Layout B (columns B,F,G,H,I,J): Category=B, Field=F, Type=G, Required=H, Desc=I, Default=J

.PARAMETER ExtractedPath
    Path to the extracted spreadsheet directory

.PARAMETER SheetFile
    The worksheet XML filename (e.g., "sheet5.xml"). Use find-delete-sheet.ps1 to determine this.

.PARAMETER Layout
    Column layout: "A" (Facility-style: Field=G) or "B" (UserProfile-style: Field=F). Default: auto-detect.

.PARAMETER StartRow
    Row number to start parsing from (0-indexed into row array). Default: 5 (skips header rows).

.PARAMETER EndRow
    Row number to stop parsing at (0-indexed into row array). Default: 150.

.EXAMPLE
    .\parse-delete-attributes.ps1 -ExtractedPath "C:\Auto\API\Upfront_Fee_v2.1_extracted" -SheetFile "sheet5.xml"

.EXAMPLE
    .\parse-delete-attributes.ps1 -ExtractedPath "C:\Auto\API\Deal_REST_API_V1_extracted" -SheetFile "sheet3.xml" -Layout A -StartRow 8
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

# Helper: resolve cell value
function Get-CellValue($cell) {
    if (-not $cell) { return $null }
    if ($cell.t -eq 's') {
        $idx = [int]$cell.v
        if ($idx -lt $strings.Count) { return $strings[$idx] }
        return $null
    }
    return $cell.v
}

# Helper: get cell by column letter
function Get-CellByColumn($row, $colLetter) {
    $cell = $row.c | Where-Object { ($_.r -replace '\d+','') -eq $colLetter }
    return Get-CellValue $cell
}

# Auto-detect layout by checking header row
if ($Layout -eq "Auto") {
    $headerRow = $rows[$StartRow - 1]
    if (-not $headerRow) {
        # Try rows 3-6 for headers
        for ($i = 2; $i -le 6; $i++) {
            $headerRow = $rows[$i]
            $testVal = Get-CellByColumn $headerRow "G"
            if ($testVal -match 'Data Type|DataType|Type|Field') { break }
        }
    }
    
    $colG = Get-CellByColumn $headerRow "G"
    $colH = Get-CellByColumn $headerRow "H"
    
    if ($colG -match 'Data Type|DataType|Type') {
        $Layout = "B"  # Field is in column F, Type in G
        Write-Host "Auto-detected Layout B (Field=F, Type=G, Required=H)"
    } elseif ($colH -match 'Data Type|DataType|Type') {
        $Layout = "A"  # Field is in column G, Type in H
        Write-Host "Auto-detected Layout A (Field=G, Type=H, Required=I)"
    } else {
        Write-Host "Could not auto-detect layout from header row. Trying Layout B as default."
        $Layout = "B"
    }
}

Write-Host ""
Write-Host "Parsing rows $StartRow to $EndRow from $SheetFile (Layout $Layout)"
Write-Host "=" * 80

$attributes = @()
$currentCategory = ""

for ($i = $StartRow; $i -le [Math]::Min($EndRow, $rows.Count - 1); $i++) {
    $row = $rows[$i]
    if (-not $row) { continue }

    # Get category from column B
    $cat = Get-CellByColumn $row "B"
    if ($cat) { $currentCategory = $cat.Trim() }

    # Get field name, type, required, description based on layout
    if ($Layout -eq "A") {
        $fieldName = Get-CellByColumn $row "G"
        $dataType = Get-CellByColumn $row "H"
        $required = Get-CellByColumn $row "I"
        $description = Get-CellByColumn $row "J"
        $defaultValue = Get-CellByColumn $row "K"
        $mappingType = Get-CellByColumn $row "L"
    } else {
        $fieldName = Get-CellByColumn $row "F"
        $dataType = Get-CellByColumn $row "G"
        $required = Get-CellByColumn $row "H"
        $description = Get-CellByColumn $row "I"
        $defaultValue = Get-CellByColumn $row "J"
        $mappingType = Get-CellByColumn $row "K"
    }

    # Skip rows without a field name
    if (-not $fieldName -or $fieldName.Trim() -eq '') { continue }

    # Normalize Required values
    $reqNormalized = switch -Regex ($required) {
        '^(Y|Yes|Mandatory|M|TRUE)$' { "Y" }
        '^(N|No|Optional|O|FALSE)$' { "N" }
        '^(CR|Conditional)$' { "CR" }
        default { $required }
    }

    # Detect mapping type if not explicitly set
    if (-not $mappingType) {
        if ($dataType -match 'List|Collection|Array') {
            $mappingType = "NonPrimitiveCollection"
        } elseif ($dataType -match 'Object|Complex') {
            $mappingType = "NonPrimitive"
        } else {
            $mappingType = "Primitive"
        }
    }

    $attr = [PSCustomObject]@{
        Category     = $currentCategory
        FieldName    = $fieldName.Trim()
        DataType     = if ($dataType) { $dataType.Trim() } else { "String" }
        Required     = if ($reqNormalized) { $reqNormalized.Trim() } else { "N" }
        Description  = if ($description) { $description.Trim() } else { "" }
        DefaultValue = if ($defaultValue) { $defaultValue.Trim() } else { "" }
        MappingType  = if ($mappingType) { $mappingType.Trim() } else { "Primitive" }
    }
    $attributes += $attr

    Write-Host "  [$currentCategory] $($attr.FieldName) | $($attr.DataType) | Req=$($attr.Required) | $($attr.MappingType)"
}

Write-Host ""
Write-Host "=" * 80
Write-Host "Total attributes parsed: $($attributes.Count)"
Write-Host "=" * 80

if ($attributes.Count -eq 0) {
    Write-Error "No attributes found. Try the fallback parser: parse-delete-attributes-fallback.ps1"
    exit 1
}

# Output as structured data
return $attributes
