<#
.SYNOPSIS
    Last-resort fallback that reads the spreadsheet directly via COM Excel automation.

.DESCRIPTION
    When the XML-based extraction and fallback parser both fail (e.g., the .xlsx has 
    non-standard internal structure, password protection on sheets, or heavily merged cells),
    this script opens the file directly using Excel COM automation.

    Requirements: Microsoft Excel must be installed on the machine.

    Falls back gracefully if Excel is not available — outputs an error message suggesting
    the user manually provide attribute data.

.PARAMETER SpreadsheetPath
    Full path to the .xlsx file

.PARAMETER SheetName
    Name of the sheet to parse. Default: "Create"

.PARAMETER MaxRows
    Maximum rows to scan. Default: 300.

.EXAMPLE
    .\parse-via-excel-com.ps1 -SpreadsheetPath "C:\Auto\API\User Profile V2.xlsx"
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$SpreadsheetPath,

    [Parameter(Mandatory=$false)]
    [string]$SheetName = "Create",

    [Parameter(Mandatory=$false)]
    [int]$MaxRows = 300
)

if (-not (Test-Path $SpreadsheetPath)) {
    Write-Error "Spreadsheet not found: $SpreadsheetPath"
    exit 1
}

Write-Host "=" * 80
Write-Host "EXCEL COM FALLBACK: Opening spreadsheet directly via Excel automation"
Write-Host "File: $SpreadsheetPath"
Write-Host "Sheet: $SheetName"
Write-Host "=" * 80
Write-Host ""

$excel = $null
$workbook = $null

