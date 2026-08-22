<#
.SYNOPSIS
    Fallback parser for spreadsheets whose column layout does not match Layout A or B.

.DESCRIPTION
    When parse-create-attributes.ps1 fails (zero attributes found, auto-detect failure, or 
    unexpected column positions), this script uses a brute-force approach:
    1. Reads ALL cells from the Create sheet
    2. Detects the header row dynamically by scanning for known keywords
       (e.g., "Field Name", "Attribute", "Data Type", "Required", "Mandatory")
    3. Maps columns based on header content rather than fixed positions
    4. Outputs the same structured format: Category, FieldName, DataType, Required, Description, DefaultValue

    This handles spreadsheets with:
    - Different column orderings
    - Extra columns inserted between expected ones
    - Different header naming conventions
    - Merged or offset header rows

.PARAMETER ExtractedPath
    Path to the extracted spreadsheet directory

.PARAMETER SheetFile
    The worksheet XML filename (e.g., "sheet4.xml")

.PARAMETER MaxRows
    Maximum rows to scan. Default: 300.

.EXAMPLE
    .\parse-create-attributes-fallback.ps1 -ExtractedPath "C:\Auto\API\User_Profile_V2_extracted" -SheetFile "sheet4.xml"
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$ExtractedPath,

    [Parameter(Mandatory=$true)]
    [string]$SheetFile,

    [Parameter(Mandatory=$false)]
    [int]$MaxRows = 300
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

Write-Host "=" * 80
Write-Host "FALLBACK PARSER: Scanning $SheetFile for attribute data"
Write-Host "Total rows in sheet: $($rows.Count)"
Write-Host "=" * 80
Write-Host ""

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

# Helper: extract column letter from cell reference (e.g., "AB12" -> "AB")
function Get-Column($cellRef) {
    return ($cellRef -replace '\d+', '')
}

# Step 1: Build a full cell map for the first 30 rows to find headers
Write-Host "Step 1: Scanning for header row..."
$headerRowIndex = -1
$columnMap = @{}  # Maps role -> column letter

# Known header patterns (case-insensitive regex)
$fieldNamePatterns = @('field\s*name', 'attribute\s*name', 'attribute', 'api\s*field', 'json\s*field', 'field', 'parameter\s*name', 'parameter')
$dataTypePatterns = @('data\s*type', 'datatype', 'type', 'value\s*type')
$requiredPatterns = @('required', 'mandatory', 'mand', 'req', 'is\s*required', 'is\s*mandatory')
$descriptionPatterns = @('description', 'desc', 'comments?', 'notes?', 'business\s*rule', 'remarks?', 'details?')
$defaultPatterns = @('default\s*value', 'default', 'def\s*val')
$categoryPatterns = @('category', 'group', 'section', 'heading', 'block', 'object')

$scanLimit = [Math]::Min(30, $rows.Count)

for ($i = 0; $i -lt $scanLimit; $i++) {
    $row = $rows[$i]
    $cellValues = @{}
    foreach ($c in $row.c) {
        $col = Get-Column $c.r
        $val = Get-CellValue $c
        if ($val) { $cellValues[$col] = $val.ToString().Trim() }
    }

    # Check if this row looks like a header (must have at least field name + data type patterns)
    $hasFieldName = $false
    $hasDataType = $false
    $tempMap = @{}

    foreach ($col in $cellValues.Keys) {
        $val = $cellValues[$col].ToLower()
        
        foreach ($p in $fieldNamePatterns) {
            if ($val -match "^${p}$") { $tempMap['FieldName'] = $col; $hasFieldName = $true; break }
        }
        foreach ($p in $dataTypePatterns) {
            if ($val -match "^${p}$") { $tempMap['DataType'] = $col; $hasDataType = $true; break }
        }
        foreach ($p in $requiredPatterns) {
            if ($val -match "^${p}$") { $tempMap['Required'] = $col; break }
        }
        foreach ($p in $descriptionPatterns) {
            if ($val -match "^${p}$") { $tempMap['Description'] = $col; break }
        }
        foreach ($p in $defaultPatterns) {
            if ($val -match "^${p}$") { $tempMap['DefaultValue'] = $col; break }
        }
        foreach ($p in $categoryPatterns) {
            if ($val -match "^${p}$") { $tempMap['Category'] = $col; break }
        }
    }

    if ($hasFieldName -and $hasDataType) {
        $headerRowIndex = $i
        $columnMap = $tempMap
        Write-Host "  Header row found at index $i (row $($row.r))"
        Write-Host "  Column mapping:"
        foreach ($key in $columnMap.Keys) {
            Write-Host "    $key -> Column $($columnMap[$key]) (value: '$($cellValues[$columnMap[$key]])')"
        }
        break
    }
}

