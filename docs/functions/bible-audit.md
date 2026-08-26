---
title: bible-audit
category: Function
managed_by: Home Manager
source: ~/dotfiles/configs/fish/functions/bible-audit.fish
runtime: ~/.config/fish/functions/bible-audit.fish
tags: bible audit fish documentation maintenance
status: active
criticality: important
last_verified: 2026-08-26
---

# `bible-audit`

## Purpose

`bible-audit` checks whether the Config Bible still matches the repository and visible system state.

It is designed to answer:

> Did I add a function, script, stack, or config and forget to document it?

> Do any Bible pages point to files that no longer exist?

> Is metadata missing or duplicated?

> Which pages have not been verified recently?

## Run Everything

```fish
bible-audit
```

## Focused Audits

Fish functions:

```fish
bible-audit --functions
```

Home Manager helper scripts:

```fish
bible-audit --scripts
```

Compose stacks visible on the current host:

```fish
bible-audit --compose
```

Documentation `source:` paths:

```fish
bible-audit --sources
```

Metadata:

```fish
bible-audit --metadata
```

Old `last_verified` dates:

```fish
bible-audit --stale
```

Minimal output:

```fish
bible-audit --quiet
```

Help:

```fish
bible-audit --help
```

## Fish Function Audit

The audit scans:

```text
~/dotfiles/configs/fish/functions/*.fish
```

and checks whether the function name or source path appears somewhere under:

```text
~/dotfiles/docs
```

Undocumented functions are reported.

## Home Manager Script Audit

Scans:

```text
~/dotfiles/home-manager/scripts/
```

and checks whether each helper appears in the Bible.

## Compose Audit

If `/DATA/compose` exists on the current machine, the audit scans visible Compose stack directories.

On the workstation, `/DATA/compose` normally does not exist because it belongs to the ZimaBoard. In that case the audit explicitly treats the ZimaBoard stack documentation as external rather than broken.

## Source Path Audit

Each documentation page may define:

```yaml
source:
```

Local paths are checked for existence.

Known external/reference sources such as:

```text
/DATA/...
/var/lib/casaos/...
```

are not reported as broken merely because the audit is running on the workstation.

## Metadata Audit

Checks for:

```yaml
title:
category:
status:
last_verified:
```

and reports duplicate `title:` values.

Files excluded from metadata enforcement:

```text
INDEX.md
INDEX-BATCH*.md
TEMPLATE.md
```

## Stale Documentation

Pages older than:

```text
180 days
```

according to `last_verified:` are reported.

This is a reminder to verify the configuration, not an automatic indication that the page is incorrect.

## Exit Status

```text
0  clean
1  warnings/errors found
```

This makes the audit usable from future automation or Git hooks.

## Recommended Routine

After adding/changing configuration:

```fish
hms
bible-audit
git status --short
```

Before a larger documentation commit:

```fish
bible-audit --metadata
bible-audit --sources
```

## Source

```text
~/dotfiles/configs/fish/functions/bible-audit.fish
```
