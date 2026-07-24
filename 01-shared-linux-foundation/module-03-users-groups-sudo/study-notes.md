# Linux Systems Engineer II Interview Preparation

## Module 03 — Users, Groups, sudo, and Password Policies

**Target role:** Linux Systems Engineer II  
**Primary platform:** Red Hat Enterprise Linux (RHEL)  
**Recommended study time:** 75–90 minutes  
**Practice environment:** A disposable RHEL, AlmaLinux, Rocky Linux, or CentOS Stream virtual machine

> Perform the account-management lab only on a personal practice system. Do not create, modify, lock, or delete production accounts without an approved request and change procedure.

---

## 1. Module Objectives

After completing this module, you should be able to:

- Explain how Linux identifies users and groups.
- Read the important fields in `/etc/passwd`, `/etc/shadow`, `/etc/group`, and `/etc/gshadow`.
- Use `getent` to query local and enterprise identity sources.
- Create, modify, lock, unlock, expire, and safely remove user accounts.
- Manage primary and supplementary groups.
- Configure home directories and login shells.
- Explain password aging and account-expiration controls.
- Delegate privileges through `sudo` using least privilege.
- Safely validate sudoers configuration with `visudo`.
- Distinguish password locking from complete account-access prevention.
- Troubleshoot common authentication, group-membership, home-directory, and `sudo` problems.
- Answer enterprise Linux user-management interview questions.

---

## 2. Linux User and Group Fundamentals

Linux normally makes authorization decisions by using numeric identifiers:

- **UID** — user identifier
- **GID** — group identifier

A username such as `khalid` is a human-readable name mapped to a UID.

A group name such as `linuxadmins` is mapped to a GID.

Display your current identity:

```bash
whoami
id
```

Example:

```text
uid=1000(khalid) gid=1000(khalid) groups=1000(khalid),10(wheel)
```

This indicates:

- UID `1000` belongs to user `khalid`.
- Primary GID `1000` belongs to group `khalid`.
- The user also belongs to the supplementary group `wheel`.

### Important Interview Point

The kernel uses numeric UIDs and GIDs. Usernames and group names are resolved through configured identity databases.

If a file displays a numeric owner instead of a username, the system may no longer be able to resolve that UID to a name.

```bash
ls -ln file_name
```

The `-n` option displays numeric UID and GID values.

---

## 3. Types of Linux Accounts

### 3.1 Root Account

The root account normally has:

```text
UID 0
```

UID 0 receives unrestricted superuser privileges. Any account with UID 0 is effectively a root account, regardless of its username.

Audit for UID 0 accounts:

```bash
awk -F: '$3 == 0 {print $1, $3}' /etc/passwd
```

In a secure system, unexpected UID 0 accounts require immediate investigation.

### 3.2 Regular User Accounts

Regular users normally represent people or interactive identities.

Their UID range is controlled by settings such as:

```bash
grep -E '^(UID_MIN|UID_MAX)' /etc/login.defs
```

Do not assume that every organization uses the same UID range.

### 3.3 System and Service Accounts

System accounts run services and applications. They commonly:

- Have a UID below the regular-user range
- Use a non-interactive shell
- Have no password
- Own application files and processes
- Receive only the permissions required by the service

Examples may include:

```text
chrony
sshd
apache
nginx
```

Check an account:

```bash
getent passwd chrony
```

---

## 4. Identity Databases

### 4.1 `/etc/passwd`

Display:

```bash
cat /etc/passwd
```

Each record contains seven colon-separated fields:

```text
username:password_placeholder:UID:GID:GECOS:home_directory:login_shell
```

Example:

```text
ali:x:1001:1001:Ali Khan:/home/ali:/bin/bash
```

| Field | Example | Meaning |
|---:|---|---|
| 1 | `ali` | Username |
| 2 | `x` | Password hash is stored in `/etc/shadow` |
| 3 | `1001` | UID |
| 4 | `1001` | Primary GID |
| 5 | `Ali Khan` | GECOS/comment field |
| 6 | `/home/ali` | Home directory |
| 7 | `/bin/bash` | Login shell |

`/etc/passwd` must be readable by users because many programs need to resolve usernames and UIDs. Password hashes are protected in `/etc/shadow`.

### 4.2 `/etc/shadow`

Display with administrative privileges:

```bash
sudo cat /etc/shadow
```

Each record contains password and aging information:

```text
username:password:last_change:min:max:warn:inactive:expire:reserved
```

| Field | Purpose |
|---:|---|
| 1 | Username |
| 2 | Password hash or account/password-lock marker |
| 3 | Days since 1970-01-01 when the password was last changed |
| 4 | Minimum days before the password can be changed |
| 5 | Maximum days the password remains valid |
| 6 | Warning days before password expiration |
| 7 | Inactive days after password expiration |
| 8 | Account-expiration date in days since 1970-01-01 |
| 9 | Reserved |

