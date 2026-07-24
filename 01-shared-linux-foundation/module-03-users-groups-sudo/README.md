# Module 03 — Users, Groups, sudo, and Password Policies

**Track:** Shared Linux Foundation  
**Level:** Linux Systems Engineer I and II  
**Primary platform:** Red Hat Enterprise Linux

## Overview

This module covers Linux identities, users, groups, password aging, account locking, service accounts, enterprise identity lookups, and secure administrative delegation through `sudo`.

## Learning Objectives

After completing this module, you should be able to:

- Explain usernames, UIDs, group names, and GIDs.
- Read `/etc/passwd`, `/etc/shadow`, and `/etc/group`.
- Use `getent` for local and enterprise identity lookups.
- Create and modify regular and service accounts.
- Manage primary and supplementary groups.
- Configure password aging and account expiration.
- Explain password locking versus complete access revocation.
- Create and validate least-privilege sudo rules.
- Troubleshoot login, group-membership, and sudo failures.

## Module Contents

- [Complete Study Notes](study-notes.md)
- Local and enterprise identities
- User and group databases
- Account creation and modification
- Primary and supplementary groups
- Password aging and expiration
- Account locking and offboarding
- `sudo`, `visudo`, and least privilege
- Authentication logging
- Hands-on account-management lab
- Production troubleshooting scenarios
- Interview questions and answer key

## Key Commands

```bash
id USERNAME
getent passwd USERNAME
getent group GROUPNAME
sudo useradd -m USERNAME
sudo usermod -aG GROUPNAME USERNAME
sudo passwd -S USERNAME
sudo chage -l USERNAME
sudo passwd -l USERNAME
sudo faillock --user USERNAME
sudo visudo
sudo visudo -c
sudo -l
sudo pwck -r
sudo grpck -r
```

## Practical Outcome

You will create a small operations team, configure password policies, create a non-interactive service account, and grant a group permission to run only one approved administrative command.

## Completion Requirement

Perform the lab on a disposable practice system, complete cleanup, and answer the scenario-based interview questions.

## Navigation

- [Previous: Module 02 — Filesystem Hierarchy](../module-02-filesystem-hierarchy/README.md)
- [Next: Module 04 — Permissions, ACLs, and Special Bits](../module-04-permissions-acls-special-bits/README.md)
