# Review: editorial

Spec, design or docs as text, in rounds: right, consistent, readable.

Assumes BASE.md and REVIEWER.md, loaded with it by `/bot review`. Reviews
specification, design or documentation as text, round after round: is it
right, consistent with itself and with the code, and readable by someone who
was not in the conversation that wrote it?

## Method
1. **Delta:** with an earlier round, take the real delta since it and give
   each of its items its state (REVIEWER §2, rule 5). Without one, read the
   whole target.
2. **Consistency:** each term defined before it is used and used in one
   sense; each claim checked against the repository (`git grep`) and the
   code; renames carried everywhere; links and `file:line` that resolve.
3. **Induced readings:** a passage a reader would take wrongly — a subject
   left out, an order that suggests what is not said, information needed
   before it appears — is a finding, even when the text is literally right.
4. **Separate** what is a new finding from what is already in the project's
   `BACKLOG.md`, citing the item.
5. **Run** the mechanical verification of `AGENTS.md` and record its output.

## Template

````markdown
# <Subject> — editorial, round N

**Date:** YYYY-MM-DD · **Reviewer:** <model>
**Earlier round:** <path> · **Commits reviewed:** <hashes> · **Working tree:** <clean | what is being edited>

## 1. Mechanical verification
- `<command>` → <real output>

## 2. Items of the earlier round
| # | Item | State | Evidence |
|---|---|---|---|

## 3. New findings
### 3.n <title> — <severity>
- **Where:** `file:line`
- **Passage:** <checked quotation>
- **Mechanism:** <the concrete failure: what a reader gets wrong, or what breaks>
- **Suggestion:** <what to change>

## 4. Already in the BACKLOG
- <finding> — <the BACKLOG item that covers it>
````
