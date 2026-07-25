# Module 06 — systemd Services and Linux Boot Process

**Track:** Shared Linux Foundation  
**Level:** Linux Systems Engineer I and II  
**Primary platform:** Red Hat Enterprise Linux

## Overview

This module explains the complete Linux boot sequence and how systemd manages services, dependencies, targets, cgroups, logs, restart policies, resource controls, and system state.

## Learning Objectives

After completing this module, you should be able to:

- Explain the firmware-to-login RHEL boot sequence.
- Describe the roles of GRUB, the kernel, initramfs, and systemd.
- Identify important systemd unit types and locations.
- Start, stop, restart, reload, enable, disable, mask, and inspect services.
- Explain active state versus enablement state.
- Interpret `Wants`, `Requires`, `Before`, and `After`.
- Create and validate a service unit.
- Apply configuration through a systemd drop-in override.
- Use targets and understand rescue and emergency modes.
- Investigate failed services and slow or unsuccessful boots.
- Query service and boot logs with `journalctl`.

## Module Contents

- [Complete Study Notes](study-notes.md)
- RHEL boot sequence
- GRUB, kernel, and initramfs
- systemd architecture and unit types
- Unit-file locations and precedence
- Service lifecycle and enablement
- Unit dependencies and ordering
- Service types and restart policies
- Drop-in overrides
- Targets and recovery modes
- journald and boot logs
- Boot performance and failed-boot analysis
- Safe user-service lab
- Production scenarios and interview preparation

## Key Commands

```bash
systemctl status SERVICE
systemctl start SERVICE
systemctl restart SERVICE
systemctl reload SERVICE
systemctl enable --now SERVICE
systemctl is-active SERVICE
systemctl is-enabled SERVICE
systemctl cat SERVICE
systemctl show SERVICE
systemctl list-dependencies SERVICE
systemctl --failed
systemctl daemon-reload
systemctl get-default
journalctl -u SERVICE
journalctl -b
journalctl -b -1
systemd-analyze
systemd-analyze critical-chain
```

## Practical Outcome

You will create a safe user-level systemd service, inspect its PID and cgroup, view its journal, create an override, test restart behavior, and clean up the lab.

## Completion Requirement

Complete the lab and explain how you would investigate a failed production service or a server that boots into emergency mode.

## Navigation

- [Previous: Module 05 — Processes, Jobs, Signals, and Resource Usage](../module-05-processes-jobs-signals/README.md)
- Next: Module 07 — RPM, DNF, Repositories, and Software Management
