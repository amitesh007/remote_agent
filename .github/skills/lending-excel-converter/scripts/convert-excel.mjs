#!/usr/bin/env node
/**
 * convert-excel.mjs
 *
 * Converts LoanIQ API requirement spreadsheets from the V4 template format
 * (e.g. InterestPayment-V4.xlsx) into the EXACT visual format of the reference
 * file (default: the bundled ".github/skills/lending-excel-converter/template/UpfrontFee.xlsx").
 *
 * The reference workbook is loaded at run time using ExcelJS (which — unlike
 * the free "xlsx"/SheetJS package — fully supports both reading AND writing
 * cell styles: fill colour, font, border and alignment). Every non-data row
 * (legends, Prerequisites, metadata, Input/OUTPUT markers, column headers,
 * trailing blank rows) is cloned verbatim — value + full style — straight
 * from the reference file. Only the data rows are regenerated, reusing the
 * exact style of the reference's own first sample data row for every column.
 * This guarantees the output is visually identical to the reference.
 *
 * Source workbooks are parsed with the lightweight "xlsx" package (values
 * only — no style handling needed on the source side).
 *
 * Processed sheets: Create, Update, GetByID, Delete.
 * Any sheet absent from the source file is silently skipped.
 *
 * By default, converted files are written to the SAME DIRECTORY as their
 * source file(s). Pass --output / --output-dir to write elsewhere.
 *
 * After every sheet is rebuilt, this script automatically chains two further
 * steps on the in-memory workbook before writing it to disk:
 *   2) format-validation-rules.mjs — reformats ATTRIBUTE_DESCRIPTION text into
 *      clean, numbered validation points (always runs).
 *   3) insert-entity-name.mjs — embeds a literal ENTITY_NAME marker at A2/B2
 *      of every sheet (Create/Update/GetByID/Delete). Only runs when
 *      --entity-name was explicitly supplied on the command line (i.e. the
 *      invoking prompt itself specified "ENTITY_NAME" and its value).
 *
 * Usage:
 *   node convert-excel.mjs --source <path> [--output <path>] [--output-dir <dir>] [--reference <path>] [--entity-name <name>]
 *   node convert-excel.mjs --source-dir <dir> [--output-dir <dir>] [--reference <path>] [--entity-name <name>]
 *
 * Dependencies:  xlsx  (npm install xlsx),  exceljs  (npm install exceljs)
 */

import XLSX from 'xlsx';
import ExcelJS from 'exceljs';
import { existsSync, mkdirSync, readdirSync } from 'fs';
import { dirname, basename, join, extname } from 'path';
import { fileURLToPath } from 'url';
import { formatWorkbookValidations } from './format-validation-rules.mjs';
import { insertEntityNameMarker } from './insert-entity-name.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const DEFAULT_REFERENCE_PATH = join(__dirname, '..', 'template', 'UpfrontFee.xlsx');

// ─── CLI argument parsing ─────────────────────────────────────────────────────

const args = process.argv.slice(2);
function getArg(name) {
  const idx = args.indexOf('--' + name);
  return idx >= 0 ? args[idx + 1] || '' : null;
}

const sourceFile = getArg('source');
const sourceDir  = getArg('source-dir');
const outputFile = getArg('output');
const outputDir  = getArg('output-dir'); // if omitted, defaults to the source file's own directory
const referencePath = getArg('reference') || DEFAULT_REFERENCE_PATH;
const entityNameOverride = getArg('entity-name'); // optional — forces the entity name instead of auto-detecting it

if (!sourceFile && !sourceDir) {
  console.error('Usage:');
  console.error('  node convert-excel.mjs --source <file> [--output <file>] [--output-dir <dir>] [--reference <path>] [--entity-name <name>]');
  console.error('  node convert-excel.mjs --source-dir <dir> [--output-dir <dir>] [--reference <path>] [--entity-name <name>]');
  process.exit(1);
}

// ─── Java type mapping ────────────────────────────────────────────────────────

const JAVA_TYPE_MAP = {
  alphanumeric: 'String',
  numeric:      'BigDecimal',
  number:       'BigDecimal',
  boolean:      'Boolean',
  date:         'LocalDate',
  'date/time':  'LocalDateTime',
  datetime:     'LocalDateTime',
  enum:         'String',
  integer:      'Integer',
  int:          'Integer',
  long:         'Long',
  float:        'Float',
  double:       'Double',
};

