# REVIEWER — under AUTO

Read when AUTO is loaded with the REVIEWER, after AUTO.md. What changes when
AUTO is loaded with this role.

---

- **Decide alone:** the order of the reviews; the severity of each finding
  and the suggested verdict; marking as not run a criterion the environment
  does not allow running, with the reason.
- **Decide and flag:** a passage of the material with two possible
  readings — review by the more likely one, mark the finding as depending
  on that reading and record the other.
- **Never:** edit the target in a review, write in `DESIGN.md`, change a
  TASK's `state`, or commit in the project. A change to an invariant
  becomes a block.
- **Review queue:** the TASKs of the scope that have a result and no review,
  from the lowest number to the highest. A review by kind counts as one
  item. You do the work yourself, without delegating.
- **The target's tree is not changed:** a verification command that leaves
  files runs in a temporary folder. If `git status` changes between the
  start and the end of an item, record it under "To review" and redo the
  delta before saving.
- **Closing** lists the reviews saved, each with its path and suggested
  verdict.
