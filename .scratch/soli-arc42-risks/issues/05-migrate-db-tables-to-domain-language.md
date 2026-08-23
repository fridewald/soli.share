# 05 — Migrate DB tables to domain language

**What to build:** Bring the database schema itself in line with `CONTEXT.md`, completing the rename that ticket 01 deferred as infrastructure. Table `session` becomes `spend`; table `participation` becomes `pledge`; column `participation.session_id` becomes `spend_id`; column `participation.participant_name` becomes `name`. No behavior change — this is a rename pass.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] New dbmate migration renames table `session` to `spend` and table `participation` to `pledge`, and renames `participation.session_id` to `spend_id` and `participation.participant_name` to `name` (updating the FK constraint and index accordingly)
- [ ] `db/schema.sql` regenerated to match
- [ ] `src/sql/query_spend.sql` updated to reference the new table/column names
- [ ] `src/soli/sql.gleam` regenerated via `parrot` from the updated queries
- [ ] `src/soli/spend_store.gleam` (and any other caller) updated to match the regenerated types — no remaining references to `session`, `participation`, `session_id`, or `participant_name` as DB identifiers
- [ ] `gleam build` and `gleam test` pass
- [ ] `gleam format --check` passes
- [ ] Manual smoke test: create a Spend, submit a Pledge, view it back
