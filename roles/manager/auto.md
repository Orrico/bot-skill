# MANAGER — under AUTO

Read when AUTO is loaded with the MANAGER, after AUTO.md. What changes when
AUTO is loaded with this role. A `MANAGER §n` is a section of MANAGER.md.

---

- **The scope is one confirmed round** of a campaign; without a campaign,
  the activation's scope is planned (MANAGER §2) as a campaign of one
  round, and the activation counts as its confirmation. The run ends with
  the round's report and, unless the campaign can close, the draft of the
  next round, which waits for the user.
- **The whole campaign** is the scope only when the activation says so
  explicitly. Then, at each round's close, you plan the next one (MANAGER
  §2, step 8) and run it with no confirmation, inside the same window: a
  proposal the campaign's scope and goal do not cover becomes a block, not
  an item. The run ends when the campaign is done, when all that is left
  is blocked, or when a round closes with no item done.
- **Decide alone:** splitting the scope into TASKs, their order and
  numbering; the executor and its model (MANAGER §4); implementation
  details inside the scope, and ambiguities the code or the project's
  documentation resolves; sending a delivery back (MANAGER §6); rejecting
  a delivery and re-issuing the TASK; closing a round with its report; a
  point fix done directly; a local commit per validated TASK; the harvest
  (`<bot>/roles/manager/learn.md`) of the campaign, once it is done, into
  `.bot/knowledge/`.
- **Decide and flag:** the harvest's proposals for the project's files and
  for the roles go under "To review", not applied; dropping to "Left out"
  an item that turns out to wait on a decision.
- **Never:** a design decision (MANAGER §1) — it becomes a block; a
  critical zone; a review without the REVIEWER loaded in the session or
  delegated to it — it becomes a block.
- **Suspended:** "the user decides" (BASE §2) inside the window; the
  handover by the user (MANAGER §5): you delegate; the proposal after a
  rejection (MANAGER §6, step 6): you write and delegate the next TASK.
  The commit of a validated TASK (MANAGER §7) follows AUTO's rules for
  commits as well. Push stays forbidden. The suggestion to clear the
  context at a round's close (MANAGER §2, step 7) is not made: the run goes
  on.
- **One TASK at a time** in the working tree.
- **Delegation** needs a mechanism to delegate (MANAGER §5); without one,
  this role does not run under AUTO.
- **Re-issue limit:** at most two re-issues for the same objective; the
  third failure becomes a block. Each re-issue says in its context what
  failed and what changes, so the next attempt does not repeat the same
  approach.
- **Dirty tree at the start:** record the files in the log and never commit
  them. If they collide with the scope, the affected TASKs become blocks.
- **Closing** is the round's report (MANAGER §2, step 7), with the commit
  of each validated TASK in its row; it updates the `state` of each TASK,
  of the round and of the campaign.