function toJavaType(srcType) {
  const key = String(srcType || '').toLowerCase().trim();
  return JAVA_TYPE_MAP[key] || srcType;
}

// ─── Reference workbook loader (cached, ExcelJS — full style support) ─────────

let _refWb = null;
const _refColCounts = {};
async function loadReference() {
  if (_refWb) return _refWb;
  if (!existsSync(referencePath)) {
    console.error(`Reference workbook not found: ${referencePath}`);
    console.error('Pass --reference <path> to point at the Upfront Fee v2.1.xlsx file.');
    process.exit(1);
  }
  const wb = new ExcelJS.Workbook();
  await wb.xlsx.readFile(referencePath);
  // Capture each sheet's true column width BEFORE sanitizing — flattening
  // formula cells to plain values can shrink ws.columnCount if the sheet's
  // trailing columns only ever held styling (no explicit values).
  wb.eachSheet(ws => { _refColCounts[ws.name] = ws.columnCount; });
  sanitizeWorkbook(wb);
  _refWb = wb;
  return _refWb;
}

/**
 * The reference workbook uses legacy single-cell "array formulas" (CSE-entered,
 * e.g. an auto-incrementing SL_NO column). ExcelJS tracks these internally and,
 * if left untouched, re-materialises them at their ORIGINAL address when a
 * differently-shaped worksheet is written later — producing phantom extra rows
 * in the output. Flattening every formula cell to its plain computed value
 * immediately after load prevents that leakage.
 */
function sanitizeWorkbook(wb) {
  wb.eachSheet(ws => {
    ws.eachRow({ includeEmpty: false }, row => {
      row.eachCell({ includeEmpty: false }, cell => {
        const flat = plainValue(cell.value);
        if (flat !== cell.value) cell.value = flat;
      });
    });
  });
}

// ─── ExcelJS helpers ───────────────────────────────────────────────────────────

/** Decodes "A3" style address into 0-based {row0, col0}. */
function decodeAddr(addr) {
  const m = addr.match(/^\$?([A-Z]+)\$?(\d+)$/);
  let col = 0;
  for (const ch of m[1]) col = col * 26 + (ch.charCodeAt(0) - 64);
  return { row0: parseInt(m[2], 10) - 1, col0: col - 1 };
}

function cloneStyle(cell) {
  return JSON.parse(JSON.stringify(cell.style || {}));
}

/**
 * Resolves a cell's raw value down to a plain scalar. The reference workbook
 * uses legacy single-cell "array formulas" (e.g. an auto-incrementing SL_NO
 * column) — cloning the formula object itself (instead of its computed
 * result) confuses ExcelJS's writer into emitting phantom extra rows. Since
 * the converted output is a static spreadsheet (not a live template), always
 * flatten formulas to their last computed result.
 */
function plainValue(v) {
  if (v && typeof v === 'object' && !(v instanceof Date)) {
    if ('result' in v) return v.result ?? '';
    if ('richText' in v) return v.richText.map(rt => rt.text).join('');
  }
  return v;
}

/** Copies a whole row (value + style) verbatim from a reference row to a target row. */
function copyRowVerbatim(srcRow, dstRow, N) {
  dstRow.height = srcRow.height;
  for (let c = 1; c <= N; c++) {
    const srcCell = srcRow.getCell(c);
    const dstCell = dstRow.getCell(c);
    dstCell.value = plainValue(srcCell.value);
    dstCell.style = cloneStyle(srcCell);
  }
}

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

/** Returns the (0-based) index of the last row — from startIdx0 to rowCount-1 — whose col A is numeric. */
function lastNumericRow(ws, startIdx0, maxIdx0) {
  let last = startIdx0 - 1;
  for (let r0 = startIdx0; r0 <= maxIdx0; r0++) {
    const raw = ws.getCell(r0 + 1, 1).value;
    if (raw !== '' && raw != null && !isNaN(Number(raw))) last = r0;
  }
  return last;
}

// ─── Source sheet parser (values only — via the lightweight "xlsx" package) ───

