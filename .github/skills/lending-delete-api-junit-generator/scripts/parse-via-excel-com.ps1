<#
.SYNOPSIS
    Last-resort parser using Excel COM automation to extract Delete sheet attributes.

.DESCRIPTION
    Opens the .xlsx directly using Excel COM automation when XML-based parsers fail.
    Handles merged cells, password-protected sheets, and non-standard XML internals.
    Requires Microsoft Excel to be installed.

.PARAMETER SpreadsheetPath
    Full path to the .xlsx file

.PARAMETER SheetName
    Name of the sheet to parse. Default: "Delete"

.PARAMETER MaxRows
    Maximum rows to scan. Default: 300.

.EXAMPLE
    .\parse-via-excel-com.ps1 -SpreadsheetPath "C:\Auto\API\Upfront Fee v2.1.xlsx" -SheetName "Delete"
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$SpreadsheetPath,

    [Parameter(Mandatory=$false)]
    [string]$SheetName = "Delete",

    [Parameter(Mandatory=$false)]
    [int]$MaxRows = 300
)

if (-not (Test-Path $SpreadsheetPath)) {
    Write-Error "Spreadsheet not found: $SpreadsheetPath"
    exit 1
}

Write-Host "=" * 80
Write-Host "EXCEL COM PARSER: Opening $SpreadsheetPath"
Write-Host "Target sheet: $SheetName"
Write-Host "=" * 80
Write-Host ""

# Try to create Excel COM object
try {
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
} catch {
    Write-Error "Microsoft Excel is not installed or COM automation is not available."
    Write-Error "Please provide attribute data manually or install Excel."
    exit 1
}

try {
    $workbook = $excel.Workbooks.Open($SpreadsheetPath, $false, $true)
    
    # Find the Delete sheet
    $sheet = $null
    foreach ($ws in $workbook.Worksheets) {
        if ($ws.Name -match "^${SheetName}$") {
            $sheet = $ws
            break
        }
    }
    
    if (-not $sheet) {
        Write-Error "Sheet '$SheetName' not found. Available sheets:"
        foreach ($ws in $workbook.Worksheets) {
            Write-Host "  - $($ws.Name)"
        }
        exit 1
    }
    
    Write-Host "Found sheet: $($sheet.Name)"
    Write-Host ""

    # Known header patterns
    $fieldNamePatterns = @('field\s*name', 'attribute\s*name', 'attribute_field_name', 'attribute', 'api\s*field', 'field', 'parameter')
    $dataTypePatterns = @('data\s*type', 'datatype', 'type')
    $requiredPatterns = @('required', 'mandatory', 'mand', 'req')
    $descriptionPatterns = @('description', 'attribute_description', 'desc', 'comments?', 'notes?', 'remarks?')
    $defaultPatterns = @('default\s*value', 'default')
    $mappingTypePatterns = @('mapping\s*type', 'mapping', 'field\s*type')

    # Step 1: Find header row (scan first 30 rows)
    Write-Host "Step 1: Scanning for header row..."
    $headerRow = -1
    $columnMap = @{}
    $usedRange = $sheet.UsedRange
    $maxCol = [Math]::Min($usedRange.Columns.Count, 20)

    for ($r = 1; $r -le 30; $r++) {
        $matchCount = 0
        $tempMap = @{}
        
        for ($c = 1; $c -le $maxCol; $c++) {
            $val = $sheet.Cells($r, $c).Text
            if (-not $val -or $val.Trim() -eq '') { continue }
            $val = $val.Trim()
            
            foreach ($pattern in $fieldNamePatterns) {
                if ($val -match $pattern -and -not $tempMap.ContainsKey('FieldName')) {
                    $tempMap['FieldName'] = $c; $matchCount++; break
                }
            }
            foreach ($pattern in $dataTypePatterns) {
                if ($val -match $pattern -and -not $tempMap.ContainsKey('DataType')) {
                    $tempMap['DataType'] = $c; $matchCount++; break
                }
            }
            foreach ($pattern in $requiredPatterns) {
                if ($val -match $pattern -and -not $tempMap.ContainsKey('Required')) {
                    $tempMap['Required'] = $c; $matchCount++; break
                }
            }
            foreach ($pattern in $descriptionPatterns) {
                if ($val -match $pattern -and -not $tempMap.ContainsKey('Description')) {
                    $tempMap['Description'] = $c; break
                }
            }
            foreach ($pattern in $defaultPatterns) {
                if ($val -match $pattern -and -not $tempMap.ContainsKey('DefaultValue')) {
                    $tempMap['DefaultValue'] = $c; break
                }
            }
            foreach ($pattern in $mappingTypePatterns) {
                if ($val -match $pattern -and -not $tempMap.ContainsKey('MappingType')) {
                    $tempMap['MappingType'] = $c; break
                }
            }
        }

        if ($matchCount -ge 2) {
            $headerRow = $r
            $columnMap = $tempMap
            Write-Host "  Header row found at row $r"
            break
        }
    }

    if ($headerRow -eq -1) {
        Write-Error "Could not find header row in first 30 rows."
        exit 1
    }

    Write-Host "Column mapping:"
    $columnMap.GetEnumerator() | ForEach-Object { Write-Host "  $($_.Key) -> Column $($_.Value)" }
    Write-Host ""

    if (-not $columnMap.ContainsKey('FieldName')) {
        Write-Error "Could not identify FieldName column."
        exit 1
    }

    # Step 2: Parse data rows
    Write-Host "Step 2: Parsing data rows..."
    $attributes = @()
    $currentCategory = ""
    $dataEnd = [Math]::Min($headerRow + $MaxRows, $usedRange.Rows.Count)

    for ($r = $headerRow + 1; $r -le $dataEnd; $r++) {
        $fieldName = $sheet.Cells($r, $columnMap['FieldName']).Text
        if (-not $fieldName -or $fieldName.Trim() -eq '') { continue }
        $fieldName = $fieldName.Trim()

        $dataType = if ($columnMap.ContainsKey('DataType')) { $sheet.Cells($r, $columnMap['DataType']).Text.Trim() } else { "String" }
        $required = if ($columnMap.ContainsKey('Required')) { $sheet.Cells($r, $columnMap['Required']).Text.Trim() } else { "N" }
        $description = if ($columnMap.ContainsKey('Description')) { $sheet.Cells($r, $columnMap['Description']).Text.Trim() } else { "" }
        $defaultValue = if ($columnMap.ContainsKey('DefaultValue')) { $sheet.Cells($r, $columnMap['DefaultValue']).Text.Trim() } else { "" }
        $mappingType = if ($columnMap.ContainsKey('MappingType')) { $sheet.Cells($r, $columnMap['MappingType']).Text.Trim() } else { $null }

        # Normalize Required
        $reqNormalized = switch -Regex ($required) {
            '^(Y|Yes|Mandatory|M|TRUE)$' { "Y" }
            '^(N|No|Optional|O|FALSE)$' { "N" }
            '^(CR|Conditional)$' { "CR" }
            default { $required }
        }

        # Detect mapping type
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

        Write-Host "  $fieldName | $dataType | Req=$reqNormalized | $mappingType"
    }

    Write-Host ""
    Write-Host "=" * 80
    Write-Host "Total attributes parsed (COM): $($attributes.Count)"
    Write-Host "=" * 80

    if ($attributes.Count -eq 0) {
        Write-Error "Excel COM parser found 0 attributes. Please provide attribute data manually."
        exit 1
    }

    return $attributes

} finally {
    # Clean up COM objects
    if ($workbook) { $workbook.Close($false) }
    if ($excel) { $excel.Quit() }
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
    [System.GC]::Collect()
}