try {
    $excel = New-Object -ComObject Excel.Application -ErrorAction Stop
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
    
    $workbook = $excel.Workbooks.Open($SpreadsheetPath, $false, $true)  # ReadOnly=true
    
    # Find the Create sheet
    $sheet = $null
    foreach ($ws in $workbook.Worksheets) {
        if ($ws.Name -match "^$SheetName$") {
            $sheet = $ws
            break
        }
    }
    
    if (-not $sheet) {
        Write-Host "Available sheets:"
        foreach ($ws in $workbook.Worksheets) {
            Write-Host "  - $($ws.Name)"
        }
        Write-Error "Sheet '$SheetName' not found in workbook."
        exit 1
    }
    
    Write-Host "Sheet '$($sheet.Name)' found. Scanning for header row..."
    
    # Find the header row by looking for known patterns
    $headerRow = -1
    $columnMap = @{}
    
    $fieldNamePatterns = @('field\s*name', 'attribute\s*name', 'attribute', 'api\s*field', 'json\s*field', 'field', 'parameter')
    $dataTypePatterns = @('data\s*type', 'datatype', 'type', 'value\s*type')
    $requiredPatterns = @('required', 'mandatory', 'mand', 'req')
    $descriptionPatterns = @('description', 'desc', 'comments?', 'notes?', 'business\s*rule', 'remarks?')
    $defaultPatterns = @('default\s*value', 'default')
    $categoryPatterns = @('category', 'group', 'section', 'heading', 'block', 'object')
    
    $usedRange = $sheet.UsedRange
    $maxCol = [Math]::Min($usedRange.Columns.Count, 26)  # Cap at column Z
    
    for ($r = 1; $r -le [Math]::Min(30, $usedRange.Rows.Count); $r++) {
        $tempMap = @{}
        $hasField = $false
        $hasType = $false
        
        for ($c = 1; $c -le $maxCol; $c++) {
            $val = $sheet.Cells.Item($r, $c).Text
            if (-not $val -or $val.Trim() -eq "") { continue }
            $valLower = $val.Trim().ToLower()
            
            foreach ($p in $fieldNamePatterns) {
                if ($valLower -match "^${p}$") { $tempMap['FieldName'] = $c; $hasField = $true; break }
            }
            foreach ($p in $dataTypePatterns) {
                if ($valLower -match "^${p}$") { $tempMap['DataType'] = $c; $hasType = $true; break }
            }
            foreach ($p in $requiredPatterns) {
                if ($valLower -match "^${p}$") { $tempMap['Required'] = $c; break }
            }
            foreach ($p in $descriptionPatterns) {
                if ($valLower -match "^${p}$") { $tempMap['Description'] = $c; break }
            }
            foreach ($p in $defaultPatterns) {
                if ($valLower -match "^${p}$") { $tempMap['DefaultValue'] = $c; break }
            }
            foreach ($p in $categoryPatterns) {
                if ($valLower -match "^${p}$") { $tempMap['Category'] = $c; break }
            }
        }
        
        if ($hasField -and $hasType) {
            $headerRow = $r
            $columnMap = $tempMap
            Write-Host "  Header found at row $r"
            foreach ($key in $columnMap.Keys) {
                $colVal = $sheet.Cells.Item($r, $columnMap[$key]).Text
                Write-Host "    $key -> Col $($columnMap[$key]) ('$colVal')"
            }
            break
        }
    }
    
    # Looser match if strict fails
    if ($headerRow -eq -1) {
        Write-Host "  Strict match failed, trying loose match..."
        for ($r = 1; $r -le [Math]::Min(30, $usedRange.Rows.Count); $r++) {
            $tempMap = @{}
            $hasField = $false
            $hasType = $false
            
            for ($c = 1; $c -le $maxCol; $c++) {
                $val = $sheet.Cells.Item($r, $c).Text
                if (-not $val -or $val.Trim() -eq "") { continue }
                $valLower = $val.Trim().ToLower()
                
                foreach ($p in $fieldNamePatterns) {
                    if ($valLower -match $p) { $tempMap['FieldName'] = $c; $hasField = $true; break }
                }
                foreach ($p in $dataTypePatterns) {
                    if ($valLower -match $p) { $tempMap['DataType'] = $c; $hasType = $true; break }
                }
                foreach ($p in $requiredPatterns) {
                    if ($valLower -match $p) { $tempMap['Required'] = $c; break }
                }
                foreach ($p in $descriptionPatterns) {
                    if ($valLower -match $p) { $tempMap['Description'] = $c; break }
                }
                foreach ($p in $defaultPatterns) {
                    if ($valLower -match $p) { $tempMap['DefaultValue'] = $c; break }
                }
                foreach ($p in $categoryPatterns) {
                    if ($valLower -match $p) { $tempMap['Category'] = $c; break }
                }
            }
            
            if ($hasField -and $hasType) {
                $headerRow = $r
                $columnMap = $tempMap
                Write-Host "  Header found (loose) at row $r"
                foreach ($key in $columnMap.Keys) {
                    $colVal = $sheet.Cells.Item($r, $columnMap[$key]).Text
                    Write-Host "    $key -> Col $($columnMap[$key]) ('$colVal')"
                }
                break
            }
        }
    }
    
    if ($headerRow -eq -1) {
        Write-Error "Could not find header row in sheet '$SheetName'."
        exit 1
    }
    
    # Parse data rows
    Write-Host ""
    Write-Host "Parsing data rows starting from row $($headerRow + 1)..."
    Write-Host "=" * 80
    
    $attributes = @()
    $lastCategory = ""
    $endRow = [Math]::Min($headerRow + $MaxRows, $usedRange.Rows.Count)
    
    for ($r = $headerRow + 1; $r -le $endRow; $r++) {
        $field = if ($columnMap.ContainsKey('FieldName')) {
            $sheet.Cells.Item($r, $columnMap['FieldName']).Text.Trim()
        } else { "" }
        
        if (-not $field -or $field -eq "") {
            # Check for category-only row
            if ($columnMap.ContainsKey('Category')) {
                $cat = $sheet.Cells.Item($r, $columnMap['Category']).Text.Trim()
                if ($cat) { $lastCategory = $cat }
            }
            continue
        }
        
        # Skip sub-headers or notes
        if ($field -match '^(note|end of|total|page|sheet)' -or $field.Length -gt 60) { continue }
        
        $category = if ($columnMap.ContainsKey('Category')) {
            $val = $sheet.Cells.Item($r, $columnMap['Category']).Text.Trim()
            if ($val) { $lastCategory = $val; $val } else { $lastCategory }
        } else { $lastCategory }
        
        $dataType = if ($columnMap.ContainsKey('DataType')) {
            $sheet.Cells.Item($r, $columnMap['DataType']).Text.Trim()
        } else { "" }
        
        $required = if ($columnMap.ContainsKey('Required')) {
            $sheet.Cells.Item($r, $columnMap['Required']).Text.Trim()
        } else { "" }
        
        $description = if ($columnMap.ContainsKey('Description')) {
            $raw = $sheet.Cells.Item($r, $columnMap['Description']).Text.Trim()
            if ($raw) { $raw.Substring(0, [Math]::Min(150, $raw.Length)) } else { "" }
        } else { "" }
        
        $defaultVal = if ($columnMap.ContainsKey('DefaultValue')) {
            $sheet.Cells.Item($r, $columnMap['DefaultValue']).Text.Trim()
        } else { "" }
        
        # Normalize Required field
        $normalizedRequired = switch -Regex ($required.ToUpper()) {
            '^(Y|YES|TRUE|MANDATORY|MAND|M)$' { "Y" }
            '^(N|NO|FALSE|OPTIONAL|OPT|O)$' { "N" }
            '^(CR|COND|CONDITIONAL|C)$' { "CR" }
            default { if ($required) { $required } else { "N" } }
        }
        
        $attr = [PSCustomObject]@{
            Row = $r
            Category = $category
            FieldName = $field
            DataType = $dataType
            Required = $normalizedRequired
            Description = $description
            DefaultValue = $defaultVal
        }
        $attributes += $attr
        
        $reqFlag = switch ($attr.Required) {
            "Y" { "[MANDATORY]" }
            "CR" { "[CONDITIONAL]" }
            default { "[OPTIONAL]" }
        }
        Write-Host "Row${r}: $reqFlag $($attr.FieldName) ($($attr.DataType)) $(if($attr.Category){"[$($attr.Category)]"})"
    }
    
    Write-Host ""
    Write-Host "=" * 80
    Write-Host "EXCEL COM FALLBACK Summary:"
    Write-Host "  Total attributes: $($attributes.Count)"
    Write-Host "  Mandatory (Y): $(($attributes | Where-Object { $_.Required -eq 'Y' }).Count)"
    Write-Host "  Conditional (CR): $(($attributes | Where-Object { $_.Required -eq 'CR' }).Count)"
    Write-Host "  Optional (N): $(($attributes | Where-Object { $_.Required -eq 'N' -or $_.Required -eq '' }).Count)"
    Write-Host ""
    
    if ($attributes.Count -eq 0) {
        Write-Error "EXCEL COM FALLBACK: No attributes could be extracted."
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
    
} catch [System.Runtime.InteropServices.COMException] {
    Write-Error "Excel COM automation failed. Excel may not be installed."
    Write-Host "Error: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "ALTERNATIVE: Please provide the attribute data manually in the following format:"
    Write-Host "  FieldName | DataType | Required (Y/N/CR) | Description"
    Write-Host ""
    Write-Host "Or install the ImportExcel PowerShell module:"
    Write-Host "  Install-Module ImportExcel -Scope CurrentUser"
    exit 1
} catch {
    Write-Error "Unexpected error: $($_.Exception.Message)"
    exit 1
} finally {
    if ($workbook) {
        $workbook.Close($false)
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($workbook) | Out-Null
    }
    if ($excel) {
        $excel.Quit()
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
    }
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}
