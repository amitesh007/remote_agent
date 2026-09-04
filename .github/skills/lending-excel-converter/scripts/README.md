# lending-excel-converter — Scripts

## Scripts in this folder

| Script | Purpose |
|---|---|
| `convert-excel.mjs` | Converts V4-format requirement spreadsheets to the reference Upfront Fee format |

## Prerequisites

```bash
npm install xlsx
```

## Usage

```bash
# Single file
node convert-excel.mjs --source ../../../../IntegrationAPITool/artifacts/requirement_doc/InterestPayment-V4.xlsx \
                        --output-dir ../../../../IntegrationAPITool/artifacts/requirement_doc/converted

# Batch (entire directory)
node convert-excel.mjs --source-dir ../../../../IntegrationAPITool/artifacts/requirement_doc \
                        --output-dir ../../../../IntegrationAPITool/artifacts/requirement_doc/converted
```

## Testing the conversion

Run against the three source files and verify output against the reference:

```bash
node convert-excel.mjs \
  --source "C:/Users/asrivas3/git/remote_agent/IntegrationAPITool/artifacts/requirement_doc/InterestPayment-V4.xlsx" \
  --output-dir ./out

node convert-excel.mjs \
  --source "C:/Users/asrivas3/git/remote_agent/IntegrationAPITool/artifacts/requirement_doc/PrincipalPayment-V4.xlsx" \
  --output-dir ./out

node convert-excel.mjs \
  --source "C:/Users/asrivas3/git/remote_agent/IntegrationAPITool/artifacts/requirement_doc/LoanInitialDrawndown-V4.xlsx" \
  --output-dir ./out
```

## What the script converts

Each source sheet goes through three phases:

1. **Header detection** — scans the header row for keyword-based column identification
   (handles typos like "Attriute Field Name" and column-order variations between sheets)
2. **Data extraction** — collects input rows (above OUTPUT marker) and output rows
3. **Format mapping** — writes reference-format rows with:
   - Derived class names from `ENTITY_NAME`
   - Java type mapping (Alphanumeric → String, Date/Time → LocalDateTime, etc.)
   - 32-column layout for Create/Update, 29-column layout for GetByID/Delete
