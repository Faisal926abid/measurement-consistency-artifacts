# Replication materials: Measurement information in inferred human-state requirements

This package accompanies an exploratory study comparing HM-Req and FRET and evaluating a small measurement-linked extension to HM-Req. **The extension experiment is the main reproduction target.** The 16 requirement encodings and saved FRET outputs are supplied as supporting comparison artifacts.

## Original tools

- **HM-Req:** https://github.com/Ethical-Human-Machine-Interaction/hmreq
- **FRET (Formal Requirements Elicitation Tool):** https://github.com/NASA-SW-VnV/fret

These projects are maintained separately and are not redistributed here. Refer to their repositories for installation and general usage. The extension was developed against an HM-Req Langium workspace; a compatible checkout with installed Node.js dependencies is required. Exact upstream revision and dependency lockfile were not included in these materials.

## Package contents

- `requirements/hmreq/`: 16 study-specific HM-Req `.req` formulations (ADDW01–06, DDAW01–06, NCAP01–04).
- `requirements/fret/fret_16_requirements.json`: corresponding FRET records, including saved semantics where available.
- `requirements/fret/fret_16_summary.csv`: compact FRET record summary.
- `requirements/fret/original_exports/`: original FRET project and variable exports, including additional exploratory entries beyond the 16 comparison cases.
- `extension/packages/language/src/req.langium`: modified HM-Req Langium grammar.
- `extension/packages/language/src/req-validator.ts`: modified HM-Req validator.
- `extension/test_linked.mjs`: six constructed scenarios and the diagnostic test harness.
- `extension/evidence/observed_diagnostics.csv`: recorded outcomes.
- `extension/evidence/actual_cli_output.png`: screenshot of observed command-line output.
- `extension/EXPERIMENT_3_REPORT.md`: experimental notes and scope limitations.
- `comparison/`: illustrative DDAW01 HM-Req and FRET screenshots.

## Reproduce the measurement-linked extension experiment

The following steps assume a compatible **original HM-Req workspace** has already been obtained and its dependencies installed. They are **not** general installation instructions for HM-Req or FRET.

1. Make a separate copy of the original HM-Req workspace. In its workspace root, locate `packages/language/src/` and `packages/language/out/` (the latter is created by the build).
2. Back up the original `packages/language/src/req.langium` and `packages/language/src/req-validator.ts`.
3. Copy this package's `extension/packages/language/src/req.langium` and `extension/packages/language/src/req-validator.ts` over the corresponding files in the copied HM-Req workspace.
4. Copy `extension/test_linked.mjs` to the **root of the HM-Req workspace**, at the same level as the `packages/` directory. Do not run it directly from this ZIP's `extension/` folder: its imports expect the built workspace at `./packages/language/out/`.
5. In a terminal in the HM-Req workspace, generate the parser and build the language package:

   ```bash
   cd packages/language
   npx langium generate
   cd ../..
   npx tsc -b tsconfig.build.json
   node test_linked.mjs
   ```

6. Compare the six JSON output lines against `extension/evidence/observed_diagnostics.csv` and the command-line screenshot.

### Expected output summary

| Scenario | Parser errors | Validation diagnostics |
|---|---:|---|
| `original` | 0 | None |
| `linked_valid` | 0 | None |
| `linked_threshold_mismatch` | 0 | Error: threshold 8 versus 7 |
| `linked_operator_mismatch` | 0 | Error: operator `>=` versus `>` |
| `linked_scale_mismatch` | 0 | Error: scale KSS versus OTHER |
| `linked_missing_metadata` | 0 | Warning: missing measurement definition |

**What the test demonstrates:** The modified grammar parses all six constructed inputs; the validator compares structured measurement scale, operator, and threshold against linked metadata and reports selected mismatches. The test harness calls validator methods directly on parsed syntax trees. It does **not** test the complete editor/language-server workflow, measurement accuracy, equivalence of scales, or full regulatory compliance. The linked metadata is local to a requirement rather than a reusable external definition.

**Reproduction status:** The original command-line output is recorded, but this distribution has not been independently rebuilt and rerun from a clean HM-Req checkout. Compatibility may depend on the upstream revision and installed dependencies. This archive is a source overlay, not a standalone runnable application.

## Comparison artifacts

The 16 HM-Req encodings and corresponding FRET records are provided to make the comparison inspectable. FRET generated semantics are saved for 14 cases. ADDW05 and ADDW06 are permission-formulation cases with no generated semantics. The FRET JSON export also contains extra experimental entries, retained as original records for traceability. No claim is made that the saved exports alone reproduce the entire comparative study.

## Data availability and citation

When a public or anonymous review repository is established, use its verified URL in the paper's Data Availability Statement. Until then, do not claim that the archive is already hosted publicly. The underlying regulatory and assessment documents should be cited through their original sources; this archive contains study encodings, not authoritative legal text.

## Scope

The six extension scenarios were constructed around one driver-drowsiness requirement. Their observed outcomes are evidence of selected internal consistency checks, not a comprehensive evaluation of measurement semantics or verification feasibility.
