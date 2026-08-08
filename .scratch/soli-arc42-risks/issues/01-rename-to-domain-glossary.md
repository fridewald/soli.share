# 01 — Rename Session/Participation/share to Spend/Pledge

**What to build:** Bring the codebase's vocabulary in line with `CONTEXT.md`. Everywhere the code currently says "Session" it means a Spend; everywhere it says "Participation" it means a Pledge; "share" language should follow suit (e.g. Share Link). No behavior changes — this is a rename pass, not a feature.

**Blocked by:** None — can start immediately.

**Status:** done

- [x] No occurrences of "Session"/"Participation" remain as domain vocabulary in module names, types, functions, routes, templates, or user-facing copy (infrastructure-only uses, if any, are fine to leave)
- [x] `gleam build` and `gleam test` pass after the rename
- [x] `gleam format --check` passes

## Comments

Implemented via a mechanical rename pass across `src/soli/` (module names, types, functions, routes, templates, user-facing copy) and regenerating `src/soli/sql.gleam` via `parrot` after renaming query names in `src/sql/query_spend.sql`. DB table/column names (`session`, `participation`, `session_id`, `participant_name`) were left as infrastructure per the ticket's allowance. `docs/arc42.md` and `.claude/skills/run-soli/SKILL.md` were updated to match so they don't go stale. Verified with `gleam build`/`gleam test`/`gleam format --check` and a manual browser smoke test (create Spend → view → Pledge page). Reviewed via `/code-review` (Standards + Spec, both clean; one judgement call noted and left as-is — see conversation).
