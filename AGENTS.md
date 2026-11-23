# Working in this repository

What the skill is and how it is laid out: [README](README.md). Its data, its
flow and the decisions in force: [DESIGN](DESIGN.md); what is left:
[BACKLOG](BACKLOG.md); what changed: [CHANGELOG](CHANGELOG.md). This file
lists what is easy to get wrong.

## Live by symlink

This folder is linked as `~/.claude/skills/bot` and
`~/.gemini/config/skills/bot`: an edit changes every session that follows,
in every project. `roles/` is read by `/bot` and by the delegates of every
project; the scripts must stay executable (`chmod +x`). Antigravity does not
replace `$ARGUMENTS` with the command's text, which `SKILL.md` allows for.

## Rules of the roles

- **A role names another by its name alone.** A Markdown link or a `§n` to
  another role leads the agent to open it; the exceptions are BASE, which the
  coordinators have read, and reading another file as material, said so in
  the text.
- **Executors carry all they need.** DEV, TESTER, WRITER and READER are read
  alone by a delegate, which may be any model in any tool: a rule they need
  stays in them, even when the global rules or BASE say it already.
- **What a session does not use stays out of the role's file.** The
  harvest and each role's run under AUTO are in `roles/<role>/`, read on
  demand: a rule the role needs in every session goes in its file, since
  every line there is reread on every turn. A delegate reviewing a TASK
  reads `REVIEWER.md` alone, so what it needs of BASE is in it.
- **Each file has one writer,** and the role that writes it sets its format.
  A new format goes to the role that writes the file, or to
  `roles/templates/` when it is a form.
- **`<bot>` is the skill's folder.** A role or a script never names the
  folder by a path of one machine; a file or a prompt another model reads
  gets it as an absolute path, which the scripts resolve from where they lie.
- **Renumbering a section breaks citations.** Look for who cites it first,
  with the second command of "Verification".

## Measurements

A change meant to make the skill cheaper or more reliable starts from
`measurements/`: the last record gives the numbers to beat and the tool that
measured each. After it, a new record with the same method; how to write one
is in `measurements/README.md`.

## Conventions

- **Everything is written in English.**
- **Markdown prose in `roles/` is wrapped at 80 columns;** tables, headings
  and code blocks are not.
- **Commits** follow Conventional Commits, with no AI trailers.
- **No secret** enters here, and no name of a private project.

## Pitfalls

- **`delegate.sh` to `agy` needs `bwrap` and `xdg-dbus-proxy` in the PATH.**
  `delegate.sh` passes `--settings '{"agentMode":"","enableTerminalSandbox":false}'`
  inline because agy's own sandbox does not start on NixOS (for interactive
  `agy` sessions on NixOS, keep `"enableTerminalSandbox": false` in
  `~/.gemini/antigravity-cli/settings.json` when using its sandbox).
- **`.bot/` does not show in searches that honour git's ignore:** list it
  with `ls`; `boot.sh` prints facts about it alone.

## Verification

For a change to `scripts/`, with a project that has a `.bot/`:

```
for s in scripts/*.sh; do bash -n "$s" && test -x "$s" && echo "ok $s"; done
scripts/boot.sh <project>
scripts/status.sh <project>
scripts/learn-sources.sh <project> --list
echo '[]' | jq -c -f scripts/lessons.jq
scripts/round-close.sh <project> CAMPAIGN-nnn#N
```

The third line ends in `total: …`; the fourth prints `[]`; the last, on a
round closed since the causes became a set, ends in `ok: …`.

For a change to `new.sh` or to a form of `roles/templates/`, in a
throwaway project, never one with a real `.bot/`:

```
p=$(mktemp -d -p /tmp)/demo && mkdir -p "$p/.bot"
scripts/new.sh "$p" campaign && scripts/new.sh "$p" task dev+tester 1#1
scripts/new.sh "$p" review TASK-001 && scripts/task-preflight.sh "$p" TASK-001 --no-run
```

The preflight lists under `unfilled:` each `<…>` left, with no `<bot>` and
no `TASK-nnn` among them.

For a change to `roles/`, no prose line of `roles/` past 80 columns and no
citation of a section that does not exist:

```
awk 'FNR==1{b=0} /^ *```/{b=!b} !b && length>80 && !/^ *\|/ && !/^    / {print FILENAME":"FNR}' roles/*.md roles/*/*.md
grep -rnoE '(BASE|MANAGER|ARCHITECT|REVIEWER|AUTO|READER|WORKER)(\.md)? §[0-9]+' roles scripts SKILL.md
```