# If header not found with strict matching, try looser matching
if ($headerRowIndex -eq -1) {
    Write-Host "  Strict header match failed. Trying looser matching..."
    for ($i = 0; $i -lt $scanLimit; $i++) {
        $row = $rows[$i]
        $cellValues = @{}
        foreach ($c in $row.c) {
            $col = Get-Column $c.r
            $val = Get-CellValue $c
            if ($val) { $cellValues[$col] = $val.ToString().Trim() }
        }

        $hasFieldName = $false
        $hasDataType = $false
        $tempMap = @{}

        foreach ($col in $cellValues.Keys) {
            $val = $cellValues[$col].ToLower()
            
            foreach ($p in $fieldNamePatterns) {
                if ($val -match $p) { $tempMap['FieldName'] = $col; $hasFieldName = $true; break }
            }
            foreach ($p in $dataTypePatterns) {
                if ($val -match $p) { $tempMap['DataType'] = $col; $hasDataType = $true; break }
            }
            foreach ($p in $requiredPatterns) {
                if ($val -match $p) { $tempMap['Required'] = $col; break }
            }
            foreach ($p in $descriptionPatterns) {
                if ($val -match $p) { $tempMap['Description'] = $col; break }
            }
            foreach ($p in $defaultPatterns) {
                if ($val -match $p) { $tempMap['DefaultValue'] = $col; break }
            }
            foreach ($p in $categoryPatterns) {
                if ($val -match $p) { $tempMap['Category'] = $col; break }
            }
        }

        if ($hasFieldName -and $hasDataType) {
            $headerRowIndex = $i
            $columnMap = $tempMap
            Write-Host "  Header row found (loose match) at index $i (row $($row.r))"
            Write-Host "  Column mapping:"
            foreach ($key in $columnMap.Keys) {
                Write-Host "    $key -> Column $($columnMap[$key]) (value: '$($cellValues[$columnMap[$key]])')"
            }
            break
        }
    }
}

# If still not found, try to find any row with "field" or "attribute" in it
if ($headerRowIndex -eq -1) {
    Write-Host "  Loose matching also failed. Scanning for any row containing 'field' or 'attribute'..."
    for ($i = 0; $i -lt $scanLimit; $i++) {
        $row = $rows[$i]
        foreach ($c in $row.c) {
            $val = Get-CellValue $c
            if ($val -and $val.ToString().Trim().ToLower() -match '(field|attribute)') {
                $headerRowIndex = $i
                # Use positional heuristic: field name col is where we found 'field/attribute'
                $fieldCol = Get-Column $c.r
                $columnMap['FieldName'] = $fieldCol
                # Assume next columns are type, required, description
                $allCols = @()
                foreach ($cc in $row.c) { $allCols += Get-Column $cc.r }
                $allCols = $allCols | Sort-Object
                $fieldIdx = [array]::IndexOf($allCols, $fieldCol)
                if ($fieldIdx + 1 -lt $allCols.Count) { $columnMap['DataType'] = $allCols[$fieldIdx + 1] }
                if ($fieldIdx + 2 -lt $allCols.Count) { $columnMap['Required'] = $allCols[$fieldIdx + 2] }
                if ($fieldIdx + 3 -lt $allCols.Count) { $columnMap['Description'] = $allCols[$fieldIdx + 3] }
                if ($fieldIdx - 1 -ge 0) { $columnMap['Category'] = $allCols[$fieldIdx - 1] }
                Write-Host "  Heuristic header found at index $i (row $($row.r))"
                Write-Host "  Column mapping (heuristic):"
                foreach ($key in $columnMap.Keys) {
                    Write-Host "    $key -> Column $($columnMap[$key])"
                }
                break
            }
        }
        if ($headerRowIndex -ne -1) { break }
    }
}

if ($headerRowIndex -eq -1) {
    Write-Error "FALLBACK FAILED: Could not locate header row in any of the first $scanLimit rows."
    Write-Host "Dumping first 10 rows for manual inspection:"
    for ($i = 0; $i -lt [Math]::Min(10, $rows.Count); $i++) {
        $row = $rows[$i]
        Write-Host "  Row $($row.r):"
        foreach ($c in $row.c) {
            $val = Get-CellValue $c
            if ($val) { Write-Host "    $(Get-Column $c.r): $val" }
        }
    }
    exit 1
}

