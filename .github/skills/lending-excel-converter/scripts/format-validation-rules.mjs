#!/usr/bin/env node
/**
 * format-validation-rules.mjs
 *
 * Reformats the ATTRIBUTE_DESCRIPTION (and SWAGGER_ATTRIBUTE_DESCRIPTION) cell
 * text for every INPUT-attribute row of a converted (reference-format) LoanIQ
 * requirement spreadsheet, so the free-text "description and validation"
 * content reads as clear, numbered validation rules:
 *
 *   - Every cell — even one containing a single point — is rewritten as a
 *     NUMBERED list within the SAME cell, e.g.:
 *       1. Must not be null.
 *       2. Must be unique within the bank.
 *     Points are split on newlines, bullet markers ("·"/"-"/"*"/"1."/"1)")
 *     and sentence boundaries, then cleaned (redundant "Validation:" labels
 *     stripped, capitalised, terminal punctuation ensured).
 *   - A cell that has NO description text at all is not left blank: a
 *     baseline validation is synthesised from that row's REQUIRED, DATA_TYPE,
 *     "Multiple Values allowed (Y/N)" and "Default Value" columns (e.g.
 *     "1. Optional field; may be left blank.\n2. Must be either Y (true) or
 *     N (false)."), so every input attribute ends up with a proper, numbered
 *     validation rule set.
 *
 * This is a deterministic, rule-based reformatting (no LLM/AI rewriting of
 * wording) — it only splits, cleans, capitalises, punctuates and numbers the
 * text that is already present (or synthesises a baseline rule from column
 * metadata when no text is present at all).
 *
 * This step is run AUTOMATICALLY by convert-excel.mjs at the end of every
 * conversion (after the reference-format sheets have been built, before the
 * workbook is written to disk). It can also be run standalone against an
 * already-converted file:
 *
 *   node format-validation-rules.mjs --source <path> [--output <path>]
 *
 * (When --output is omitted, the source file is overwritten in place.)
 */

import ExcelJS from 'exceljs';

// ─── Section / header helpers (mirrors convert-excel.mjs's own helpers) ──────

/** Locates the Input-header, OUTPUT-marker and Output-header row indices (0-based) by scanning col A. */
function getSectionIndices(ws) {
  let inHdr = -1, outMark = -1, outHdr = -1;
  const rowCount = ws.rowCount;
  for (let r = 1; r <= rowCount; r++) {
    const raw = ws.getCell(r, 1).value;
    const v = String(raw == null ? '' : raw).trim().toLowerCase();
    const i = r - 1;
    if (/^sl[ _]?no\.?$/.test(v)) {
      if (inHdr < 0) inHdr = i;
      else if (outMark >= 0 && outHdr < 0) outHdr = i;
    }
    if (v === 'output') outMark = i;
  }
  return { inHdr, outMark, outHdr };
}

// ─── Text splitting / cleaning ────────────────────────────────────────────────

/** Splits a free-text description into individual candidate validation points. */
function splitValidationPoints(text) {
  let s = String(text == null ? '' : text);
  if (!s.trim()) return [];
  s = s.replace(/\r\n/g, '\n').replace(/\r/g, '\n');

  const points = [];
  for (let line of s.split('\n')) {
    line = line.trim();
    if (!line) continue;
    // Strip leading bullet markers: "·", "-", "*", "1.", "1)", etc.
    line = line.replace(/^[·•\-\*]\s*/, '').replace(/^\d+[.)]\s*/, '').trim();
    if (!line) continue;
    // Split into sentences: break after ".", "?" or "!" when followed by
    // whitespace + a capital letter (avoids breaking on abbreviations like "e.g.").
    const sentenceParts = line.split(/(?<=[.?!])\s+(?=[A-Z])/);
    for (let part of sentenceParts) {
      part = part.trim();
      if (part) points.push(part);
    }
  }
  return points;
}

/** Cleans a single validation-point fragment so it reads as a proper rule sentence. */
function cleanPoint(point) {
  let t = point.trim();
  // Drop a redundant leading "Validation:" / "Validation -" label — every
  // point in this cell is already understood to be a validation rule.
  t = t.replace(/^validation\s*[:\-]\s*/i, '');
  if (!t) return '';
  t = t.charAt(0).toUpperCase() + t.slice(1);
  if (!/[.?!:]$/.test(t)) t += '.';
  return t;
}

/** Reformats one cell's full text into a numbered validation-point list. */
function formatValidationText(text) {
  const points = splitValidationPoints(text).map(cleanPoint).filter(Boolean);
  return numberPoints(points);
}

/** Joins a list of already-cleaned point strings into a numbered list (or '' if empty). */
function numberPoints(points) {
  if (!points.length) return '';
  return points.map((p, i) => `${i + 1}. ${p}`).join('\n');
}

/** Maps a (Java) data type to a baseline validation statement for that type. */
function dataTypeValidationText(dataType) {
  const t = String(dataType || '').trim();
  switch (t) {
    case 'String':        return 'Must be a valid alphanumeric string.';
    case 'Boolean':       return 'Must be either Y (true) or N (false).';
    case 'LocalDate':     return 'Must be a valid date.';
    case 'LocalDateTime': return 'Must be a valid date and time.';
    case 'BigDecimal':    return 'Must be a valid numeric (decimal) value.';
    case 'Integer':       return 'Must be a valid integer value.';
    case 'Long':          return 'Must be a valid numeric value.';
    default:              return '';
  }
}

