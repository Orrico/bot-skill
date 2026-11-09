# /bot

A skill for coding agents — Claude Code and Gemini (Antigravity) — that takes
roles on a project: a manager that plans campaigns and writes TASKs, an
architect that designs with the user, a reviewer, and executors that carry a
TASK out. The work's state lives in the project's `.bot/` folder, outside the
project's git, so the project keeps no trace of it.

```
/bot <project> [role+role] <request>
```

read as "in project X, as roles Y, do Z":

```
/bot . manager "plan the next round from the backlog"
/bot ~/Code/myapp manager+architect "design the sessions' store"
/bot myapp dev+tester TASK-071
/bot myapp review TASK-012
/bot myapp review --code src/
/bot myapp learn
/bot myapp status
```

## Layout

| Path | What it holds |
|---|---|
| [`SKILL.md`](SKILL.md) | the skill: how `/bot` reads its arguments and boots |
| [`roles/`](roles/) | one file per role; `BASE.md` is what the coordinating roles share |
| [`roles/manager/`](roles/manager/) | the parts of the MANAGER read on demand: the harvest (`learn`) and the run under AUTO |
| [`roles/reviews/`](roles/reviews/) | one file per kind of review (`--code`, `--design`, …) |
| [`roles/templates/`](roles/templates/) | the forms of a campaign, a round, a TASK and a review |
| [`scripts/`](scripts/) | boot and status of a project, delegation to another CLI, the harvest's sources |
| [`models.md`](models.md) | which model takes which work, in each CLI |

The roles name the skill's own folder as `<bot>`; the scripts find it from
where they lie, so the skill works from wherever it is cloned.

## Roles

| Role | Does |
|---|---|
| MANAGER | plans campaigns in rounds, writes TASKs, delegates, validates, consolidates, harvests lessons |
| ARCHITECT | designs with the user and records the decisions |
| REVIEWER | reviews a TASK's delivery, or a subject by one kind of review |
| DEV | executes one TASK |
| TESTER | writes tests that can fail, alone or with DEV |
| WRITER | executes one editorial TASK |
| READER | reads conversations for the harvest |
| AUTO | a layer that runs a scope without asking, inside a window of authorization |
| WORKER | work outside the flow |

## Install

Clone it, then link it where each CLI looks for skills:

```
git clone git@github.com:Orrico/bot-skill.git ~/Code/bot-skill
ln -s ~/Code/bot-skill ~/.claude/skills/bot          # Claude Code
ln -s ~/Code/bot-skill ~/.gemini/config/skills/bot   # Gemini / Antigravity
```

The scripts need `bash`, `git` and `jq`; the harvest reads Antigravity's
conversations with `sqlite3`; delegating to Antigravity runs it under
`bwrap` with `xdg-dbus-proxy`.

## The project's `.bot/`

```
.bot/
├── campaigns/   CAMPAIGN-nnn/campaign.md and round-N.md
├── tasks/       TASK-nnn.md, its result and its review
├── reports/     reviews by kind
├── knowledge/   lessons digested by /bot learn
└── drafts/      scripts proposed by a harvest, never executable
```

It has a git of its own, without a remote, and a global excludes file keeps it
out of the project's git (`.bot/` in `~/.config/git/ignore`).

## License

[MIT](LICENSE).
