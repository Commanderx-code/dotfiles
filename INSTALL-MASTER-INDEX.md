# Install Master Config Bible Index

From the workstation:

```fish
cd ~/dotfiles
tar -xzf ~/Downloads/config-bible-master-index.tar.gz
```

This intentionally replaces/updates:

```text
docs/INDEX.md
```

and adds:

```text
docs/START-HERE.md
docs/commands/bible-workflow.md
docs/recovery/pre-change-checklist.md
```

Review:

```fish
git diff -- docs/INDEX.md
git status --short
```

Stage when satisfied:

```fish
git add docs
```

Test:

```fish
config-index "start here"
config-index "bible workflow"
config-index "pre-change"
```