function buildColMap(hdr) {
  const m = {};
  hdr.forEach((raw, i) => {
    const s = String(raw || '').toLowerCase().trim().replace(/\s+/g, ' ');
    if (m.slNo       === undefined && /^sl[ _]?no\.?$/.test(s))                           m.slNo       = i;
    if (m.attrCat    === undefined && /^(attribute category|class(_name)?)$/.test(s))     m.attrCat    = i;
    if (m.isList     === undefined && s.includes('multiple instances'))                    m.isList     = i;
    if (m.fieldName  === undefined && /attri?ute field name|attribute_field_name/.test(s)) m.fieldName  = i;
    if (m.dataType   === undefined && /^data[ _]?type$/.test(s))                           m.dataType   = i;
    if (m.required   === undefined && s.includes('required') &&
        !s.includes('attribute') && !s.includes('category') &&
        !s.includes('multiple')  && !s.includes('translation'))                            m.required   = i;
    if (m.description=== undefined && (s.includes('description') || s.includes('validation'))
        && !s.includes('swagger'))                                                          m.description= i;
    if (m.updatable  === undefined && s.includes('updatable'))                             m.updatable  = i;
    if (m.multiVal   === undefined && s.includes('multiple values'))                       m.multiVal   = i;
    if (m.transReq   === undefined && s.includes('translation required'))                  m.transReq   = i;
    if (m.transLogic === undefined && s.includes('translation logic'))                     m.transLogic = i;
    if (m.codeTable  === undefined && /^code[ _]?table$/.test(s))                          m.codeTable  = i;
    if (m.soapApi    === undefined && (s.includes('soap api') || s.includes('in_soap_api')
        || s.includes('existing in soap')))                                                 m.soapApi    = i;
    if (m.defaultVal === undefined && s === 'default value')                               m.defaultVal = i;
  });
  return m;
}

function findSourceSectionIndices(rows) {
  let inHdr = -1, outMark = -1, outHdr = -1;
  for (let i = 0; i < rows.length; i++) {
    const v = String(rows[i][0] || '').trim().toLowerCase();
    if (/^sl[ _]?no\.?$/.test(v)) {
      if (inHdr < 0) inHdr = i;
      else if (outMark >= 0 && outHdr < 0) outHdr = i;
    }
    if (v === 'output') outMark = i;
  }
  return { inHdr, outMark, outHdr };
}

function parseSourceSheet(rows) {
  const res = { title: String(rows[0]?.[0] || ''), entityValue: '',
                inMap: {}, inRows: [], outMap: {}, outRows: [] };
  for (const r of rows.slice(0, 10))
    if (String(r[0] || '').trim() === 'ENTITY_NAME') { res.entityValue = String(r[1] || '').trim(); break; }

  const idx = findSourceSectionIndices(rows);
  if (idx.inHdr >= 0) {
    res.inMap = buildColMap(rows[idx.inHdr]);
    const end = idx.outMark >= 0 ? idx.outMark : rows.length;
    for (let i = idx.inHdr + 1; i < end; i++) {
      const v = rows[i][0];
      if (v !== '' && v != null && !isNaN(Number(v))) res.inRows.push(rows[i]);
    }
  }
  if (idx.outHdr >= 0) {
    res.outMap = buildColMap(rows[idx.outHdr]);
    for (let i = idx.outHdr + 1; i < rows.length; i++) {
      const v = rows[i][0];
      if (v !== '' && v != null && !isNaN(Number(v))) res.outRows.push(rows[i]);
    }
  }
  return res;
}

// ─── Template-cloning sheet builder (ExcelJS) ─────────────────────────────────

