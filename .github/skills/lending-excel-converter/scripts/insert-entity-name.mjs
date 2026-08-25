#!/usr/bin/env node
/**
 * insert-entity-name.mjs
 *
 * Inserts a literal ENTITY_NAME marker pair into an already-converted
 * (reference-format) LoanIQ requirement spreadsheet: cell A2 is set to the
 * literal string "ENTITY_NAME" and cell B2 is set to the supplied entity
 * value. This is done for every Create / Update / GetByID / Delete worksheet
 * present in the workbook.
 *
 * This is the THIRD and FINAL step of the conversion pipeline:
 *   1) convert-excel.mjs          — rebuilds sheets in reference format
 *   2) format-validation-rules.mjs — reformats validation text into numbered points
 *   3) insert-entity-name.mjs      — (this script) embeds ENTITY_NAME/<value> at A2/B2
 *
 * This step is OPTIONAL and is only run when an explicit entity name is
 * supplied — i.e. when the invoking prompt literally specifies "ENTITY_NAME"
 * and its corresponding value. It is auto-chained by convert-excel.mjs
 * whenever --entity-name is passed on the command line. It can also be run
 * standalone against an already-converted file:
 *
 *   node insert-entity-name.mjs --source <path> --entity-name <value> [--output <path>]
 *
 * (When --output is omitted, the source file is overwritten in place.)
 */

import ExcelJS from 'exceljs';

const SHEET_TARGETS = ['create', 'update', 'getbyid', 'delete'];

/**
 * If the cell at (row, col) is part of a merged range, un-merges that range
 * so the cell (and its neighbours) can hold independent values again.
 */
function unmergeIfMerged(ws, row, col) {
  const cell = ws.getCell(row, col);
  if (!cell.isMerged) return;
  const masterAddress = cell.master.address;
  const merges = (ws.model.merges || []).slice();
  for (const m of merges) {
    if (m.startsWith(masterAddress + ':')) {
      ws.unMergeCells(m);
      return;
    }
  }
}

/**
 * Sets A2 = 'ENTITY_NAME' and B2 = entityName on every Create/Update/GetByID/
 * Delete worksheet of a workbook. Returns the number of sheets updated.
 */
export function insertEntityNameMarker(wb, entityName) {
  let changed = 0;
  wb.eachSheet(ws => {
    if (!SHEET_TARGETS.includes(ws.name.toLowerCase())) return;
    // Some sheets (GetById, Delete) have A2 merged across several columns
    // (e.g. a "Prerequisites" banner row) — un-merge it first so A2 and B2
    // can hold independent values instead of both being redirected to the
    // same merged master cell.
    unmergeIfMerged(ws, 2, 1);
    ws.getCell(2, 1).value = 'ENTITY_NAME';
    ws.getCell(2, 2).value = entityName;
    changed++;
  });
  return changed;
}

// ─── Standalone CLI entry point ───────────────────────────────────────────────

function getArg(name) {
  const i = process.argv.indexOf(`--${name}`);
  return i >= 0 ? process.argv[i + 1] : undefined;
}

async function main() {
  const sourceFile = getArg('source');
  const entityName = getArg('entity-name');
  if (!sourceFile || !entityName) {
    console.error('Usage: node insert-entity-name.mjs --source <path> --entity-name <value> [--output <path>]');
    process.exitCode = 1;
    return;
  }

  const outputFile = getArg('output') || sourceFile;
  const wb = new ExcelJS.Workbook();
  await wb.xlsx.readFile(sourceFile);
  const changed = insertEntityNameMarker(wb, entityName);
  await wb.xlsx.writeFile(outputFile);
  console.log(`✓ Inserted ENTITY_NAME='${entityName}' at A2/B2 in ${changed} sheet(s). Written: ${outputFile}`);
}

// Only auto-run when executed directly (not when imported by convert-excel.mjs).
if (process.argv[1] && process.argv[1].endsWith('insert-entity-name.mjs')) {
  main().catch(err => { console.error(err); process.exitCode = 1; });
}
