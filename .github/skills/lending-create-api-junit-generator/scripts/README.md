# Scripts for Create Test Generation

This folder contains PowerShell scripts used during the process of generating Create Integration Test classes. These scripts handle spreadsheet extraction, parsing, and codebase discovery.

## Scripts

| Script | Purpose |
|---|---|
| `extract-spreadsheet.ps1` | Extracts .xlsx file to XML for parsing |
| `find-create-sheet.ps1` | Locates the "Create" sheet in the workbook |
| `parse-create-attributes.ps1` | Parses all attribute rows from the Create sheet |
| `discover-codebase.ps1` | Finds integration classes, enums, security symbols in codebase |

## Usage

All scripts accept parameters. Run them from any PowerShell terminal.

```powershell
# Step 1: Extract spreadsheet
.\extract-spreadsheet.ps1 -SpreadsheetPath "C:\Auto\API\User Profile V2.xlsx"

# Step 2: Find the Create sheet
.\find-create-sheet.ps1 -ExtractedPath "C:\Auto\API\User_Profile_V2_extracted"

# Step 3: Parse attributes from the Create sheet
.\parse-create-attributes.ps1 -ExtractedPath "C:\Auto\API\User_Profile_V2_extracted" -SheetFile "sheet4.xml"

# Step 4: Discover codebase classes and enums
.\discover-codebase.ps1 -BusinessObject "UserProfile" -CodebasePath "C:\Users\asrivas3\git\7740_3\FLIQ-liqjava\LoanIQ"
```