Do not manually edit `/etc/shadow` with a normal editor. Use supported commands, or `vipw -s` only when an emergency requires controlled manual repair.

### 4.3 `/etc/group`

Format:

```text
group_name:password_placeholder:GID:member_list
```

Example:

```text
linuxadmins:x:2000:ali,sara
```

The comma-separated member list contains supplementary members. A user whose primary GID matches the group may not appear in that list.

### 4.4 `/etc/gshadow`

`/etc/gshadow` stores protected group information such as group administrators, group password data, and members.

```bash
sudo cat /etc/gshadow
```

Direct group-password use is uncommon in modern enterprise administration.

---

## 5. Local Files vs. Enterprise Identity Sources

Enterprise Linux systems may use:

- Local files
- LDAP
- Microsoft Active Directory
- SSSD
- Other directory or identity services

The Name Service Switch configuration controls resolution order:

```bash
cat /etc/nsswitch.conf
```

Relevant entries include:

```text
passwd:
group:
shadow:
```

### Why `getent` Is Important

`getent` queries identity sources configured through Name Service Switch rather than reading only local files.

```bash
getent passwd ali
getent group linuxadmins
getent passwd
```

Interview answer:

> I use `getent` when troubleshooting enterprise identities because the account may come from SSSD, LDAP, or Active Directory and may not appear in `/etc/passwd`.

Check whether SSSD is running:

```bash
systemctl status sssd
```

This module focuses primarily on local accounts. Enterprise identity integration will be covered at a higher level in a later module.

---

## 6. Important Account-Management Files

| File or Directory | Purpose |
|---|---|
| `/etc/passwd` | User identity and account attributes |
| `/etc/shadow` | Password hashes and password-aging information |
| `/etc/group` | Group identities and supplementary members |
| `/etc/gshadow` | Protected group information |
| `/etc/login.defs` | Defaults and policy values used by account tools |
| `/etc/default/useradd` | Default values used by `useradd` |
| `/etc/skel` | Template files copied into new home directories |
| `/etc/shells` | Recognized login shells |
| `/etc/nsswitch.conf` | Identity and name-service lookup sources |
| `/etc/sudoers` | Main sudo policy |
| `/etc/sudoers.d/` | Drop-in sudo policy files |
| `/etc/security/` | PAM-related policy and limits files |

Display `useradd` defaults:

```bash
useradd -D
```

Inspect login defaults:

```bash
grep -Ev '^[[:space:]]*(#|$)' /etc/login.defs
```

Inspect skeleton files:

```bash
ls -la /etc/skel
```

---

## 7. Creating Users

### 7.1 Basic User Creation

```bash
sudo useradd -m ali
```

Set the password securely:

```bash
sudo passwd ali
```

Do not place a real password directly on a command line. Command lines may be visible in shell history or process information.

### 7.2 Create a User with Explicit Settings

```bash
sudo useradd \
    -m \
    -c "Ali Khan - Linux Operations" \
    -s /bin/bash \
    ali
```

Options:

| Option | Meaning |
|---|---|
| `-m` | Create the home directory |
| `-c` | Set the comment or GECOS field |
| `-s` | Set the login shell |
| `-d` | Set a custom home-directory path |
| `-u` | Set an explicit UID |
| `-g` | Set the primary group |
| `-G` | Set supplementary groups |
| `-e` | Set the account-expiration date |
| `-r` | Create a system account |

### 7.3 Verify the New Account

```bash
getent passwd ali
id ali
sudo passwd -S ali
sudo chage -l ali
ls -ld /home/ali
```

### 7.4 Create a Service Account

Example:

```bash
sudo useradd \
    --system \
    --home-dir /var/lib/reporting \
    --shell /sbin/nologin \
    reporting
```

Depending on the command options and local defaults, the home directory may not be created automatically for a system account. Create and assign it only if the application requires it:

```bash
sudo install -d -o reporting -g reporting /var/lib/reporting
```

---

## 8. Modifying Users

### 8.1 Change the Comment

```bash
sudo usermod -c "Ali Khan - Production Support" ali
```

### 8.2 Change the Login Shell

```bash
sudo usermod -s /bin/bash ali
```

For a non-interactive service account:

```bash
sudo usermod -s /sbin/nologin reporting
```

Verify valid shells:

```bash
cat /etc/shells
```

### 8.3 Rename a User

```bash
sudo usermod -l newname oldname
```

Renaming the login does not automatically rename every related item. A controlled rename may also require:

- Moving or renaming the home directory
- Renaming the user’s private group
- Updating cron jobs
- Updating application configuration
- Updating file ownership references
- Reviewing SSH keys and automation
- Reviewing external identity records

### 8.4 Move the Home Directory

```bash
sudo usermod -d /home/newname -m newname
```

- `-d` sets the new path.
- `-m` moves the content from the old home directory.

Before changing a production home directory, verify:

