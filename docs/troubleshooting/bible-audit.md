---
title: bible-audit Troubleshooting
category: Troubleshooting
managed_by: Home Manager
source: ~/dotfiles/configs/fish/functions/bible-audit.fish
runtime: ~/.config/fish/functions/bible-audit.fish
tags: bible audit fish troubleshooting metadata
status: active
criticality: normal
last_verified: 2026-08-26
---

# `bible-audit` Troubleshooting

## `test: Missing argument at index 3`

An early version of `bible-audit` defined helper functions inside the main function and expected
them to capture local variables such as `quiet` and `warnings`.

Fish functions do not behave like lexical closures. Those helper functions did not inherit the
parent function's locals, producing errors such as:

```text
test: Missing argument at index 3
-eq 0
```

The corrected implementation keeps state inside the main `bible-audit` function.

## Every Fish Function Is Reported Undocumented

The early version had two issues:

1. the helper responsible for searching docs could not see the parent `docs` variable
2. `path basename "$file" .fish` did not strip the extension as intended

The corrected version uses:

```fish
set -l base (path basename "$file")
set -l name (string replace -r '\.fish$' '' "$base")
```

and performs the documentation search directly.

## Warnings Are Printed but Summary Says Clean

The early nested warning helper incremented its own local variable instead of the main function's
`warnings` counter.

The corrected implementation increments the counter directly in the main function.

## Descriptive `source:` Values Reported as Missing Paths

Some pages use provenance text such as:

```yaml
source: Prior network design
```

or combined descriptive values.

These are not filesystem paths. The corrected source audit only validates values beginning with
`~/` or `/`, and recognizes `/DATA` and CasaOS paths as external to the workstation.

## Many Old Pages Still Show Metadata Warnings

Those can be genuine.

Older placeholder pages created before the Bible metadata standard may not start with YAML
frontmatter. The corrected audit reports each such page once as:

```text
Legacy page missing YAML metadata
```

instead of producing four warnings for the same file.

Those legacy pages should be upgraded or merged with their newer canonical pages rather than
ignored permanently.