# Step 2: Parse data rows starting after the header
Write-Host ""
Write-Host "Step 2: Parsing data rows starting after header (index $($headerRowIndex + 1))..."
Write-Host "=" * 80

$attributes = @()
$startIdx = $headerRowIndex + 1
$endIdx = [Math]::Min($startIdx + $MaxRows, $rows.Count - 1)
$lastCategory = ""

for ($i = $startIdx; $i -le $endIdx; $i++) {
    $row = $rows[$i]
    $cells = @{}
    foreach ($c in $row.c) {
        $col = Get-Column $c.r
        $val = Get-CellValue $c
        if ($val) { $cells[$col] = $val.ToString().Trim() }
    }

    # Extract field name
    $field = if ($columnMap.ContainsKey('FieldName') -and $cells.ContainsKey($columnMap['FieldName'])) {
        $cells[$columnMap['FieldName']]
    } else { $null }

    # Skip empty rows
    if (-not $field -or $field -eq "" -or $field -match '^\s*$') {
        # Check if this is a category-only row
        if ($columnMap.ContainsKey('Category') -and $cells.ContainsKey($columnMap['Category'])) {
            $lastCategory = $cells[$columnMap['Category']]
        }
        continue
    }

    # Skip rows that look like sub-headers or notes
    if ($field -match '^(note|end of|total|page|sheet)' -or $field.Length -gt 60) {
        continue
    }

    # Extract other fields
    $category = if ($columnMap.ContainsKey('Category') -and $cells.ContainsKey($columnMap['Category'])) {
        $cells[$columnMap['Category']]
    } else { $lastCategory }

    $dataType = if ($columnMap.ContainsKey('DataType') -and $cells.ContainsKey($columnMap['DataType'])) {
        $cells[$columnMap['DataType']]
    } else { "" }

    $required = if ($columnMap.ContainsKey('Required') -and $cells.ContainsKey($columnMap['Required'])) {
        $cells[$columnMap['Required']]
    } else { "" }

    $description = if ($columnMap.ContainsKey('Description') -and $cells.ContainsKey($columnMap['Description'])) {
        $raw = $cells[$columnMap['Description']]
        $raw.Substring(0, [Math]::Min(150, $raw.Length))
    } else { "" }

    $defaultVal = if ($columnMap.ContainsKey('DefaultValue') -and $cells.ContainsKey($columnMap['DefaultValue'])) {
        $cells[$columnMap['DefaultValue']]
    } else { "" }

    # Normalize Required field
    $normalizedRequired = switch -Regex ($required.ToUpper()) {
        '^(Y|YES|TRUE|MANDATORY|MAND|M)$' { "Y" }
        '^(N|NO|FALSE|OPTIONAL|OPT|O)$' { "N" }
        '^(CR|COND|CONDITIONAL|C)$' { "CR" }
        default { if ($required) { $required } else { "N" } }
    }

    # Update category tracking
    if ($category -and $category -ne "") {
        $lastCategory = $category
    } elseif ($lastCategory) {
        $category = $lastCategory
    }

    $attr = [PSCustomObject]@{
        Row = $row.r
        Category = if ($category) { $category } else { "" }
        FieldName = $field
        DataType = if ($dataType) { $dataType } else { "" }
        Required = $normalizedRequired
        Description = if ($description) { $description } else { "" }
        DefaultValue = if ($defaultVal) { $defaultVal } else { "" }
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

Write-Host ""
Write-Host "=" * 80
Write-Host "FALLBACK PARSER Summary:"
Write-Host "  Total attributes: $($attributes.Count)"
Write-Host "  Mandatory (Y): $(($attributes | Where-Object { $_.Required -eq 'Y' }).Count)"
Write-Host "  Conditional (CR): $(($attributes | Where-Object { $_.Required -eq 'CR' }).Count)"
Write-Host "  Optional (N): $(($attributes | Where-Object { $_.Required -eq 'N' -or $_.Required -eq '' }).Count)"
Write-Host ""

if ($attributes.Count -eq 0) {
    Write-Error "FALLBACK FAILED: No attributes could be extracted. The spreadsheet format is not parseable."
    Write-Host "Column map used: $($columnMap | ConvertTo-Json -Compress)"
    exit 1
}

# Group by category
$categories = $attributes | Group-Object Category
Write-Host "Categories:"
foreach ($cat in $categories) {
    $catName = if ($cat.Name) { $cat.Name } else { "(root-level)" }
    Write-Host "  $catName : $($cat.Count) fields"
}

return $attributes