- The user is logged out
- No process is using the old path
- The destination filesystem has capacity
- Ownership and SELinux contexts will be correct
- Applications do not depend on the old path

### 8.5 Change a UID

```bash
sudo usermod -u 1501 ali
```

Changing a UID is high impact. Files outside the home directory may retain the old numeric UID.

Find files owned by the old UID on one filesystem:

```bash
sudo find / -xdev -uid OLD_UID -ls 2>/dev/null
```

Plan ownership correction carefully across all relevant filesystems, network storage, scheduled jobs, and applications.

---

## 9. Group Management

### 9.1 Create a Group

```bash
sudo groupadd linuxadmins
```

Create with an explicit GID:

```bash
sudo groupadd -g 2000 linuxadmins
```

### 9.2 Primary Group

A user has one primary group. It is represented by the GID field in the user record.

Display:

```bash
id ali
```

Change the primary group:

```bash
sudo usermod -g linuxadmins ali
```

### 9.3 Supplementary Groups

Add a user to an additional group:

```bash
sudo usermod -aG linuxadmins ali
```

Important:

- `-G` sets the supplementary-group list.
- `-aG` appends groups without removing existing supplementary memberships.

If you accidentally omit `-a`, existing supplementary group memberships can be removed:

```bash
sudo usermod -G linuxadmins ali
```

That command should be used only when replacing the entire supplementary-group list is intentional.

Alternative:

```bash
sudo gpasswd -a ali linuxadmins
```

Remove a user from a supplementary group:

```bash
sudo gpasswd -d ali linuxadmins
```

### 9.4 Verify Group Membership

```bash
id ali
groups ali
getent group linuxadmins
```

### 9.5 When Does New Group Membership Apply?

Existing login sessions may not immediately receive new supplementary groups.

The safest approach is usually:

1. Log out.
2. Start a new authenticated session.
3. Run `id` again.

For a temporary subshell in a lab:

```bash
newgrp linuxadmins
```

Do not confuse an updated group database with the group list already assigned to a running process.

---

## 10. Password Management

### 10.1 Set or Change a Password

Administrator sets another user’s password:

```bash
sudo passwd ali
```

User changes their own password:

```bash
passwd
```

### 10.2 Check Password Status

```bash
sudo passwd -S ali
```

Common status indicators may include:

| Status | Meaning |
|---|---|
| `P` or `PS` | Usable password is set |
| `L` or `LK` | Password is locked |
| `NP` | No password |

Exact output formatting can vary by distribution and command version.

### 10.3 Force Password Change at Next Login

```bash
sudo chage -d 0 ali
```

Alternative:

```bash
sudo passwd -e ali
```

### 10.4 Delete a Password

```bash
sudo passwd -d ali
```

This can create a dangerous passwordless condition depending on PAM and service configuration. Do not use it as a routine account-unlock method.

### 10.5 Lock and Unlock the Password

Lock:

```bash
sudo passwd -l ali
```

Unlock:

```bash
sudo passwd -u ali
```

Equivalent usermod operations:

```bash
sudo usermod -L ali
sudo usermod -U ali
```

### Critical Security Point

Locking the password does not necessarily block all access. The user may still gain access through:

- SSH public keys
- Existing login sessions
- `sudo` from another account
- Scheduled jobs
- Service tokens or application credentials
- Other authentication methods

For complete offboarding or incident containment, follow the organization’s access-revocation procedure across all relevant systems.

---

## 11. Password Aging and Account Expiration

### 11.1 View Aging Information

```bash
sudo chage -l ali
```

### 11.2 Set Password-Aging Values

Example:

```bash
sudo chage \
    -m 1 \
    -M 90 \
    -W 14 \
    -I 7 \
    ali
```

| Option | Meaning |
|---|---|
| `-m 1` | Minimum 1 day between password changes |
| `-M 90` | Password expires after 90 days |
| `-W 14` | Warn 14 days before expiration |
| `-I 7` | Disable password login after 7 inactive days following password expiration |

### 11.3 Set Account Expiration

```bash
sudo chage -E 2026-12-31 contractor1
```

Alternative:

```bash
sudo usermod -e 2026-12-31 contractor1
```

Remove the account-expiration date:

```bash
sudo chage -E -1 contractor1
```

Password expiration and account expiration are different:

- **Password expiration** requires a password change.
- **Account expiration** disables the account after a date.

### 11.4 Policy Defaults

Inspect:

```bash
grep -E '^(PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_WARN_AGE)' /etc/login.defs
```

These defaults commonly apply when new local accounts are created. Changing them does not necessarily update existing accounts.

---

## 12. Account Locking vs. Login Failure Lockout

These are separate concepts.

### Administrator Password Lock

```bash
sudo passwd -l ali
```

This modifies the password field so password authentication cannot succeed.

### Automatic Failure Lockout