function buildFromTemplate(refWb, sheetName, outSheetName, newWb, parsed, opts) {
  const { metaOverrides = {}, titleOverride, mapInputRow, mapOutputRow } = opts;

  const refWs = refWb.getWorksheet(sheetName);
  if (!refWs) throw new Error(`Reference workbook has no sheet "${sheetName}"`);
  const N = _refColCounts[sheetName] || refWs.columnCount;
  const totalRows = refWs.rowCount;

  const idx = getSectionIndices(refWs);
  if (idx.inHdr < 0 || idx.outMark < 0 || idx.outHdr < 0) {
    throw new Error(`Could not locate Input/Output sections in reference sheet "${sheetName}"`);
  }
  const lastOutRow = lastNumericRow(refWs, idx.outHdr + 1, totalRows - 1);

  const newWs = newWb.addWorksheet(outSheetName);
  for (let c = 1; c <= N; c++) {
    const w = refWs.getColumn(c).width;
    if (w) newWs.getColumn(c).width = w;
  }

  let curRow = 0;

  // 1. Rows [0..inHdr] verbatim, with metadata/title overrides.
  for (let r0 = 0; r0 <= idx.inHdr; r0++) {
    curRow++;
    const srcRow = refWs.getRow(r0 + 1);
    const dstRow = newWs.getRow(curRow);
    copyRowVerbatim(srcRow, dstRow, N);
    if (r0 === 0 && titleOverride) dstRow.getCell(1).value = titleOverride;
    const label = String(dstRow.getCell(1).value || '').trim().toLowerCase();
    if (metaOverrides[label] !== undefined) dstRow.getCell(2).value = metaOverrides[label];
  }

  // 2. New input data rows — style cloned from the reference's own first sample row.
  const inTemplateRow0 = (idx.outMark > idx.inHdr + 1) ? idx.inHdr + 1 : idx.inHdr;
  const tmplInRow = refWs.getRow(inTemplateRow0 + 1);
  for (const srcRow of parsed.inRows) {
    curRow++;
    const values = mapInputRow(srcRow, parsed.inMap);
    const dstRow = newWs.getRow(curRow);
    dstRow.height = tmplInRow.height;
    for (let c = 1; c <= N; c++) {
      const tmplCell = tmplInRow.getCell(c);
      const dstCell = dstRow.getCell(c);
      dstCell.style = cloneStyle(tmplCell);
      const v = values[c - 1];
      dstCell.value = v === undefined ? plainValue(tmplCell.value) : v;
    }
  }

  // 3. OUTPUT marker row + output header row — verbatim.
  for (let r0 = idx.outMark; r0 <= idx.outHdr; r0++) {
    curRow++;
    const srcRow = refWs.getRow(r0 + 1);
    const dstRow = newWs.getRow(curRow);
    copyRowVerbatim(srcRow, dstRow, N);
  }

  // 4. New output data rows.
  const outTemplateRow0 = (lastOutRow >= idx.outHdr + 1) ? idx.outHdr + 1 : idx.outHdr;
  const tmplOutRow = refWs.getRow(outTemplateRow0 + 1);
  for (const srcRow of parsed.outRows) {
    curRow++;
    const values = mapOutputRow(srcRow, parsed.outMap);
    const dstRow = newWs.getRow(curRow);
    dstRow.height = tmplOutRow.height;
    for (let c = 1; c <= N; c++) {
      const tmplCell = tmplOutRow.getCell(c);
      const dstCell = dstRow.getCell(c);
      dstCell.style = cloneStyle(tmplCell);
      const v = values[c - 1];
      dstCell.value = v === undefined ? plainValue(tmplCell.value) : v;
    }
  }

  // 5. Trailing (blank/formatting) rows — verbatim.
  for (let r0 = lastOutRow + 1; r0 < totalRows; r0++) {
    curRow++;
    const srcRow = refWs.getRow(r0 + 1);
    const dstRow = newWs.getRow(curRow);
    copyRowVerbatim(srcRow, dstRow, N);
  }

  // 6. Merges: keep only full-width label merges (Prerequisites/Input/OUTPUT), row-shifted.
  const delta1 = parsed.inRows.length - (idx.outMark - idx.inHdr - 1);
  const delta2 = parsed.outRows.length - (lastOutRow - idx.outHdr);
  const mapRow0 = (orig0) => {
    if (orig0 <= idx.inHdr) return orig0;
    if (orig0 > idx.inHdr && orig0 < idx.outMark) return null;
    if (orig0 >= idx.outMark && orig0 <= idx.outHdr) return orig0 + delta1;
    if (orig0 > idx.outHdr && orig0 <= lastOutRow) return null;
    return orig0 + delta1 + delta2;
  };
  for (const rangeStr of (refWs.model.merges || [])) {
    const [startAddr, endAddr] = rangeStr.split(':');
    const s = decodeAddr(startAddr), e = decodeAddr(endAddr);
    if (s.col0 !== 0) continue; // drop merges that lived inside the reference's own sample data
    const ns = mapRow0(s.row0), ne = mapRow0(e.row0);
    if (ns == null || ne == null) continue;
    newWs.mergeCells(ns + 1, s.col0 + 1, ne + 1, e.col0 + 1);
  }

  return newWs;
}

// ─── Per-sheet column-mapping rules (source columns → reference columns) ──────

