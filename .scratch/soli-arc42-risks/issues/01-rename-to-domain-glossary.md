# 01 — Rename Session/Participation/share to Spend/Pledge

**What to build:** Bring the codebase's vocabulary in line with `CONTEXT.md`. Everywhere the code currently says "Session" it means a Spend; everywhere it says "Participation" it means a Pledge; "share" language should follow suit (e.g. Share Link). No behavior changes — this is a rename pass, not a feature.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] No occurrences of "Session"/"Participation" remain as domain vocabulary in module names, types, functions, routes, templates, or user-facing copy (infrastructure-only uses, if any, are fine to leave)
- [ ] `gleam build` and `gleam test` pass after the rename
- [ ] `gleam format --check` passes