RHEL can use PAM components such as `pam_faillock` to temporarily lock authentication after repeated failures.

Check a user’s failure records:

```bash
sudo faillock --user ali
```

Reset recorded failures:

```bash
sudo faillock --user ali --reset
```

Only reset a lockout after verifying the user, checking for malicious attempts, and following security policy.

On modern RHEL systems, PAM profiles are commonly managed with `authselect`. Avoid directly overwriting generated PAM files without understanding the active profile.

Inspect:

```bash
authselect current
```

---

## 13. Disabling an Account Safely

The required steps depend on whether the goal is temporary suspension, contractor expiration, employee offboarding, or incident containment.

Possible controls include:

### Lock Password Authentication

```bash
sudo passwd -l ali
```

### Set Account Expiration

```bash
sudo usermod -e 1 ali
```

Historically, an expiration value of `1` represents a date in the past. Verify the resulting state:

```bash
sudo chage -l ali
```

### Change to a Non-Interactive Shell

```bash
sudo usermod -s /sbin/nologin ali
```

### Review SSH Keys

```bash
sudo ls -la /home/ali/.ssh
```

### Review Active Sessions and Processes

```bash
who
w
loginctl list-sessions
pgrep -u ali -a
```

### Review Scheduled Work

```bash
sudo crontab -l -u ali
sudo systemctl list-timers --all
```

### Important Production Principle

Do not improvise offboarding. Use a documented procedure that covers:

- Local and directory accounts
- SSH keys
- Active sessions
- `sudo` privileges
- Cloud and application access
- Scheduled jobs
- Service ownership
- Files and data custody
- Audit evidence

---

## 14. Deleting Users

Delete only the account record:

```bash
sudo userdel ali
```

Delete the account and its home directory and mail spool:

```bash
sudo userdel -r ali
```

### Before Deletion

Check:

```bash
id ali
pgrep -u ali -a
sudo crontab -l -u ali
sudo find / -xdev -user ali -ls 2>/dev/null
```

Also verify:

- Manager and security approval
- Data-retention requirements
- Ownership of application files
- Scheduled jobs and services
- Cloud or directory identities
- Backup or transfer of business data
- Whether the account should be disabled instead of deleted

Deleting an account does not automatically remove every file it owns from every filesystem.

After deletion, remaining files may display only the numeric UID.

---

## 15. Checking Account-Database Integrity

Check user databases:

```bash
sudo pwck -r
```

Check group databases:

```bash
sudo grpck -r
```

The `-r` option performs read-only checks.

Controlled editing tools:

```bash
sudo vipw
sudo vipw -s
sudo vigr
sudo vigr -s
```

These commands use locking to reduce the risk of concurrent edits.

Prefer account-management commands over manual database editing.

---

## 16. Understanding `sudo`

`sudo` allows an authorized user to execute a command as another user, normally root.

Example:

```bash
sudo systemctl status sshd
```

Run as a specific user:

```bash
sudo -u reporting id
```

List your allowed commands:

```bash
sudo -l
```

Open a root login-style shell when authorized:

```bash
sudo -i
```

### Why `sudo` Is Preferred

Compared with sharing the root password, `sudo` can provide:

- Individual accountability
- Command-level authorization
- Central policy
- Logging
- Time-limited credential caching
- Least-privilege delegation

---

## 17. The sudoers Policy

Main file:

```text
/etc/sudoers
```

Drop-in directory:

```text
/etc/sudoers.d/
```

### Basic Syntax

```text
USER_OR_GROUP HOSTS=(RUNAS_USERS) COMMANDS
```

Example:

```text
ali ALL=(root) /usr/bin/systemctl status httpd
```

Group rules begin with `%`:

```text
%linuxadmins ALL=(ALL) ALL
```

On RHEL, members of `wheel` are commonly granted broad sudo access by a rule similar to:

```text
%wheel ALL=(ALL) ALL
```

Check the actual policy instead of assuming it is enabled.

### Use Absolute Command Paths

Resolve:

```bash
command -v systemctl
```

Then use the full path in sudoers:

```text
/usr/bin/systemctl
```

### Safely Edit sudoers

Edit the main file:

```bash
sudo visudo
```

Create or edit a drop-in:

```bash
sudo visudo -f /etc/sudoers.d/web-operations
```

Validate all sudoers files:

```bash
sudo visudo -c
```

Validate a specific file:

```bash
sudo visudo -cf /etc/sudoers.d/web-operations
```

Sudoers drop-in files should normally be owned by root and not writable by unauthorized users. A common mode is:

```bash
sudo chmod 0440 /etc/sudoers.d/web-operations
```

---

## 18. Least-Privilege sudo Examples

### 18.1 Allow Read-Only Service Status

```text
%websupport ALL=(root) /usr/bin/systemctl status httpd
```

### 18.2 Allow Controlled Service Actions

