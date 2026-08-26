---
title: Pre-Change Safety Checklist
category: Recovery
managed_by: Documentation
source: ~/dotfiles/docs
runtime:
tags: checklist backup safety recovery
status: active
criticality: critical
last_verified: 2026-08-26
---

# Pre-Change Safety Checklist

Use this before major boot, storage, firewall, package-management, or recovery work.

- [ ] Read the relevant Bible page.
- [ ] Confirm the source-of-truth file/path.
- [ ] Run `git status`.
- [ ] Run `backup-everything` for major workstation changes.
- [ ] Verify the `Linux-Backup` drive is mounted.
- [ ] Verify Restic can list snapshots.
- [ ] Preserve the current working config before replacing it.
- [ ] Confirm SSH access before changing firewall rules remotely.
- [ ] Do not copy an old generated `grub.cfg`.
- [ ] Do not blindly restore old disk UUIDs.
- [ ] Do not expose secret `.env`, SSH, KWallet, or credential files.
- [ ] Have a recovery medium available for boot/storage work.
- [ ] Verify the change after applying it.
- [ ] Update the Bible if the final working configuration changed.
