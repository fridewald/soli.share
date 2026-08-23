# Soli

Soli lets a group of people cover a shared expense by each pledging what they're willing to pay, rather than splitting the cost evenly. Soli only computes what each participant owes — collecting the money happens outside the app.

## Language

**Spending**:
A shared expense being collected for: a Total, plus the Pledges collected toward it. The central concept of the domain.
_Avoid_: Session, Share

**Total**:
The target amount a Spending needs to cover. The Creator can change it up until the first Pledge is submitted; once pledging has started, it's fixed for the life of the Spending.

**Pledge**:
A participant's commitment within a Spending: a name and the maximum amount they're willing to pay toward its Total.
_Avoid_: Participant, Participation

**Creator**:
The person who created a Spending. Holds its Manage Link and is the only one who can attempt settlement or reopen an Unbalanced Spending. Creating a Spending does not itself add a Pledge — a Creator who wants to contribute submits a Pledge the same way any other participant does, via the Share Link. Soli does not track who ends up paying whom.
_Avoid_: Owner, Admin

**Share Link**:
The public URL for a Spending, usable by anyone to view it and add or change a Pledge while Open.

**Manage Link**:
A separate, secret URL for a Spending, held only by its Creator. Device-independent — unlike a cookie, it works from wherever the Creator opens it. There is no recovery if it's lost.
_Avoid_: Manage token, admin URL

**Open**:
A Spending accepting Pledges. Anyone can add or change a Pledge. Aggregate information (total pledged, number of Pledges, amount still missing) is hidden while Open, so pledging is a blind commitment rather than a reaction to what others have already offered.

**Unbalanced**:
The state a Spending enters when its Creator attempts settlement but the Pledges don't support it. Pledges are frozen and aggregate information becomes visible on the Share Link, so participants can see what's missing and raise their Pledge accordingly. Only the Creator can return the Spending to Open.

**Resolved**:
The state a Spending enters once its Creator successfully settles it: every Pledge's final owed amount is fixed via proportional scale-down against the total.