function buildCreateSheet(refWb, newWb, parsed, entity) {
  const className = `Create${entity}Integration`;
  return buildFromTemplate(refWb, 'Create', 'Create', newWb, parsed, {
    metaOverrides: {
      'integration_class': `LiqAPICreate${entity}Integration`,
      'response_class':    `LiqAPI${entity}IntegrationAsReturnValue`,
    },
    mapInputRow: (row, cm) => {
      const g = (k, fb) => row[cm[k] ?? fb] ?? '';
      return {
        0: row[0] ?? '', 1: className,
        2: g('attrCat', 1), 3: g('attrCat', 1), 4: g('isList', 2),
        14: g('fieldName', 5), 15: g('fieldName', 5),
        16: toJavaType(g('dataType', 6)), 17: g('required', 7),
        18: g('description', 8), 19: g('description', 8),
        20: 'N', 21: g('soapApi', 14), 22: -1, 23: -1,
        24: g('defaultVal', -1) || '', 25: g('multiVal', 10),
        26: g('transReq', 11), 27: g('transLogic', 12), 28: g('codeTable', 13),
      };
    },
    mapOutputRow: (row, cm) => {
      const g = (k, fb) => row[cm[k] ?? fb] ?? '';
      const respClass = `LiqAPI${entity}IntegrationAsReturnValue`;
      return {
        0: row[0] ?? '', 1: g('attrCat', 1) || respClass,
        14: g('fieldName', 4), 15: g('dataType', 5),
        16: toJavaType(g('dataType', 5)), 17: g('required', 6),
        18: g('description', 8), 19: g('description', 8),
        22: -1, 23: -1, 25: g('multiVal', 7), 26: g('transReq', 9),
      };
    },
  });
}

function buildUpdateSheet(refWb, newWb, parsed, entity) {
  const className = `Update${entity}Integration`;
  return buildFromTemplate(refWb, 'Update', 'Update', newWb, parsed, {
    metaOverrides: {
      'integration_class': `LiqAPIUpdate${entity}Integration`,
      'response_class':    `LiqAPI${entity}IntegrationAsReturnValue`,
    },
    mapInputRow: (row, cm) => {
      const g = (k, fb) => row[cm[k] ?? fb] ?? '';
      return {
        0: row[0] ?? '', 1: className,
        2: g('attrCat', 1), 3: g('attrCat', 1), 4: g('isList', 2),
        14: g('fieldName', 4), 15: g('fieldName', 4),
        16: toJavaType(g('dataType', 5)), 17: g('required', 6),
        18: g('description', 7), 19: g('description', 7),
        20: g('updatable', 8) || '', 21: g('soapApi', 14), 22: -1, 23: -1,
        24: g('defaultVal', -1) || '', 25: g('multiVal', 10),
        26: g('transReq', 11), 27: g('transLogic', 12), 28: g('codeTable', 13),
      };
    },
    mapOutputRow: (row, cm) => {
      const g = (k, fb) => row[cm[k] ?? fb] ?? '';
      const respClass = `LiqAPI${entity}IntegrationAsReturnValue`;
      return {
        0: row[0] ?? '', 1: g('attrCat', 1) || respClass,
        14: g('fieldName', 4), 15: g('dataType', 5),
        16: toJavaType(g('dataType', 5)), 17: g('required', 6),
        18: g('description', 7), 19: g('description', 7),
        22: -1, 23: -1, 25: g('multiVal', 8), 26: g('transReq', 9),
      };
    },
  });
}

