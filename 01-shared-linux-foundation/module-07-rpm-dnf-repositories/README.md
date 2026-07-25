# Module 07 — RPM, DNF, Repositories, and Software Management

**Track:** Shared Linux Foundation  
**Level:** Linux Systems Engineer I and II  
**Primary platform:** Red Hat Enterprise Linux

## Overview

This module explains how RHEL packages software with RPM and how DNF resolves dependencies, uses repositories, records transactions, applies security updates, and manages kernel packages.

## Learning Objectives

After completing this module, you should be able to:

- Explain RPM package names, metadata, and the RPM database.
- Query package information, files, ownership, scripts, and dependencies.
- Verify package signatures and installed-file integrity.
- Install, upgrade, downgrade, reinstall, and remove packages through DNF.
- Explain why DNF is normally preferred over direct RPM installation.
- Configure and troubleshoot repositories.
- Use DNF history carefully.
- Identify and apply security updates.
- Plan kernel updates and determine whether a reboot is required.
- Perform controlled enterprise patching with validation and rollback planning.

## Module Contents

- [Complete Study Notes](study-notes.md)
- RPM package structure and queries
- Package ownership and verification
- DNF dependency management
- Repository files, metadata, and GPG checking
- DNF groups and module streams
- Transaction history and rollback limitations
- Security advisories and patching
- Kernel package lifecycle
- Configuration-file handling
- Repository and RPM database troubleshooting
- Controlled hands-on lab
- Production scenarios and interview preparation

## Key Commands

```bash
rpm -qa
rpm -qi PACKAGE
rpm -ql PACKAGE
rpm -qf /path/to/file
rpm -V PACKAGE
rpm -K package.rpm
dnf repolist
dnf list installed
dnf info PACKAGE
dnf provides '*/command'
dnf install PACKAGE
dnf upgrade
dnf history
dnf updateinfo list security
dnf updateinfo info --security
dnf upgrade --security
dnf needs-restarting -r
```

## Practical Outcome

You will inventory packages and repositories, locate a file’s owning package, preview a transaction, safely install and remove a small lab package, verify package integrity, and record DNF history.

## Completion Requirement

Complete the controlled lab and explain how you would patch a production RHEL server while protecting availability and rollback capability.

## Navigation

- [Previous: Module 06 — systemd Services and Linux Boot Process](../module-06-systemd-and-boot/README.md)
- Next: Module 08 — Partitions, Filesystems, Mounts, and Swap
