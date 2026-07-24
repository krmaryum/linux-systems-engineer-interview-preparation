# Module 02 — Linux Filesystem Hierarchy and File Management

**Track:** Shared Linux Foundation  
**Level:** Linux Systems Engineer I and II  
**Primary platform:** Red Hat Enterprise Linux

## Overview

This module explains the Linux filesystem hierarchy, important directories, file types, inodes, links, file-management commands, search tools, and production disk-usage investigation.

## Learning Objectives

After completing this module, you should be able to:

- Explain the purpose of important directories under `/`.
- Work with absolute and relative paths.
- Recognize Linux file types.
- Explain filenames, directory entries, and inodes.
- Create and troubleshoot hard and symbolic links.
- Copy, move, rename, and remove files safely.
- Search by filename, type, owner, size, and modification time.
- Investigate disk-capacity and inode-exhaustion problems.
- Find deleted files that remain open by a process.
- Explain why `df` and `du` can report different usage.

## Module Contents

- [Complete Study Notes](study-notes.md)
- Linux filesystem hierarchy
- File types and inode concepts
- Hard links and symbolic links
- Safe file-management procedures
- `find`, `locate`, and `grep`
- Disk and inode investigation
- Deleted-but-open files
- Hands-on filesystem lab
- Production troubleshooting scenarios
- Interview questions and revision exercises

## Key Commands

```bash
pwd
ls -lah
stat file
file file
findmnt
lsblk
df -hT
df -i
du -xhd1 /path
find /path -xdev -type f -size +1G -ls
grep -Rni 'pattern' /path
ln original hard-link
ln -s target symbolic-link
readlink -f symbolic-link
sudo lsof +L1
```

## Practical Outcome

You will build a filesystem practice environment, create links, search for files and content, and investigate common production problems such as a full `/var`, inode exhaustion, and differences between `df` and `du`.

## Completion Requirement

Complete the practical lab, explain the production scenarios aloud, and finish the module checklist.

## Navigation

- [Previous: Module 01 — Linux Architecture](../module-01-linux-architecture/README.md)
- [Next: Module 03 — Users, Groups, sudo, and Password Policies](../module-03-users-groups-sudo/README.md)