/** Finds the 1-based column index whose input-header row cell matches the given predicate, or -1. */
function findColByHeader(hdrRow, colCount, predicate) {
  for (let c = 1; c <= colCount; c++) {
    const h = String(hdrRow.getCell(c).value == null ? '' : hdrRow.getCell(c).value).trim();
    if (predicate(h)) return c;
  }
  return -1;
}

/**
 * Synthesises a baseline, numbered validation-rule cell value for a row that
 * has NO description text at all, using whatever of REQUIRED / DATA_TYPE /
 * "Multiple Values allowed (Y/N)" / "Default Value" is available for that row.
 * Returns '' if none of those columns yield a usable rule.
 */
function buildDefaultValidationText(row, cols) {
  const points = [];

  const required = cols.reqCol > 0 ? String(row.getCell(cols.reqCol).value ?? '').trim().toUpperCase() : '';
  if (required === 'Y') points.push('Required to save; must not be null or blank.');
  else if (required === 'N') points.push('Optional field; may be left blank.');

  const dataType = cols.typeCol > 0 ? String(row.getCell(cols.typeCol).value ?? '').trim() : '';
  const typeRule = dataTypeValidationText(dataType);
  if (typeRule) points.push(typeRule);

  const multiVal = cols.multiCol > 0 ? String(row.getCell(cols.multiCol).value ?? '').trim().toUpperCase() : '';
  if (multiVal === 'Y') points.push('Multiple values are allowed for this attribute.');

  const defaultVal = cols.defaultCol > 0 ? String(row.getCell(cols.defaultCol).value ?? '').trim() : '';
  if (defaultVal && defaultVal !== '-1') {
    points.push(/^default value/i.test(defaultVal) ? cleanPoint(defaultVal) : cleanPoint(`Default value is ${defaultVal}`));
  }

  return numberPoints(points);
}

// ─── Worksheet / workbook drivers ─────────────────────────────────────────────

/** Reformats ATTRIBUTE_DESCRIPTION-like columns for every input-attribute data row of one sheet. */
function formatSheetValidations(ws) {
  const idx = getSectionIndices(ws);
  if (idx.inHdr < 0) return 0;

  const hdrRow = ws.getRow(idx.inHdr + 1);
  const N = Math.max(ws.columnCount, hdrRow.cellCount);
  const descCols = [];
  for (let c = 1; c <= N; c++) {
    const h = String(hdrRow.getCell(c).value == null ? '' : hdrRow.getCell(c).value).trim().toUpperCase();
    if (h === 'ATTRIBUTE_DESCRIPTION' || h === 'SWAGGER_ATTRIBUTE_DESCRIPTION') descCols.push(c);
  }
  if (!descCols.length) return 0;

  const cols = {
    reqCol:     findColByHeader(hdrRow, N, h => h.toUpperCase() === 'REQUIRED'),
    typeCol:    findColByHeader(hdrRow, N, h => h.toUpperCase() === 'DATA_TYPE'),
    multiCol:   findColByHeader(hdrRow, N, h => /multiple values allowed/i.test(h)),
    defaultCol: findColByHeader(hdrRow, N, h => /^default value$/i.test(h)),
  };

  const firstDataRow = idx.inHdr + 2; // 1-based
  const lastDataRow  = idx.outMark >= 0 ? idx.outMark : ws.rowCount; // idx.outMark (0-based) === last data row (1-based)
  let changed = 0;

  for (let r = firstDataRow; r <= lastDataRow; r++) {
    const row = ws.getRow(r);
    let synthesized; // computed lazily, at most once per row
    for (const c of descCols) {
      const cell = row.getCell(c);
      const raw = typeof cell.value === 'string' ? cell.value : '';
      let formatted;
      if (raw.trim()) {
        formatted = formatValidationText(raw);
      } else {
        if (synthesized === undefined) synthesized = buildDefaultValidationText(row, cols);
        formatted = synthesized;
      }
      if (formatted && formatted !== cell.value) {
        cell.value = formatted;
        cell.alignment = Object.assign({}, cell.alignment, { wrapText: true });
        changed++;
      }
    }
  }
  return changed;
}

/** Reformats validation text across every sheet (Create/Update/GetByID/Delete) of a workbook. */
export function formatWorkbookValidations(wb) {
  let totalChanged = 0;
  wb.eachSheet(ws => { totalChanged += formatSheetValidations(ws); });
  return totalChanged;
}

// ─── Standalone CLI entry point ───────────────────────────────────────────────

function getArg(name) {
  const i = process.argv.indexOf(`--${name}`);
  return i >= 0 ? process.argv[i + 1] : undefined;
}

async function main() {
  const sourceFile = getArg('source');
  if (!sourceFile) return; // imported as a module — do nothing

  const outputFile = getArg('output') || sourceFile;
  const wb = new ExcelJS.Workbook();
  await wb.xlsx.readFile(sourceFile);
  const changed = formatWorkbookValidations(wb);
  await wb.xlsx.writeFile(outputFile);
  console.log(`✓ Reformatted ${changed} validation cell(s). Written: ${outputFile}`);
}

// Only auto-run when executed directly (not when imported by convert-excel.mjs).
if (process.argv[1] && process.argv[1].endsWith('format-validation-rules.mjs')) {
  main().catch(err => { console.error(err); process.exitCode = 1; });
}
