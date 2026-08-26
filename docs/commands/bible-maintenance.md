---
title: Config Bible Maintenance
category: Commands
managed_by: Documentation
source: ~/dotfiles/docs
runtime:
tags: bible maintenance audit verification documentation
status: active
criticality: important
last_verified: 2026-08-26
---

# Config Bible Maintenance

## After Changing a Config

```fish
bible-audit
```

Then update the relevant page if the behavior, source path, recovery procedure, or rationale changed.

## After Adding a Fish Function

1. Add the function beneath:

```text
~/dotfiles/configs/fish/functions/
```

2. Document it beneath:

```text
~/dotfiles/docs/functions/
```

3. Stage new flake files:

```fish
git add configs/fish/functions/NEW-FUNCTION.fish
```

4. Apply:

```fish
hms
```

5. Audit:

```fish
bible-audit --functions
```

## After Adding a Home Manager Script

Document:

```text
~/dotfiles/home-manager/scripts/...
```

then:

```fish
bible-audit --scripts
```

## After Homelab Changes

When a new ZimaBoard stack is added:

- update its Compose documentation
- record AppData paths
- record ports/networks
- record secrets without exposing values
- record recovery order

On the ZimaBoard, `bible-audit --compose` can detect visible undocumented `/DATA/compose` stacks if the Bible repository is also available there.

## Periodic Review

Every few months:

```fish
bible-audit --stale
```

Review pages that have not been verified in 180 days.

## Before Git Push

Recommended:

```fish
bible-audit
git status
git diff --cached
```

For sensitive configuration, also inspect for accidental secrets before pushing.