function buildGetByIdSheet(refWb, newWb, parsed, entity) {
  const className = `Get${entity}Integration`;
  const respClass = `LiqAPI${entity}IntegrationAsReturnValue`;
  // GetById now shares the EXACT same 32-column reference layout as Create/Update
  // (R/NR legend, Prerequisites, PCP/FILE_OP_PATH metadata, Input/OUTPUT banners) —
  // no free-text title row anymore, so no titleOverride is passed.
  return buildFromTemplate(refWb, 'GetById', 'GetById', newWb, parsed, {
    metaOverrides: {
      'integration_class': `LiqAPI${entity}QueryIntegration`,
      'response_class':    respClass,
    },
    mapInputRow: (row, cm) => {
      const g = (k, fb) => row[cm[k] ?? fb] ?? '';
      return {
        0: row[0] ?? '', 1: className,
        2: g('attrCat', 1), 3: g('attrCat', 1),
        14: g('fieldName', 4), 15: g('fieldName', 4),
        16: toJavaType(g('dataType', 5)), 17: g('required', 6),
        18: g('description', 7), 19: g('description', 7),
        20: 'N', 21: g('soapApi', 9) || 'N', 22: -1, 23: -1,
        24: g('defaultVal', -1) || '', 25: g('multiVal', 12),
        26: g('transReq', 13), 27: g('transLogic', 14), 28: g('codeTable', 15),
      };
    },
    mapOutputRow: (row, cm) => {
      const g = (k, fb) => row[cm[k] ?? fb] ?? '';
      return {
        0: row[0] ?? '', 1: g('attrCat', 1) || respClass,
        14: g('fieldName', 4), 15: g('fieldName', 4),
        16: toJavaType(g('dataType', 5)), 17: g('required', 6),
        18: g('description', 7), 19: g('description', 7),
        22: -1, 23: -1, 25: g('multiVal', 8), 26: g('transReq', 12),
      };
    },
  });
}

function buildDeleteSheet(refWb, newWb, parsed, entity) {
  const className = `Delete${entity}Integration`;
  const respClass = `LiqAPI${entity}IntegrationAsReturnValue`;
  // Delete now shares the EXACT same 32-column reference layout as Create/Update —
  // no free-text title row anymore, so no titleOverride is passed.
  return buildFromTemplate(refWb, 'Delete', 'Delete', newWb, parsed, {
    metaOverrides: {
      'integration_class': `LiqAPI${entity}DeleteIntegration`,
      'response_class':    respClass,
    },
    mapInputRow: (row, cm) => {
      const g = (k, fb) => row[cm[k] ?? fb] ?? '';
      return {
        0: row[0] ?? '', 1: className,
        2: g('attrCat', 1), 3: g('attrCat', 1),
        14: g('fieldName', 3), 15: g('fieldName', 3),
        16: toJavaType(g('dataType', 4)), 17: g('required', 5),
        18: g('description', 6), 19: g('description', 6),
        20: 'N', 21: g('soapApi', 8) || 'N', 22: -1, 23: -1,
        24: g('defaultVal', -1) || '', 25: g('multiVal', 11),
        26: g('transReq', 12), 27: g('transLogic', 13), 28: g('codeTable', 14),
      };
    },
    mapOutputRow: (row, cm) => {
      const g = (k, fb) => row[cm[k] ?? fb] ?? '';
      return {
        0: row[0] ?? '', 1: g('attrCat', 1) || respClass,
        14: g('fieldName', 3), 15: g('fieldName', 3),
        16: toJavaType(g('dataType', 6)), 17: g('required', 7),
        18: g('description', 8), 19: g('description', 8),
        22: -1, 23: -1, 26: g('transReq', 10),
      };
    },
  });
}

// ─── Main conversion ──────────────────────────────────────────────────────────

