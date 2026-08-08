# 04 — Fix hardcoded Pledge id

**What to build:** A new Pledge (`NewParticipation`) gets a real, unique id when it's created, instead of the current placeholder literal `"test"`.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Submitting a Pledge generates a unique id for it (not the literal `"test"`)
- [ ] Submitting multiple Pledges (including to the same Spend) never collides on id
