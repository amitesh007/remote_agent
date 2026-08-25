---
name: lending-excel-converter
description: 'Converts LoanIQ API requirement spreadsheets from the V4 format (e.g. InterestPayment-V4.xlsx) to the reference Upfront Fee format (bundled template/UpfrontFee.xlsx). Processes Create, Update, GetByID, and Delete worksheets. Any sheet not present in the source file is silently skipped. Uses Node.js with exceljs (style-preserving template cloning) and xlsx/SheetJS (source-value parsing only).'
---

# Excel Converter Skill

> **Purpose**: Transform LoanIQ API requirement spreadsheets from the multi-column V4 template
> into the canonical reference format used by the Upfront Fee v2.1 specification, producing an
> output file that is visually IDENTICAL to the reference (fonts, fills, borders, merges).
>
> **By default, the converted file is written to the SAME DIRECTORY as the source file**
> (overwriting it if no different name is given). Pass `--output` or `--output-dir` to write
> elsewhere instead.
>
> **After the reference-format conversion completes, a second step automatically runs**
> (`format-validation-rules.mjs`) that reformats the free-text `ATTRIBUTE_DESCRIPTION` /
> `SWAGGER_ATTRIBUTE_DESCRIPTION` cells of every INPUT-attribute row into clear, numbered
> validation points (see [Validation-rule formatting](#validation-rule-formatting) below).
>
> **A third, OPTIONAL step** (`insert-entity-name.mjs`) runs only when the invoking prompt
> itself explicitly states `ENTITY_NAME` and its value (passed through as `--entity-name`). When
> triggered, it writes the literal string `ENTITY_NAME` into cell A2 and the supplied value into
> cell B2 of every `Create` / `Update` / `GetByID` / `Delete` sheet (see
> [ENTITY_NAME marker insertion](#entity_name-marker-insertion) below).

---

## How it works

The reference workbook — bundled at
`.github/skills/lending-excel-converter/template/UpfrontFee.xlsx` (override with `--reference <path>`) —
is loaded at run time with **ExcelJS**, which — unlike the free `xlsx`/SheetJS package — fully
supports both reading AND writing cell styles (fill colour, font, border, alignment). Every
non-data row (legends, Prerequisites, metadata, Input/OUTPUT markers, column headers, trailing
blank rows) is cloned verbatim (value + full style) straight from the reference file. Only the
data rows are regenerated, reusing the exact style of the reference's own first sample data row
for every column. Source workbooks are parsed with the lightweight `xlsx` package for VALUES
only — no style handling needed on the source side.

Once every sheet has been rebuilt in reference format, `convert-excel.mjs` automatically calls
`format-validation-rules.mjs` (see below) on the in-memory workbook — before it is written to
disk — so the output file already has clean, numbered validation-rule text on first write. If
`--entity-name` was explicitly supplied, it then also calls `insert-entity-name.mjs` to embed an
ENTITY_NAME/value marker at A2/B2 of every sheet, before the workbook is written.

---

## What it does

| Source format (V4) | → | Reference format (Upfront Fee) |
|---|---|---|
| Free-text header rows, varied column counts per sheet | | Standardised legend rows, 32-column input/output sections |
| `ENTITY_NAME` / `ENTITY_VALUE` at R1 | | Derived `INTEGRATION_CLASS`, `RESPONSE_CLASS`, `CLASS_NAME` |
| "Alphanumeric" / "Date" source types | | Mapped Java types (`String`, `LocalDate`, …) |
| Sheet names: `Create`, `Update`, `GetByID`, `Delete` | | Sheet names: `Create`, `Update`, `GetById`, `Delete` |

---

## Prerequisites

- Node.js ≥ 18
- `xlsx` package installed (`npm install xlsx`) — used for parsing source file values only
- `exceljs` package installed (`npm install exceljs`) — used for reading/cloning/writing the reference workbook with full style fidelity
- Reference workbook bundled at `.github/skills/lending-excel-converter/template/UpfrontFee.xlsx` (or pass `--reference <path>` to use a different one)

---

## How to run the script

```bash
# Convert a single file — output written alongside the source (default, overwrites it)
node .github/skills/lending-excel-converter/scripts/convert-excel.mjs \
     --source IntegrationAPITool/artifacts/requirement_doc/InterestPayment-V4.xlsx

# Convert a single file to an explicit output directory
node .github/skills/lending-excel-converter/scripts/convert-excel.mjs \
     --source IntegrationAPITool/artifacts/requirement_doc/InterestPayment-V4.xlsx \
     --output-dir IntegrationAPITool/artifacts/requirement_doc/converted

# Convert a single file to an explicit output path
node .github/skills/lending-excel-converter/scripts/convert-excel.mjs \
     --source InterestPayment-V4.xlsx \
     --output InterestPayment-converted.xlsx

# Convert with an explicit entity name (bypasses auto-detection — needed when
# re-converting an already-converted file, since it no longer has a raw
# ENTITY_NAME row)
node .github/skills/lending-excel-converter/scripts/convert-excel.mjs \
     --source IntegrationAPITool/artifacts/requirement_doc/PrincipalPayment-V4.xlsx \
     --entity-name LoanPrincipalPayment

# Batch convert every .xlsx file in a directory — outputs written alongside each source (default)
node .github/skills/lending-excel-converter/scripts/convert-excel.mjs \
     --source-dir IntegrationAPITool/artifacts/requirement_doc

# Batch convert to a separate output directory
node .github/skills/lending-excel-converter/scripts/convert-excel.mjs \
     --source-dir IntegrationAPITool/artifacts/requirement_doc \
     --output-dir IntegrationAPITool/artifacts/requirement_doc/converted
```

---

## Arguments

| Argument | Required? | Description |
|---|---|---|
| `--source <path>` | One of `--source` or `--source-dir` | Path to a single `.xlsx` source file |
| `--source-dir <dir>` | One of `--source` or `--source-dir` | Directory containing `.xlsx` source files |
| `--output <path>` | Optional | Explicit output file path (single-file mode only). Defaults to overwriting the source file in place. |
| `--output-dir <dir>` | Optional | Directory where converted files are written. Defaults to the source file's own directory (i.e. same location as the file being converted). |
| `--reference <path>` | Optional (default: bundled `.github/skills/lending-excel-converter/template/UpfrontFee.xlsx`) | Path to the reference workbook to clone structure/styles from |
| `--entity-name <name>` | Optional | Forces the entity name used for derived class names (`INTEGRATION_CLASS`, `RESPONSE_CLASS`, `CLASS_NAME`, sheet titles), bypassing auto-detection. Use this when re-converting an already-converted file (it no longer has a raw `ENTITY_NAME` row) to avoid an incorrect filename-derived guess. |

---

## Column mapping rules

### Create / Update sheets (32-column reference format)

| Reference column | Source column (detected via header scan) |
|---|---|
| `SL_NO` | `Sl No.` |
| `CLASS_NAME` | Derived: `Create{EntityName}Integration` / `Update{EntityName}Integration` |
| `ATTRIBUTE_CATEGORY` + `SWAGGER_ATTRIBUTE_CATEGORY` | `Attribute Category` |
| `IS_LIST` | `Multiple instances allowed for Attribute Category (Y/N)` |
| `ATTRIBUTE_FIELD_NAME` + `SWAGGER_ATTRIBUTE_FIELD_NAME` | `Attriute Field Name` |
| `DATA_TYPE` | Mapped Java type from `Data Type` |
| `REQUIRED` | `Required (Y/N)` |
| `ATTRIBUTE_DESCRIPTION` + `SWAGGER_ATTRIBUTE_DESCRIPTION` | `Description and Validation` |
| `MULTIPLE_VALUES_ALLOWED` | `Multiple Values allowed (Y/N)` |
| `TRANSLATION_REQUIRED` | `Translation Required (Y/N)` |
| `TRANSLATION_LOGIC` | `Translation Logic` |
| `CODE_TABLE` | `Code Table` |
| `ATTRIBUTE_EXISTING_IN_SOAP_API` | `Attribute Existing in SOAP API (Y/N)` |
| `MIN_SIZE` / `MAX_SIZE` | `-1` (default) |

### GetByID / Delete sheets (same 32-column format as Create/Update)

`GetById` and `Delete` now share the EXACT same 32-column structure, styles, cell merges and
legend/metadata rows as `Create`/`Update` (R/NR legend, Prerequisites banner, PCP, FILE_OP_PATH,
SOAP_CLASS, INTEGRATION_CLASS, RESPONSE_CLASS, PACKAGE_NAME, Input banner, 32-column headers,
OUTPUT banner). There is no free-text title row. `CLASS_NAME` is derived as
`Get{EntityName}Integration` / `Delete{EntityName}Integration` respectively, and `INTEGRATION_CLASS`
is derived as `LiqAPI{EntityName}QueryIntegration` / `LiqAPI{EntityName}DeleteIntegration`. Fields
that aren't semantically applicable to a Query/Delete operation (e.g. `UPDATABLE`) are still
present for structural parity but populated with a neutral default (`N`). Column counts are
derived dynamically from the reference file's actual populated content (not hardcoded).

---

## Validation-rule formatting

After `convert-excel.mjs` finishes rebuilding a workbook in reference format, it automatically
runs `format-validation-rules.mjs` (`formatWorkbookValidations()`) against the in-memory
workbook, **before** writing the file to disk. This is a second, deterministic pass — no
LLM/AI rewriting — that only reformats text already present:

- Scans every sheet's INPUT-attribute data rows (between the input header row and the `OUTPUT`
  marker) for columns headed `ATTRIBUTE_DESCRIPTION` or `SWAGGER_ATTRIBUTE_DESCRIPTION` (the
  field populated from the source's `Description and Validation` column).
- Splits each cell's free text into candidate validation points on newlines, bullet markers
  (`·`, `-`, `*`, `1.`, `1)`, …) and sentence boundaries.
- Cleans each point: strips a redundant leading `Validation:` label, capitalises the first
  letter, and ensures it ends with terminal punctuation.
- **Every** cell is rewritten as a NUMBERED list within the SAME cell — even a cell with only
  one point is numbered `1. ...` — for consistent, unambiguous formatting, e.g.:
  ```
  1. Must not be null.
  2. Must be unique within the bank.
  3. Must match one of the active values in the Risk Type table.
  ```
- A cell that has **no description text at all** is not left blank: a baseline validation is
  synthesised from that row's `REQUIRED`, `DATA_TYPE`, `Multiple Values allowed (Y/N)` and
  `Default Value` columns, e.g.:
  ```
  1. Optional field; may be left blank.
  2. Must be either Y (true) or N (false).
  3. Default value is unchecked.
  ```
  so every input attribute ends up with a proper, numbered validation rule set.

Cell styling (font, fill, wrap) is preserved — only the text value changes.

### Running it standalone

The formatter can also be run directly against an already-converted (reference-format) file,
independent of `convert-excel.mjs`:

```bash
# Reformat validation text in place
node .github/skills/lending-excel-converter/scripts/format-validation-rules.mjs \
     --source IntegrationAPITool/artifacts/requirement_doc/InterestPayment-V4.xlsx

# Reformat and write to a different output path
node .github/skills/lending-excel-converter/scripts/format-validation-rules.mjs \
     --source IntegrationAPITool/artifacts/requirement_doc/InterestPayment-V4.xlsx \
     --output IntegrationAPITool/artifacts/requirement_doc/InterestPayment-V4-reformatted.xlsx
```

---

## ENTITY_NAME marker insertion

This THIRD and FINAL pipeline step (`insert-entity-name.mjs`) is **conditional**: it only runs
when the invoking prompt itself explicitly contains `ENTITY_NAME` and its corresponding value
(passed through to `convert-excel.mjs` as `--entity-name <value>`). If no `--entity-name` is
supplied, this step is skipped entirely and the file is unaffected.

When it does run, it embeds a literal, machine-readable marker into every `Create` / `Update` /
`GetByID` / `Delete` sheet of the workbook:

- Cell **A2** is set to the literal string `ENTITY_NAME`.
- Cell **B2** is set to the supplied entity value (e.g. `LoanPrincipalPayment`).

Some sheets (`GetById`, `Delete`) have A2 merged across several columns as part of a
"Prerequisites" banner row in the reference template; this step automatically un-merges that
range first so A2 and B2 can hold their own independent values.

This gives every future conversion a reliable, fixed-position marker to detect the entity name
from (row 2, column A/B) — even after the file has already been converted once and its original
raw `ENTITY_NAME` row (from the V4 source format) no longer exists.

### Running it standalone

```bash
# Insert the marker in place
node .github/skills/lending-excel-converter/scripts/insert-entity-name.mjs \
     --source IntegrationAPITool/artifacts/requirement_doc/PrincipalPayment-V4.xlsx \
     --entity-name LoanPrincipalPayment

# Insert the marker and write to a different output path
node .github/skills/lending-excel-converter/scripts/insert-entity-name.mjs \
     --source IntegrationAPITool/artifacts/requirement_doc/PrincipalPayment-V4.xlsx \
     --entity-name LoanPrincipalPayment \
     --output IntegrationAPITool/artifacts/requirement_doc/PrincipalPayment-V4-marked.xlsx
```

---

## Java type mapping

| Source type | Java type |
|---|---|
| `Alphanumeric` | `String` |
| `Numeric` / `Number` | `BigDecimal` |
| `Boolean` | `Boolean` |
| `Date` | `LocalDate` |
| `Date/Time` | `LocalDateTime` |
| `Enum` | `String` |
| `Integer` / `Int` | `Integer` |
| `Long` | `Long` |
| (anything else) | kept as-is |

---

## How to invoke as a Copilot skill

### Single file — convert and overwrite in-place (default behaviour)

```
#lending-excel-converter Convert 'IntegrationAPITool/artifacts/requirement_doc/InterestPayment-V4.xlsx' to Upfront Fee reference format
```

This writes the converted file to the SAME location as the source file (no `--output`/`--output-dir` needed).

### Single file — convert and save to a specific output directory

```
#lending-excel-converter Convert spreadsheet at 'IntegrationAPITool/artifacts/requirement_doc/InterestPayment-V4.xlsx' to reference format and save to 'IntegrationAPITool/artifacts/requirement_doc/converted/InterestPayment-V4.xlsx'
```

### Single file — convert and overwrite in-place

```
#lending-excel-converter Convert 'IntegrationAPITool/artifacts/requirement_doc/PrincipalPayment-V4.xlsx' to Upfront Fee reference format and save the output to 'IntegrationAPITool/artifacts/requirement_doc/PrincipalPayment-V4.xlsx'
```

### Batch — convert all files in a directory

```
#lending-excel-converter Convert all Excel spreadsheets in 'IntegrationAPITool/artifacts/requirement_doc' to reference format and write outputs to 'IntegrationAPITool/artifacts/requirement_doc/converted'
```

### With explicit entity name override (when ENTITY_NAME row is missing)

```
#lending-excel-converter Convert 'IntegrationAPITool/artifacts/requirement_doc/LoanInitialDrawndown-V4.xlsx' to reference format using entity name 'LoanDrawdown' and save to 'IntegrationAPITool/artifacts/requirement_doc/converted/LoanInitialDrawndown-V4.xlsx'
```

### With ENTITY_NAME=value in the prompt (also inserts the A2/B2 marker)

```
#lending-excel-converter Convert 'IntegrationAPITool/artifacts/requirement_doc/PrincipalPayment-V4.xlsx' to reference format and save to the same path. ENTITY_NAME=LoanPrincipalPayment
```

This passes `--entity-name LoanPrincipalPayment` to `convert-excel.mjs`, which both (a) uses it
for the derived class names and (b) triggers the third step, embedding `ENTITY_NAME` at A2 and
`LoanPrincipalPayment` at B2 of every Create/Update/GetByID/Delete sheet.

### Full example — all three source files

```
#lending-excel-converter Convert the following spreadsheets to Upfront Fee reference format and save outputs to 'IntegrationAPITool/artifacts/requirement_doc/converted':
- IntegrationAPITool/artifacts/requirement_doc/InterestPayment-V4.xlsx
- IntegrationAPITool/artifacts/requirement_doc/PrincipalPayment-V4.xlsx
- IntegrationAPITool/artifacts/requirement_doc/LoanInitialDrawndown-V4.xlsx
```

---

## Expected output structure

After conversion, each output file contains only the four operation sheets
in the reference layout:

```
InterestPayment-V4.xlsx (converted)
 ├── Create    — 32-column layout, rows: R/NR legend, metadata, Input section, OUTPUT section
 ├── Update    — 32-column layout (same structure as Create)
 ├── GetById   — 32-column layout (same structure/styles/merges as Create/Update, no title row)
 └── Delete    — 32-column layout (same structure/styles/merges as Create/Update, no title row)
```

---

## Script location

```
.github/skills/lending-excel-converter/scripts/convert-excel.mjs
.github/skills/lending-excel-converter/scripts/format-validation-rules.mjs
.github/skills/lending-excel-converter/scripts/insert-entity-name.mjs
```