async function convertFile(sourcePath, targetPath, entityNameOverride) {
  console.log(`\nConverting: ${sourcePath}`);
  console.log(`       →  : ${targetPath}`);

  const refWb = await loadReference();
  const wb    = XLSX.readFile(sourcePath);
  const newWb = new ExcelJS.Workbook();

  // 1) Explicit CLI override always wins.
  let entityValue = String(entityNameOverride || '').trim();

  // 2) Detect entity value from a raw ENTITY_NAME row (present in original V4 source files).
  if (!entityValue) {
    for (const t of ['Create', 'Update', 'GetByID', 'Delete']) {
      const sn = wb.SheetNames.find(s => s.toLowerCase() === t.toLowerCase());
      if (!sn) continue;
      const rows = XLSX.utils.sheet_to_json(wb.Sheets[sn], { header: 1, defval: '' });
      for (const row of rows.slice(0, 10))
        if (String(row[0] || '').trim() === 'ENTITY_NAME') { entityValue = String(row[1] || '').trim(); break; }
      if (entityValue) break;
    }
  }

  // 3) Fall back to extracting the entity name from an existing INTEGRATION_CLASS
  //    metadata row (present when re-converting an already-converted file, which
  //    no longer has a raw ENTITY_NAME row). E.g.
  //    "LiqAPICreateLoanPrincipalPaymentIntegration" -> "LoanPrincipalPayment".
  if (!entityValue) {
    for (const t of ['Create', 'Update', 'GetByID', 'Delete']) {
      const sn = wb.SheetNames.find(s => s.toLowerCase() === t.toLowerCase());
      if (!sn) continue;
      const rows = XLSX.utils.sheet_to_json(wb.Sheets[sn], { header: 1, defval: '' });
      for (const row of rows.slice(0, 10)) {
        if (String(row[0] || '').trim() !== 'INTEGRATION_CLASS') continue;
        const raw = String(row[1] || '').trim();
        const m = raw.match(/^LiqAPI(?:Create|Update)?(.+?)(?:Query|Delete)?Integration$/);
        if (m && m[1]) { entityValue = m[1]; break; }
      }
      if (entityValue) break;
    }
    if (entityValue) console.log(`  (Entity name recovered from existing INTEGRATION_CLASS metadata)`);
  }

  // 4) Last resort: derive from the filename.
  if (!entityValue) {
    entityValue = basename(sourcePath, extname(sourcePath)).replace(/-V\d+(\.\d+)?$/, '');
    console.warn(`  WARNING: ENTITY_NAME not found — using "${entityValue}"`);
  }
  console.log(`  Entity: ${entityValue}`);

  let convertedAny = false;
  for (const target of ['Create', 'Update', 'GetByID', 'Delete']) {
    const srcName = wb.SheetNames.find(s => s.toLowerCase() === target.toLowerCase());
    if (!srcName) { console.log(`  Sheet '${target}': not present — skipping`); continue; }

    console.log(`  Sheet '${target}': converting...`);
    const srcRows = XLSX.utils.sheet_to_json(wb.Sheets[srcName], { header: 1, defval: '' });
    const parsed  = parseSourceSheet(srcRows);

    switch (target) {
      case 'Create':  buildCreateSheet (refWb, newWb, parsed, entityValue); break;
      case 'Update':  buildUpdateSheet (refWb, newWb, parsed, entityValue); break;
      case 'GetByID': buildGetByIdSheet(refWb, newWb, parsed, entityValue); break;
      case 'Delete':  buildDeleteSheet (refWb, newWb, parsed, entityValue); break;
    }
    convertedAny = true;
    console.log(`    ${parsed.inRows.length} input row(s), ${parsed.outRows.length} output row(s)`);
  }

  if (!convertedAny) { console.warn('  WARNING: no sheets converted'); return; }

  const changedValidations = formatWorkbookValidations(newWb);
  console.log(`  Reformatted ${changedValidations} validation cell(s) into numbered rule points`);

  // Third step: only when the invocation explicitly supplied an entity name
  // (i.e. the prompt contained "ENTITY_NAME" and its corresponding value via
  // --entity-name), embed it at A2/B2 of every sheet for future detection.
  if (entityNameOverride) {
    const markedSheets = insertEntityNameMarker(newWb, entityValue);
    console.log(`  Inserted ENTITY_NAME='${entityValue}' at A2/B2 in ${markedSheets} sheet(s)`);
  }

  const outDir = dirname(targetPath);
  if (!existsSync(outDir)) mkdirSync(outDir, { recursive: true });

  await newWb.xlsx.writeFile(targetPath);
  console.log(`  ✓ Written: ${targetPath}`);
}

// ─── Entry point ──────────────────────────────────────────────────────────────

if (sourceFile) {
  // Default: write alongside the source file (same directory) unless
  // --output or --output-dir was explicitly provided.
  const targetPath = outputFile || join(outputDir || dirname(sourceFile), basename(sourceFile));
  await convertFile(sourceFile, targetPath, entityNameOverride);
} else {
  if (!existsSync(sourceDir)) { console.error(`Source dir not found: ${sourceDir}`); process.exit(1); }
  const files = readdirSync(sourceDir).filter(f => f.toLowerCase().endsWith('.xlsx') && !f.startsWith('done_')).sort();
  if (!files.length) { console.log('No .xlsx files found'); process.exit(0); }
  console.log(`Found ${files.length} file(s) to convert.`);
  // Default: write each converted file alongside its source (in sourceDir itself)
  // unless --output-dir was explicitly provided.
  const targetDir = outputDir || sourceDir;
  for (const f of files) await convertFile(join(sourceDir, f), join(targetDir, f), entityNameOverride);
  console.log('\nDone.');
}