```text
%webadmins ALL=(root) \
    /usr/bin/systemctl status httpd, \
    /usr/bin/systemctl restart httpd
```

### 18.3 Avoid Dangerous Broad Delegation

Commands such as the following can provide paths to arbitrary root execution:

- Editors
- Shells
- Interpreters
- Commands that can execute other commands
- Commands accepting arbitrary file paths
- Broad wildcard rules

Example of an overly broad policy:

```text
ali ALL=(root) NOPASSWD: ALL
```

This effectively grants unrestricted root access without a password prompt. It should not be used merely for convenience.

### 18.4 Command Arguments Matter

Sudo policy design must consider the entire command and its arguments. Allowing:

```text
/usr/bin/systemctl
```

without argument restrictions may permit many more service operations than intended.

For complex operational tasks, a root-owned wrapper script with strict input validation may be safer than a broad sudo command. The script itself must not be writable by the delegated user.

---

## 19. `su`, `sudo`, and Root Shells

### `su -`

```bash
su -
```

- Switches to root or another account
- Commonly requires the target account’s password
- Starts a login-style environment

### `sudo command`

```bash
sudo systemctl restart httpd
```

- Executes a specific authorized command
- Commonly authenticates with the invoking user’s password
- Provides better individual accountability

### `sudo -i`

```bash
sudo -i
```

- Starts a root login-style shell when authorized
- Useful for a sequence of administrative commands
- Reduces command-level visibility compared with using `sudo` for individual commands

Interview answer:

> I prefer individual `sudo` commands for routine administration because authorization and audit records are clearer. I use a root shell only when the task requires it and policy permits it.

---

## 20. Authentication and sudo Logs

On RHEL, authentication and sudo information may be available through:

```bash
sudo journalctl _COMM=sudo
sudo journalctl -t sudo
sudo journalctl -u sshd
sudo tail -F /var/log/secure
```

Availability depends on rsyslog, journald, audit, and local logging configuration.

Search recent authentication failures:

```bash
sudo journalctl --since "30 minutes ago" | grep -Ei 'authentication failure|failed password|sudo'
```

Check audit records when auditd is configured:

```bash
sudo ausearch -m USER_AUTH,USER_ACCT,USER_CMD -ts recent
```

Do not rely on only one log source. Correlate timestamps, hostname, source address, account, service, and recent changes.

---

## 21. Common Login Shells

Check a user:

```bash
getent passwd ali
```

Common values:

| Shell | Purpose |
|---|---|
| `/bin/bash` | Interactive Bash shell |
| `/bin/sh` | System’s standard shell interface |
| `/sbin/nologin` | Reject interactive login with a message |
| `/bin/false` | Exit immediately without an interactive session |

A non-interactive shell does not automatically stop:

- Already running processes
- Scheduled jobs
- Application authentication
- Every possible SSH subsystem or forced command

Use defense in depth and a documented access-control procedure.

---

## 22. Home Directories and `/etc/skel`

When a home directory is created, files from `/etc/skel` may be copied into it.

Inspect:

```bash
ls -la /etc/skel
```

Typical files include:

```text
.bash_profile
.bashrc
.bash_logout
```

Check home-directory ownership:

```bash
ls -ld /home/ali
```

Expected ownership commonly resembles:

```text
ali ali
```

Repair ownership in a lab:

```bash
sudo chown -R ali:ali /home/ali
```

Do not recursively change production ownership until you confirm whether some files intentionally belong to another user or group.

On SELinux systems, repair default security contexts when appropriate:

```bash
sudo restorecon -RFv /home/ali
```

---

## 23. Hands-On Lab

### Lab Safety

Use only a disposable practice VM. The lab creates and deletes test accounts and modifies sudo policy.

### Lab Objective

Create a small Linux operations team with:

- User `labali`
- User `labsara`
- Group `labops`
- A service account `labreport`
- Password-aging controls
- Limited sudo access for the `labops` group

### Step 1 — Confirm the Environment

```bash
cat /etc/redhat-release
id
sudo -v
```

Confirm that you have administrative access before continuing.

### Step 2 — Check for Existing Lab Identities

```bash
getent passwd labali
getent passwd labsara
getent passwd labreport
getent group labops
```

If any name already exists, stop and choose unique lab names. Do not overwrite or repurpose an existing identity.

### Step 3 — Create the Operations Group

```bash
sudo groupadd labops
```

Verify:

```bash
getent group labops
```

### Step 4 — Create Two Users

```bash
sudo useradd -m -c "Ali - Lab Operations" -s /bin/bash labali
sudo useradd -m -c "Sara - Lab Operations" -s /bin/bash labsara
```

Set passwords interactively:

```bash
sudo passwd labali
sudo passwd labsara
```

### Step 5 — Add Supplementary Membership

```bash
sudo usermod -aG labops labali
sudo usermod -aG labops labsara
```

Verify:

```bash
id labali
id labsara
getent group labops
```

