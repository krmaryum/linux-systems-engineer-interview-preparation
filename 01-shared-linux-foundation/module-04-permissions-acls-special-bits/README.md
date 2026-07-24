# Module 04 — Linux Permissions, ACLs, SUID, SGID, and Sticky Bit

**Track:** Shared Linux Foundation  
**Level:** Linux Systems Engineer I and II  
**Primary platform:** Red Hat Enterprise Linux

## Overview

This module explains Linux ownership, file and directory permissions, symbolic and octal modes, `umask`, Access Control Lists, special permission bits, shared directories, security auditing, and layered permission troubleshooting.

## Learning Objectives

After completing this module, you should be able to:

- Read and explain a complete Linux permission string.
- Use symbolic and octal permission notation.
- Explain permissions on files and directories.
- Change ownership safely.
- Calculate typical results from `umask`.
- Create and inspect ACL entries.
- Explain the ACL mask and default ACL inheritance.
- Explain SUID, SGID, and sticky-bit behavior.
- Build a secure shared-team directory.
- Audit dangerous permissions and special bits.
- Troubleshoot DAC, ACL, mount, NFS, and SELinux access problems.

## Module Contents

- [Complete Study Notes](study-notes.md)
- Ownership and standard permissions
- File versus directory permission behavior
- Symbolic and octal `chmod`
- `umask` calculations
- POSIX ACLs and ACL masks
- Default ACL inheritance
- SUID, SGID, and sticky bit
- Secure shared-directory design
- Special-permission auditing
- Hands-on permission lab
- Production troubleshooting scenarios
- Interview questions and revision checklist

## Key Commands

```bash
stat -c '%A %a %U %G %n' file
chmod 640 file
chmod 2770 directory
chown USER:GROUP file
umask
getfacl file
setfacl -m u:USER:r-- file
setfacl -m d:g:GROUP:rwx directory
namei -l /complete/path
findmnt -T /complete/path
ls -lZ /complete/path
sudo find / -xdev -type f -perm /6000 -ls
```

## Practical Outcome

You will practice standard modes, test `umask`, configure access and default ACLs, observe the ACL mask, apply SGID and sticky-bit behavior, and audit special permissions.

## Completion Requirement

Complete the lab and be able to explain why mode `777` may still produce `Permission denied`.

## Navigation

- [Previous: Module 03 — Users, Groups, and sudo](../module-03-users-groups-sudo/README.md)
- Next: Module 05 — Processes, Jobs, Signals, and Resource Usage
