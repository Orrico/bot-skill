# AUTO — run a scope without asking

A layer over the other roles: it exists only with one of them, and is
loaded last. The role says how to work; AUTO says who decides and when to
stop. What this file does not change follows [BASE.md](BASE.md), the role
files and the model's global rules. Each role file says, in its section
"Under AUTO", what it decides alone, what it flags, what it never does and
which of its rules are suspended; this file holds what is common to all of
them.

The activation names the scope: a campaign (`CAMPAIGN-nnn`) — its
confirmed round, or the whole campaign when the activation says so
explicitly —, or a literal list — BACKLOG items, TASKs to review or to
test. It may narrow the window (e.g. "no commit") or bring decisions
already made. Without an explicit scope, ask before starting: it is the
only question of this mode.

At boot, add to BASE's line the scope understood and the restrictions of the
activation. Then start, without waiting for an answer.

---

## 1. Role
- **You do not consult.** Inside the window (§2), you decide in the user's
  place and move to the next item of the scope without waiting.
- **The scope is the activation's.** When it is done, close (§6); do not
  invent the next work. The next round of a campaign run whole is planned
  from the report of the one before, as the role's section says.
- **The user follows and may interrupt.** A message of theirs during the
  run overrides this file.
- **Do not stop to ask.** No "may I go on?". The turn ends only when the
  scope is done, when all that is left is blocked, or when the user
  interrupts.

## 2. Window of authorization
**Decide alone** — record it in the log, in one line: what the role's
section lists.

**Decide and flag** — take the option easiest to revert, record under "To
review" the reason and the discarded alternatives, and go on: what the
role's section lists, and any choice with real alternatives that a later
item depends on.

**Never** — fixed; the activation does not widen it. Record under "Blocks"
what is missing from the user and move to the next independent item:
- leaving the scope or changing an item's objective;
- changing a critical zone;
- a new dependency;
- push, a destructive or irreversible action, rewriting history;
- secrets, publishing or sending any content off the machine;
- changing the global rules, the role files or this file;
- what the role's section lists.

## 3. Suspended rules
Only these, and only during the run, plus those the role's section lists:
- BASE §2, "the user decides": inside the window, you decide.
- BASE §5, the user's approval for each delegation: the activation
  authorizes it.
- BASE §2, align before editing: the activation is the confirmation of
  the scope.
- BASE §2, asking when an assumption would change the work: replaced by
  the window (§2).

## 4. Running
- **Log first.** With a campaign as scope, the log is the "Log" section of
  the round being run. Otherwise, create the log of the day,
  `.bot/campaigns/AUTO-YYYY-MM-DD.md` (suffix `-2`, `-3` if one exists that
  day). The log has the sections Activation (literal text), State,
  Decisions, To review, Blocks and, outside a campaign, Commits — a round
  keeps each commit in its plan's row —, each a `###` heading in a round.
  Update the item's state before and after it — in a round, its row of the
  plan, and State only for what the plan does not show.
- **A block is answered in the file.** Each one is a line
  `- [ ] <item>: <what is missing from the user>`, followed by an empty
  `  Answer:` line the user fills in, so the answer does not depend on the
  chat being open.
- **The quota is not visible.** Treat any point as a possible cut; the log
  is what allows resuming.
- **Resuming.** If there is a log of this scope with an open state, continue
  from it: check `git status` and the state of each item against the log
  before any step. Route each answered block first: the answer goes into
  the item's next step (for a TASK, the context of the next TASK, with
  `reference:`), and the line becomes `- [x]`, the answer kept below it.
- **Delegation:** the prompt names the files to read and asks back for one
  status line (BASE §5). Without a mechanism to delegate, a role that needs
  it does not run under AUTO.

## 5. Commits
Only for a role whose section allows it.
- Local, on the current branch, after the role's consolidation.
- Before it, `git status`: a file changed outside the item is a validation
  failure. `git add` by path, never `-A` nor `.`.
- The message follows Conventional Commits, in the project's language,
  without citing `TASK-nnn` or `CAMPAIGN-nnn` and without AI trailers.
- A failing commit hook: fix it inside the scope or record a block. Never
  `--no-verify`.
- Record the hash in the log, or in the round's plan. Push, never.

## 6. Closing
In the chat and in the log: the items done, "To review", "Blocks", what is
left of the scope and the checks run, plus what the role's section asks;
in a campaign, the round's report is the closing in the file. A partial
delivery is announced as partial.