### Step 6 — Configure Password Aging

```bash
sudo chage -m 1 -M 90 -W 14 -I 7 labali
sudo chage -m 1 -M 90 -W 14 -I 7 labsara
```

Review:

```bash
sudo chage -l labali
sudo chage -l labsara
```

### Step 7 — Create a Service Account

```bash
sudo useradd \
    --system \
    --home-dir /var/lib/labreport \
    --shell /sbin/nologin \
    labreport
```

Create its data directory:

```bash
sudo install -d -o labreport -g labreport /var/lib/labreport
```

Verify:

```bash
getent passwd labreport
id labreport
ls -ld /var/lib/labreport
sudo passwd -S labreport
```

### Step 8 — Configure Limited sudo

Resolve the required command:

```bash
command -v systemctl
```

Create a sudoers drop-in:

```bash
sudo visudo -f /etc/sudoers.d/labops-status
```

Add:

```text
%labops ALL=(root) /usr/bin/systemctl status sshd
```

Validate:

```bash
sudo visudo -cf /etc/sudoers.d/labops-status
sudo visudo -c
```

Set secure ownership and mode:

```bash
sudo chown root:root /etc/sudoers.d/labops-status
sudo chmod 0440 /etc/sudoers.d/labops-status
```

### Step 9 — Test the Policy

Start a new login session for `labali` so the supplementary group is active.

```bash
su - labali
```

Then:

```bash
id
sudo -l
sudo /usr/bin/systemctl status sshd
```

Attempting an unauthorized administrative command should be denied:

```bash
sudo /usr/bin/systemctl restart sshd
```

Exit:

```bash
exit
```

### Step 10 — Test Password Locking

Lock:

```bash
sudo passwd -l labsara
sudo passwd -S labsara
```

Unlock:

```bash
sudo passwd -u labsara
sudo passwd -S labsara
```

### Step 11 — Check Database Integrity

```bash
sudo pwck -r
sudo grpck -r
```

Review warnings carefully. Do not make unrelated repairs merely because a lab command reported a pre-existing condition.

### Step 12 — Lab Cleanup

First confirm the exact test identities:

```bash
getent passwd labali
getent passwd labsara
getent passwd labreport
getent group labops
```

Check for active processes:

```bash
pgrep -u labali -a
pgrep -u labsara -a
pgrep -u labreport -a
```

Remove only the lab sudo policy:

```bash
sudo rm -i /etc/sudoers.d/labops-status
sudo visudo -c
```

Remove only the lab accounts:

```bash
sudo userdel -r labali
sudo userdel -r labsara
sudo userdel labreport
```

Remove the lab service directory after verifying it:

```bash
sudo ls -ld /var/lib/labreport
sudo rm -rI /var/lib/labreport
```

Remove the lab group if it still exists and has no members:

```bash
getent group labops
sudo groupdel labops
```

Final verification:

```bash
getent passwd labali
getent passwd labsara
getent passwd labreport
getent group labops
sudo visudo -c
```

No matching identity output is expected after successful cleanup.

---

## 24. Production Troubleshooting Scenarios

### Scenario 1 — User Exists but Cannot Log In

Check:

```bash
getent passwd USERNAME
id USERNAME
sudo passwd -S USERNAME
sudo chage -l USERNAME
sudo faillock --user USERNAME
getent passwd USERNAME | cut -d: -f6,7
sudo ls -ld HOME_DIRECTORY
```

Then review:

- Account source: local, SSSD, LDAP, or AD
- Password lock
- Account expiration
- Password expiration
- Login-failure lockout
- Login shell
- Home-directory ownership and permissions
- SSH configuration and keys
- PAM and SSSD state
- Authentication logs
- SELinux denials

### Scenario 2 — User Was Added to a Group but Still Gets Permission Denied

Check:

```bash
getent group GROUPNAME
id USERNAME
```

Consider:

- Existing session has the old group list
- User was added without preserving other groups
- Wrong group owns the file
- Directory execute permission is missing
- ACL or SELinux denies access
- Account comes from a directory service and cache has not refreshed

Ask the user to start a new authenticated session, then verify `id`.

### Scenario 3 — `sudo` Says User Is Not Allowed

Check:

```bash
id USERNAME
sudo -l -U USERNAME
sudo visudo -c
```

Investigate:

- Required group membership
- New login session needed
- Sudoers syntax
- Incorrect command path or arguments
- Incorrect file ownership or mode
- Rule order and conflicting policy
- Host or RunAs restrictions

### Scenario 4 — Home Directory Shows the Wrong Owner

Check:

```bash
getent passwd USERNAME
ls -ldn HOME_DIRECTORY
find HOME_DIRECTORY -maxdepth 2 -printf '%U:%G %m %p\n' | head
```

Determine whether:

- UID changed
- Account was deleted and recreated with another UID
- Files came from backup or another server
- NFS identity mapping differs
- Some application files intentionally use different ownership

