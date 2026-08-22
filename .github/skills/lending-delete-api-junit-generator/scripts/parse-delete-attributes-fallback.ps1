<#
.SYNOPSIS
    Fallback parser for spreadsheets whose column layout does not match Layout A or B.

.DESCRIPTION
    When parse-delete-attributes.ps1 fails (zero attributes found, auto-detect failure, or 
    unexpected column positions), this script uses a brute-force approach:
    1. Reads ALL cells from the Delete sheet
    2. Detects the header row dynamically by scanning for known keywords
       (e.g., "Field Name", "Attribute", "Data Type", "Required", "Mandatory")
    3. Maps columns based on header content rather than fixed positions
    4. Outputs the same structured format: Category, FieldName, DataType, Required, Description, DefaultValue, MappingType

    This handles spreadsheets with:
    - Different column orderings
    - Extra columns inserted between expected ones
    - Different header naming conventions
    - Merged or offset header rows

.PARAMETER ExtractedPath
    Path to the extracted spreadsheet directory

.PARAMETER SheetFile
    The worksheet XML filename (e.g., "sheet5.xml")

.PARAMETER MaxRows
    Maximum rows to scan. Default: 300.

.EXAMPLE
    .\parse-delete-attributes-fallback.ps1 -ExtractedPath "C:\Auto\API\Upfront_Fee_v2.1_extracted" -SheetFile "sheet5.xml"
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
Write-Host "FALLBACK PARSER: Scanning $SheetFile for delete attribute data"
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

# Helper: extract column letter from cell reference
function Get-Column($cellRef) {
    return ($cellRef -replace '\d+', '')
}

# Known header patterns (case-insensitive regex)
$fieldNamePatterns = @('field\s*name', 'attribute\s*name', 'attribute_field_name', 'attribute', 'api\s*field', 'json\s*field', 'field', 'parameter\s*name', 'parameter')
$dataTypePatterns = @('data\s*type', 'datatype', 'type', 'value\s*type')
$requiredPatterns = @('required', 'mandatory', 'mand', 'req', 'is\s*required', 'is\s*mandatory')
$descriptionPatterns = @('description', 'attribute_description', 'desc', 'comments?', 'notes?', 'business\s*rule', 'remarks?', 'details?')
$defaultPatterns = @('default\s*value', 'default', 'def\s*val')
$categoryPatterns = @('category', 'group', 'section', 'heading', 'block', 'object')
$mappingTypePatterns = @('mapping\s*type', 'mapping', 'field\s*type', 'primitive')

# Step 1: Scan first 30 rows to find header row
Write-Host "Step 1: Scanning for header row..."
$headerRowIndex = -1
$columnMap = @{}

$scanLimit = [Math]::Min(30, $rows.Count)
for ($i = 0; $i -lt $scanLimit; $i++) {
    $row = $rows[$i]
    if (-not $row) { continue }

    $cellValues = @{}
    foreach ($c in $row.c) {
        $col = Get-Column $c.r
        $val = Get-CellValue $c
        if ($val) { $cellValues[$col] = $val.ToString().Trim() }
    }

    # Check if this row has header-like content
    $matchCount = 0
    foreach ($col in $cellValues.Keys) {
        $val = $cellValues[$col]
        foreach ($pattern in $fieldNamePatterns) {
            if ($val -match $pattern) { $matchCount++; break }
        }
        foreach ($pattern in $dataTypePatterns) {
            if ($val -match $pattern) { $matchCount++; break }
        }
        foreach ($pattern in $requiredPatterns) {
            if ($val -match $pattern) { $matchCount++; break }
        }
    }

    if ($matchCount -ge 2) {
        $headerRowIndex = $i
        Write-Host "  Header row found at index $i (row $($row.r))"
        
        # Map columns to roles
        foreach ($col in $cellValues.Keys) {
            $val = $cellValues[$col]
            $matched = $false
            
            foreach ($pattern in $fieldNamePatterns) {
                if ($val -match $pattern -and -not $columnMap.ContainsKey('FieldName')) {
                    $columnMap['FieldName'] = $col
                    $matched = $true; break
                }
            }
            if ($matched) { continue }
            
            foreach ($pattern in $dataTypePatterns) {
                if ($val -match $pattern -and -not $columnMap.ContainsKey('DataType')) {
                    $columnMap['DataType'] = $col
                    $matched = $true; break
                }
            }
            if ($matched) { continue }
            
            foreach ($pattern in $requiredPatterns) {
                if ($val -match $pattern -and -not $columnMap.ContainsKey('Required')) {
                    $columnMap['Required'] = $col
                    $matched = $true; break
                }
            }
            if ($matched) { continue }
            
            foreach ($pattern in $descriptionPatterns) {
                if ($val -match $pattern -and -not $columnMap.ContainsKey('Description')) {
                    $columnMap['Description'] = $col
                    $matched = $true; break
                }
            }
            if ($matched) { continue }
            
            foreach ($pattern in $defaultPatterns) {
                if ($val -match $pattern -and -not $columnMap.ContainsKey('DefaultValue')) {
                    $columnMap['DefaultValue'] = $col
                    $matched = $true; break
                }
            }
            if ($matched) { continue }
            
            foreach ($pattern in $categoryPatterns) {
                if ($val -match $pattern -and -not $columnMap.ContainsKey('Category')) {
                    $columnMap['Category'] = $col
                    $matched = $true; break
                }
            }
            if ($matched) { continue }

            foreach ($pattern in $mappingTypePatterns) {
                if ($val -match $pattern -and -not $columnMap.ContainsKey('MappingType')) {
                    $columnMap['MappingType'] = $col
                    $matched = $true; break
                }
            }
        }
        break
    }
}

