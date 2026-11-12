# HM-Req experiment 3: linked measurement conditions

Date: 2026-11-10

## Change
In a separate copy of HM-Req (Langium ~4.1.0), the `Condition` grammar now accepts either the original quoted condition or a structured `measured SCALE OPERATOR THRESHOLD` condition. The validator walks the condition AST and checks the scale, operator, and threshold against the optional `Measurement:` metadata. The earlier KSS-specific English-text matching code remains for legacy conditions, but the new checks do not depend on it.

## Execution
`langium generate` completed successfully with existing grammar warnings; `tsc -b tsconfig.build.json` completed successfully. `node test_linked.mjs` executed six scenarios:

| Scenario | Parser errors | Custom diagnostics |
|---|---:|---|
| Original DDAW01 | 0 | none |
| Structured KSS >= 8, matching metadata | 0 | none |
| Threshold 8 vs metadata 7 | 0 | threshold mismatch error |
| Operator >= vs metadata > | 0 | operator mismatch error |
| Scale KSS vs metadata OTHER | 0 | scale mismatch error |
| Structured condition without metadata | 0 | missing-definition warning |

## Limitations
- This is a prototype and the validation methods were called directly on the AST, not through full language-server diagnostics.
- The metadata is per requirement, not a reusable, named measurement definition. Multiple measurement conditions per requirement need further design.
- Only a single structured condition and its associated metadata were exercised in this test.
- Scientific measurement equivalence, evidence sufficiency, observation timing, and full 16-case compatibility were not evaluated.
- This does not demonstrate that any requirement is scientifically valid or verifiable with available datasets.
- Do not replace the original HM-Req implementation or revise Paper 2 based on this feasibility result alone.

## Reproduce
From a complete HM-Req workspace with installed dependencies, overlay the included `packages/language/src/req.langium` and `packages/language/src/req-validator.ts`, then run:

```
cd packages/language
npx langium generate
cd ../..
npx tsc -b tsconfig.build.json
node test_linked.mjs
```