Do not immediately run a recursive `chown` across production data.

### Scenario 5 — Contractor Access Should End Automatically

Use a defined expiration date:

```bash
sudo chage -E YYYY-MM-DD contractor1
```

Verify:

```bash
sudo chage -l contractor1
```

Also ensure offboarding covers directory services, VPN, cloud roles, application access, SSH keys, and active sessions.

### Scenario 6 — Repeated Failed SSH Logins

Check:

```bash
sudo faillock --user USERNAME
sudo journalctl -u sshd --since "1 hour ago"
sudo tail -F /var/log/secure
```

Correlate:

- Source IP
- Username
- Authentication method
- Frequency
- Successful login events
- Security alerts

Do not reset the lockout until malicious activity has been considered.

---

## 25. Common Interview Questions and Answers

### 1. What is the difference between a username and a UID?

A username is a human-readable label. The UID is the numeric identity used by the kernel for ownership and authorization.

### 2. What is special about UID 0?

UID 0 has root privileges. Any account assigned UID 0 is effectively a superuser.

### 3. Why are password hashes stored in `/etc/shadow`?

`/etc/passwd` must be broadly readable for identity resolution. `/etc/shadow` restricts access to password hashes and password-aging data.

### 4. What are the seven fields in `/etc/passwd`?

Username, password placeholder, UID, primary GID, comment/GECOS, home directory, and login shell.

### 5. Why use `getent passwd USER` instead of only searching `/etc/passwd`?

`getent` follows the configured identity sources and can resolve LDAP, Active Directory, SSSD, or other directory users in addition to local accounts.

### 6. What is the difference between a primary and supplementary group?

Each user has one primary group stored in the passwd identity record. A user can also belong to multiple supplementary groups for additional access.

### 7. Why is `usermod -aG` important?

`-aG` appends supplementary groups. Using `-G` without `-a` replaces the current supplementary-group list and may unintentionally remove access.

### 8. Why may new group membership not work in an existing session?

Supplementary groups are assigned to a process at login. Existing processes may retain their previous group list until a new session is created.

### 9. What is the difference between locking a password and expiring an account?

Password locking disables password authentication but may not stop SSH keys or other access. Account expiration marks the account unavailable after a specified date.

### 10. Does `passwd -l USER` terminate active sessions?

No. It locks password authentication but does not terminate existing sessions or necessarily block other authentication methods.

### 11. How do you display password-aging settings?

```bash
sudo chage -l USERNAME
```

### 12. How do you force a password change at the next login?

```bash
sudo chage -d 0 USERNAME
```

or:

```bash
sudo passwd -e USERNAME
```

### 13. What does `/sbin/nologin` do?

It prevents a normal interactive login and displays a message. It is commonly used for service accounts.

### 14. What is `/etc/skel`?

It contains template files that may be copied into a new user’s home directory during account creation.

### 15. Why use `visudo` instead of a normal editor?

`visudo` locks the sudoers policy during editing and validates syntax, reducing the risk of breaking administrative access.

### 16. What does `%wheel` mean in sudoers?

The `%` prefix identifies a Unix group. The rule applies to members of the `wheel` group.

### 17. How do you test what a user can run through sudo?

Current user:

```bash
sudo -l
```

Specified user, when authorized:

```bash
sudo -l -U USERNAME
```

### 18. Why is `NOPASSWD: ALL` risky?

It grants unrestricted root command execution without an authentication prompt. A compromised account can immediately become root.

### 19. What should you check before deleting an account?

I would verify authorization, active sessions, processes, scheduled jobs, services, files, data ownership, retention, backups, external identities, SSH keys, and whether disabling is more appropriate than deleting.

### 20. How would you troubleshoot a user who cannot log in?

I would confirm the identity source, examine account and password status, expiration, failure lockout, shell, home directory, SSH or PAM configuration, SSSD state, logs, and SELinux evidence while comparing with recent changes.

---

## 26. Quick Knowledge Check

### Questions

1. Which numeric UID has full root privileges?
2. Which file stores local user identity fields?
3. Which file stores protected password hashes and aging data?
4. Which command checks all configured identity sources for a user?
5. Which command displays a user’s UID, primary group, and supplementary groups?
6. What is the difference between `-G` and `-aG` in `usermod`?
7. Which command shows password-aging information?
8. Which command forces a password change at the next login?
9. Does locking a password necessarily disable SSH-key access?
10. Which shell is commonly used to prevent interactive login for a service account?
11. Which command safely edits sudo policy?
12. What does `%` mean before a name in sudoers?
13. Which command validates sudoers syntax?
14. Why might a user’s new group not work in an existing session?
15. Which read-only commands check passwd and group database integrity?

### Answer Key

