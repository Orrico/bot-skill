# Working in this repository

What the skill is and how it is laid out: [README](README.md). This file
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
- **Each file has one writer,** and the role that writes it sets its format.
  A new format goes to the role that writes the file, or to
  `roles/templates/` when it is a form.
- **`<bot>` is the skill's folder.** A role or a script never names the
  folder by a path of one machine; a file or a prompt another model reads
  gets it as an absolute path, which the scripts resolve from where they lie.
- **Renumbering a section breaks citations.** Look for who cites it first,
  with the second command of "Verification".

## Conventions

- **Everything is written in English.**
- **Markdown prose in `roles/` is wrapped at 80 columns;** tables, headings
  and code blocks are not.
- **Commits** follow Conventional Commits, with no AI trailers.
- **No secret** enters here, and no name of a private project.

## Pitfalls

- **`delegate.sh` to `agy` needs `bwrap` and `xdg-dbus-proxy` in the PATH,**
  and `"enableTerminalSandbox": false` in
  `~/.gemini/antigravity-cli/settings.json`: agy's own sandbox does not start
  on NixOS, and with it on every command fails at the handshake.
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
```

The third line ends in `total: …`; the last prints `[]`.

For a change to `roles/`, no prose line of `roles/` past 80 columns and no
citation of a section that does not exist:

```
awk 'FNR==1{b=0} /^ *```/{b=!b} !b && length>80 && !/^ *\|/ && !/^    / {print FILENAME":"FNR}' roles/*.md roles/*/*.md
grep -rnoE '(BASE|MANAGER|ARCHITECT|REVIEWER|AUTO|READER|WORKER)(\.md)? §[0-9]+' roles scripts SKILL.md
```
