# 03 — Attempt settlement (Open → Resolved/Unbalanced)

**What to build:** From the Manage Link, the Creator can attempt settlement on an Open Spend. If the Pledges support the Total, the Spend becomes Resolved and each Pledge's final owed amount is fixed via proportional scale-down against the Total. If they don't, the Spend becomes Unbalanced: Pledges are frozen (no further edits), and aggregate information (total pledged, number of Pledges, amount still missing) becomes visible on the Share Link, per ADR-0001. From the Manage Link, the Creator can return an Unbalanced Spend to Open.

**Blocked by:** 02 — Manage Link (settlement and reopening are Creator-only actions gated by it)

**Status:** ready-for-agent

- [ ] Creator can trigger "attempt settlement" from the Manage Link
- [ ] When Pledges support the Total, the Spend transitions to Resolved and each participant's final owed amount (via proportional scale-down) is shown
- [ ] When Pledges don't support the Total, the Spend transitions to Unbalanced: further Pledge edits are rejected, and the Share Link now shows total pledged, Pledge count, and amount still missing
- [ ] Creator can return an Unbalanced Spend to Open from the Manage Link
- [ ] While a Spend is Open, aggregate information stays hidden on the Share Link (regression check for ADR-0001)