if ($headerRowIndex -eq -1) {
    Write-Error "Could not find header row in first 30 rows of the Delete sheet."
    exit 1
}

Write-Host ""
Write-Host "Column mapping:"
$columnMap.GetEnumerator() | ForEach-Object { Write-Host "  $($_.Key) -> Column $($_.Value)" }
Write-Host ""

if (-not $columnMap.ContainsKey('FieldName')) {
    Write-Error "Could not identify FieldName column. Headers found but no field name pattern matched."
    exit 1
}

# Step 2: Parse data rows
Write-Host "Step 2: Parsing data rows starting from row index $($headerRowIndex + 1)..."
$attributes = @()
$currentCategory = ""

$dataStart = $headerRowIndex + 1
$dataEnd = [Math]::Min($dataStart + $MaxRows, $rows.Count - 1)

for ($i = $dataStart; $i -le $dataEnd; $i++) {
    $row = $rows[$i]
    if (-not $row) { continue }

    # Build cell map for this row
    $cellValues = @{}
    foreach ($c in $row.c) {
        $col = Get-Column $c.r
        $val = Get-CellValue $c
        if ($val) { $cellValues[$col] = $val.ToString().Trim() }
    }

    # Get category
    if ($columnMap.ContainsKey('Category') -and $cellValues.ContainsKey($columnMap['Category'])) {
        $currentCategory = $cellValues[$columnMap['Category']]
    }

    # Get field name (required)
    $fieldName = if ($cellValues.ContainsKey($columnMap['FieldName'])) { $cellValues[$columnMap['FieldName']] } else { $null }
    if (-not $fieldName -or $fieldName -eq '') { continue }

    # Get other fields
    $dataType = if ($columnMap.ContainsKey('DataType') -and $cellValues.ContainsKey($columnMap['DataType'])) { $cellValues[$columnMap['DataType']] } else { "String" }
    $required = if ($columnMap.ContainsKey('Required') -and $cellValues.ContainsKey($columnMap['Required'])) { $cellValues[$columnMap['Required']] } else { "N" }
    $description = if ($columnMap.ContainsKey('Description') -and $cellValues.ContainsKey($columnMap['Description'])) { $cellValues[$columnMap['Description']] } else { "" }
    $defaultValue = if ($columnMap.ContainsKey('DefaultValue') -and $cellValues.ContainsKey($columnMap['DefaultValue'])) { $cellValues[$columnMap['DefaultValue']] } else { "" }
    $mappingType = if ($columnMap.ContainsKey('MappingType') -and $cellValues.ContainsKey($columnMap['MappingType'])) { $cellValues[$columnMap['MappingType']] } else { $null }

    # Normalize Required
    $reqNormalized = switch -Regex ($required) {
        '^(Y|Yes|Mandatory|M|TRUE)$' { "Y" }
        '^(N|No|Optional|O|FALSE)$' { "N" }
        '^(CR|Conditional)$' { "CR" }
        default { $required }
    }

    # Detect mapping type if not set
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
        FieldName    = $fieldName
        DataType     = $dataType
        Required     = $reqNormalized
        Description  = $description
        DefaultValue = $defaultValue
        MappingType  = $mappingType
    }
    $attributes += $attr

    Write-Host "  [$currentCategory] $fieldName | $dataType | Req=$reqNormalized | $mappingType"
}

Write-Host ""
Write-Host "=" * 80
Write-Host "Total attributes parsed (fallback): $($attributes.Count)"
Write-Host "=" * 80

if ($attributes.Count -eq 0) {
    Write-Error "Fallback parser also found 0 attributes. Try parse-via-excel-com.ps1 or provide data manually."
    exit 1
}

return $attributes
