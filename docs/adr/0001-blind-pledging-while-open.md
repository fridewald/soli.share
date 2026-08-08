---
status: accepted
---

# Hide aggregate pledge information while a Spend is Open

While a Spend is `Open`, nobody — including the Creator — can see the total pledged, the number of Pledges, or how much is still missing. This is deliberate: showing that information would let participants anchor their Pledge on what others have already offered (or let the Creator time or nudge their own), undermining "pay as you think," where a Pledge should reflect what someone is willing to pay rather than what they can get away with once they've seen the group's progress.

The aggregate becomes visible only once a settlement attempt fails and the Spend moves to `Unbalanced` — at that point participants genuinely need the information to know whether and how to raise their Pledge.

## Consequences

The Share Link's rendering must branch on Spend state: the same page shows strictly less information while `Open` than while `Unbalanced` or `Resolved`. There is no way to preview how close a Spend is to settling before contributing.
