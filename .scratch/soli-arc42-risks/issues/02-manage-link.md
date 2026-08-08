# 02 — Manage Link (creator-only URL)

**What to build:** When a Creator creates a Spend, they receive a separate, secret Manage Link distinct from the public Share Link, per `CONTEXT.md`'s definition — device-independent (a URL, not a cookie/session), unrecoverable if lost. Holding the Share Link alone must no longer be sufficient to perform any creator-only action; those actions are reachable only via the Manage Link.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Creating a Spend surfaces a Manage Link to the Creator, separate from the Share Link
- [ ] The Manage Link's identifier isn't derivable from the Spend's id or the Share Link
- [ ] Opening only the Share Link exposes no creator-only capability
- [ ] The Manage Link works from any device (no reliance on cookies/session state tied to the browser that created the Spend)