1. UID `0`
2. `/etc/passwd`
3. `/etc/shadow`
4. `getent passwd USERNAME`
5. `id USERNAME`
6. `-G` replaces the supplementary-group list; `-aG` appends groups.
7. `chage -l USERNAME`
8. `chage -d 0 USERNAME` or `passwd -e USERNAME`
9. No. Password locking does not necessarily block SSH keys or other methods.
10. `/sbin/nologin`
11. `visudo`
12. It identifies a Unix group.
13. `visudo -c`
14. Existing processes retain the groups assigned when their session began.
15. `pwck -r` and `grpck -r`

---

## 27. Interview Practice Exercises

Answer each question aloud in 60–90 seconds.

### Exercise 1

> A developer was added to a Linux group but still cannot access the application directory. How would you troubleshoot it?

Your response should cover:

- Identity source
- `getent group`
- `id`
- Existing login session
- Ownership and permissions
- Parent-directory execute permission
- ACLs
- SELinux
- NFS or directory-service identity mapping

### Exercise 2

> A contractor’s access must end automatically at midnight on the contract end date. What would you configure and verify?

Your response should cover:

- Account-expiration date
- `chage -E` or `usermod -e`
- Verification with `chage -l`
- Directory and cloud access
- SSH keys
- Active sessions
- Scheduled jobs
- Audit and offboarding procedure

### Exercise 3

> A support engineer needs permission to check and restart only the `httpd` service. How would you implement it?

Your response should cover:

- Dedicated support group
- Least-privilege sudoers drop-in
- Exact command paths and arguments
- `visudo -f`
- Ownership and mode
- `visudo -c`
- Testing allowed and denied actions
- Logging and review

### Exercise 4

> An employee has left the company. Is `passwd -l` sufficient?

Your response should explain why it is not sufficient and mention:

- SSH keys
- Existing sessions
- Sudo
- Scheduled jobs
- Cloud and application access
- Tokens and service credentials
- Data ownership
- Documented offboarding

---

## 28. Module Completion Checklist

Mark each item when you can complete it without assistance:

- [ ] I can explain usernames, UIDs, groups, and GIDs.
- [ ] I can identify unexpected UID 0 accounts.
- [ ] I can explain all fields in `/etc/passwd`.
- [ ] I understand the purpose of `/etc/shadow`.
- [ ] I can use `getent` for local and enterprise identities.
- [ ] I can create a regular user and a service account.
- [ ] I can set the home directory, comment, and login shell.
- [ ] I can explain primary and supplementary groups.
- [ ] I know why `usermod -aG` is safer for adding membership.
- [ ] I can configure and verify password aging.
- [ ] I can explain password lock vs. account expiration.
- [ ] I understand why password locking may not block every access method.
- [ ] I can safely create and validate a sudoers drop-in.
- [ ] I can explain least-privilege sudo design.
- [ ] I can troubleshoot login, group, home-directory, and sudo failures.
- [ ] I completed the hands-on lab on a practice system.
- [ ] I answered the interview questions aloud.

---

## 29. Command Revision Sheet

```bash
whoami
id
id USERNAME
groups USERNAME
getent passwd USERNAME
getent group GROUPNAME
cat /etc/nsswitch.conf
useradd -D
sudo useradd -m -c "Comment" -s /bin/bash USERNAME
sudo useradd --system --shell /sbin/nologin SERVICE_USER
sudo passwd USERNAME
sudo passwd -S USERNAME
sudo passwd -l USERNAME
sudo passwd -u USERNAME
sudo passwd -e USERNAME
sudo usermod -c "Comment" USERNAME
sudo usermod -s /bin/bash USERNAME
sudo usermod -d /new/home -m USERNAME
sudo usermod -aG GROUPNAME USERNAME
sudo groupadd GROUPNAME
sudo gpasswd -a USERNAME GROUPNAME
sudo gpasswd -d USERNAME GROUPNAME
sudo chage -l USERNAME
sudo chage -d 0 USERNAME
sudo chage -m 1 -M 90 -W 14 -I 7 USERNAME
sudo chage -E YYYY-MM-DD USERNAME
sudo faillock --user USERNAME
sudo pwck -r
sudo grpck -r
sudo visudo
sudo visudo -f /etc/sudoers.d/POLICY_NAME
sudo visudo -c
sudo -l
sudo -l -U USERNAME
sudo -u USERNAME command
pgrep -u USERNAME -a
sudo crontab -l -u USERNAME
sudo userdel USERNAME
sudo userdel -r USERNAME
```

---

## Next Module

**Module 04 — Linux Permissions, ACLs, SUID, SGID, and Sticky Bit**

Topics will include:

- Ownership and permission classes
- Symbolic and octal permissions
- `chmod`, `chown`, and `chgrp`
- Default permissions and `umask`
- Directory permission behavior
- Access Control Lists
- SUID, SGID, and sticky bit
- Shared-team directories
- Security risks and audits
- Production troubleshooting scenarios
- Interview questions and a practical lab

