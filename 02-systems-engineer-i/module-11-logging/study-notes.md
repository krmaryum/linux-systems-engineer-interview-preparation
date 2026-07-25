# Linux Systems Engineer II Interview Preparation

## Module 11 — Centralized Logging and Log Analysis

**Track:** Linux Systems Engineer I  
**Level:** Linux Systems Engineer I with Engineer II extensions  
**Primary platform:** Red Hat Enterprise Linux  
**Recommended study time:** 150 minutes

> **Evidence safety:** Logs may contain credentials, tokens, personal data, internal hostnames, IP addresses, commands, and business information. Collect only what the incident requires, preserve original timestamps and files, control access, record hashes when evidence integrity matters, and follow retention and privacy policy.

---

## 1. Module Objectives

After completing this module, you should be able to:

- Explain why production systems require structured and centralized logging.
- Describe the roles of systemd-journald and rsyslog.
- Identify common local log locations.
- Query the journal by boot, unit, priority, time, process, identifier, and field.
- Select useful `journalctl` output formats.
- Explain volatile and persistent journal storage.
- Inspect journal disk usage and retention controls.
- Interpret syslog facilities and severities.
- Read legacy selectors and modern RainerScript rules.
- Validate rsyslog configuration safely.
- Explain remote logging over UDP, TCP, TLS, and RELP.
- Design queues for collector outages.
- Correlate events across hosts using synchronized time.
- Diagnose missing, delayed, duplicated, and malformed logs.
- Produce a focused incident-evidence bundle.
- Explain logging expectations for Engineer I and Engineer II.

---

## 2. Why Logging Matters

Logs answer questions such as:

- What happened?
- When did it happen?
- Which host generated the event?
- Which service, process, user, or container was involved?
- What changed immediately before the failure?
- Did the event occur once or repeatedly?
- Was the event local or distributed?
- Did security controls allow or deny an action?
- Did the system recover?

Logs support:

- Troubleshooting
- Availability monitoring
- Security investigations
- Change validation
- Root cause analysis
- Capacity planning
- Compliance
- Audit trails
- Customer support

### Interview Principle

> A log message is evidence, not automatically the root cause. Correlate it with system state, metrics, changes, dependencies, and events on other systems.

---

## 3. Linux Logging Architecture

A common RHEL logging flow is:

```text
Kernel, services, applications, users
                 │
                 ▼
        systemd-journald
        structured journal
                 │
                 ├──────────► journalctl
                 │
                 ▼
              rsyslog
         rules and processing
            │            │
            ▼            ▼
     Local text files   Remote collector
```

Not every application follows exactly the same path.

Applications may:

- Write to standard output or standard error.
- Call the syslog API.
- Write directly to their own files.
- Send events directly to a remote platform.
- Write to the systemd journal API.
- Produce audit events.

An Engineer must identify the actual path for the service being investigated.

---

## 4. Main Logging Components

### systemd-journald

Service:

```text
systemd-journald.service
```

Responsibilities:

- Collect kernel messages.
- Collect service stdout and stderr.
- Accept messages through journal and syslog-compatible sockets.
- Attach structured metadata.
- Store entries in journal files.
- Provide indexed queries through `journalctl`.

### rsyslog

Service:

```text
rsyslog.service
```

Responsibilities:

- Receive messages from configured inputs.
- Filter, transform, and route messages.
- Write traditional text files.
- Forward messages to remote collectors.
- Use memory and disk-assisted queues.
- Support TCP, UDP, TLS, and RELP through modules.

### auditd

Service:

```text
auditd.service
```

Responsibilities include recording Linux Audit subsystem events.

Common file:

```text
/var/log/audit/audit.log
```

Audit logs have their own tools, rules, and integrity requirements. Do not treat them as ordinary application logs.

---

## 5. Journald Service Health

Check:

```bash
systemctl status systemd-journald
```

Unit properties:

```bash
systemctl show systemd-journald
```

Recent journal service logs:

```bash
sudo journalctl -u systemd-journald -b
```

Sockets:

```bash
systemctl status systemd-journald.socket
systemctl status systemd-journald-dev-log.socket
```

Check processes:

```bash
ps -ef | grep '[s]ystemd-journal'
```

The journal service is tightly integrated with systemd. Do not remove journal files or restart logging components casually during an incident.

---

## 6. Journal Storage Locations

Volatile journal:

```text
/run/log/journal/
```

Characteristics:

- Stored on a temporary filesystem.
- Lost at reboot.
- Useful when persistent storage is not configured.

Persistent journal:

```text
/var/log/journal/
```

Characteristics:

- Survives reboot.
- Enables previous-boot queries.
- Requires capacity and retention planning.

Check:

```bash
sudo ls -ld /run/log/journal /var/log/journal 2>/dev/null
```

Display boots known to the journal:

```bash
journalctl --list-boots
```

If only the current boot appears, persistent history may be unavailable, rotated, vacuumed, or never stored.

---

## 7. Journald Storage Modes

Main configuration:

```text
/etc/systemd/journald.conf
```

Drop-ins:

```text
/etc/systemd/journald.conf.d/*.conf
```

Important `Storage=` values:

| Value | Meaning |
|---|---|
| `volatile` | Store under `/run/log/journal` |
| `persistent` | Store under `/var/log/journal` |
| `auto` | Use persistent storage when its directory exists; otherwise volatile |
| `none` | Discard normal stored journal data while forwarding may still occur |

View compiled configuration:

```bash
systemd-analyze cat-config systemd/journald.conf
```

Check explicit settings:

```bash
grep -R '^[[:space:]]*Storage=' \
  /etc/systemd/journald.conf \
  /etc/systemd/journald.conf.d 2>/dev/null
```

---

## 8. Configuring Persistent Journal Storage

Use an approved drop-in:

```text
/etc/systemd/journald.conf.d/10-persistent.conf
```

Content:

```ini
[Journal]
Storage=persistent
```

Create the directory with systemd-managed ownership and permissions:

```bash
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
```

Validate the effective configuration:

```bash
systemd-analyze cat-config systemd/journald.conf
```

Apply under change control:

```bash
sudo systemctl restart systemd-journald
sudo journalctl --flush
```

Verify:

```bash
sudo journalctl --disk-usage
sudo ls -l /var/log/journal
journalctl --list-boots
```

Restarting a logging service can affect collection briefly. Plan and verify the change.

---

## 9. Basic `journalctl`

All accessible entries:

```bash
journalctl
```

Newest entries first:

```bash
journalctl -r
```

Follow new entries:

```bash
journalctl -f
```

Last 50:

```bash
journalctl -n 50
```

No pager:

```bash
journalctl --no-pager
```

Full lines:

```bash
journalctl --no-pager --full
```

Users may have limited access. Administrative queries often require:

```bash
sudo journalctl
```

---

## 10. Querying by Boot

Current boot:

```bash
journalctl -b
```

Previous boot:

```bash
journalctl -b -1
```

Two boots ago:

```bash
journalctl -b -2
```

List known boots:

```bash
journalctl --list-boots
```

Specific boot ID:

```bash
journalctl --boot=BOOT_ID
```

Previous-boot queries require those entries to still exist in the journal.

---

## 11. Querying Kernel Messages

Current boot:

```bash
journalctl -k
```

Explicit:

```bash
journalctl -k -b
```

Previous boot:

```bash
journalctl -k -b -1
```

Common kernel areas:

- Disk and filesystem errors
- NIC link changes
- Out-of-memory kills
- Driver failures
- SELinux AVC messages
- Hardware errors
- Kernel warnings
- Device discovery

Examples:

```bash
sudo journalctl -k -b | grep -iE 'error|fail|warn'
```

```bash
sudo journalctl -k -b | grep -i 'out of memory'
```

Do not rely only on keyword searches. They can miss structured context or include harmless text.

---

## 12. Querying by Service

One systemd unit:

```bash
journalctl -u sshd.service
```

Current boot:

```bash
journalctl -b -u sshd.service
```

Follow:

```bash
journalctl -f -u sshd.service
```

Since a time:

```bash
journalctl -u sshd.service --since "1 hour ago"
```

Multiple units:

```bash
journalctl -u sshd.service -u NetworkManager.service
```

Use complete unit names when precision matters.

---

## 13. Querying by Time

Since today:

```bash
journalctl --since today
```

Relative:

```bash
journalctl --since "30 minutes ago"
```

Exact range:

```bash
journalctl \
  --since "2026-07-25 09:00:00" \
  --until "2026-07-25 09:15:00"
```

UTC display:

```bash
journalctl --utc --since "2026-07-25 14:00:00"
```

Confirm timezone and clock state:

```bash
timedatectl
```

Always record whether incident timestamps are local time or UTC.

---

## 14. Syslog Severity Levels

Syslog severity values:

| Number | Name | Meaning |
|---:|---|---|
| 0 | `emerg` | System unusable |
| 1 | `alert` | Immediate action required |
| 2 | `crit` | Critical condition |
| 3 | `err` | Error condition |
| 4 | `warning` | Warning condition |
| 5 | `notice` | Normal but significant |
| 6 | `info` | Informational |
| 7 | `debug` | Debug detail |

Lower numbers are more severe.

Show warning and all more-severe entries:

```bash
journalctl -p warning
```

Exact range from emergency through error:

```bash
journalctl -p emerg..err
```

Errors for the current boot:

```bash
journalctl -b -p err
```

Severity is assigned by the event producer. A poorly designed application may use levels inconsistently.

---

## 15. Querying by Process and User

PID:

```bash
journalctl _PID=1234
```

Executable path:

```bash
journalctl _EXE=/usr/sbin/sshd
```

Command:

```bash
journalctl _COMM=sshd
```

User ID:

```bash
journalctl _UID=1000
```

Systemd user unit:

```bash
journalctl --user -u UNIT
```

PIDs are reused. Combine PID with boot ID, unit, executable, and time when possible.

---

## 16. Querying by Identifier

Many syslog-style messages include:

```text
SYSLOG_IDENTIFIER
```

Query:

```bash
journalctl SYSLOG_IDENTIFIER=sshd
```

The `-t` shortcut:

```bash
journalctl -t sshd
```

Generate a tagged event:

```bash
logger -t module11-test "logging test event"
```

Query:

```bash
sudo journalctl -t module11-test --since "5 minutes ago"
```

---

## 17. Structured Journal Fields

Show one entry verbosely:

```bash
journalctl -n 1 -o verbose
```

Common trusted fields:

| Field | Meaning |
|---|---|
| `_BOOT_ID` | Unique boot ID |
| `_MACHINE_ID` | Machine identity |
| `_HOSTNAME` | Hostname attached to entry |
| `_SYSTEMD_UNIT` | System unit |
| `_SYSTEMD_USER_UNIT` | User unit |
| `_PID` | Process ID |
| `_UID` | User ID |
| `_GID` | Group ID |
| `_COMM` | Command name |
| `_EXE` | Executable path |
| `_CMDLINE` | Process command line |
| `_TRANSPORT` | How journald received the message |
| `PRIORITY` | Syslog severity number |
| `SYSLOG_FACILITY` | Syslog facility number |
| `SYSLOG_IDENTIFIER` | Program or tag |
| `MESSAGE` | Human-readable message |

Fields beginning with `_` are generally trusted metadata added by the journal.

---

## 18. Combining Journal Matches

Different fields are combined as logical AND:

```bash
journalctl _SYSTEMD_UNIT=sshd.service _PID=1234
```

Multiple values for the same field act as alternatives:

```bash
journalctl \
  _SYSTEMD_UNIT=sshd.service \
  _SYSTEMD_UNIT=NetworkManager.service
```

Explicit disjunction:

```bash
journalctl \
  _SYSTEMD_UNIT=sshd.service \
  + \
  _SYSTEMD_UNIT=NetworkManager.service
```

Use a narrow time window in large journals.

---

## 19. Discovering Available Field Values

List known fields:

```bash
journalctl --fields
```

Values for one field:

```bash
journalctl -F _SYSTEMD_UNIT
```

Boot IDs:

```bash
journalctl -F _BOOT_ID
```

Identifiers:

```bash
journalctl -F SYSLOG_IDENTIFIER
```

This helps build accurate filters instead of guessing field values.

---

## 20. Journal Output Formats

### Default Short Format

```bash
journalctl -o short
```

### ISO Time

```bash
journalctl -o short-iso
```

### Precise ISO Time

```bash
journalctl -o short-iso-precise
```

### UTC ISO Time

```bash
journalctl --utc -o short-iso-precise
```

### Monotonic Time

```bash
journalctl -o short-monotonic
```

Useful for ordering events within one boot even if wall-clock time changes.

### Message Only

```bash
journalctl -o cat
```

### Verbose Fields

```bash
journalctl -o verbose
```

### JSON

```bash
journalctl -o json
journalctl -o json-pretty
```

### Export Format

```bash
journalctl -o export
```

Choose a format based on the consumer: human, script, SIEM, evidence archive, or parser.

---

## 21. Following Live Logs

All:

```bash
journalctl -f
```

One unit:

```bash
journalctl -f -u httpd.service
```

One identifier:

```bash
journalctl -f -t module11-test
```

Since now:

```bash
journalctl --since now -f
```

Live following is useful during a controlled reproduction, but capture the exact reproduction time and avoid leaving broad log streams unattended.

---

## 22. Journal Integrity Verification

Verify journal files:

```bash
sudo journalctl --verify
```

The command checks internal consistency.

Possible problems:

- Truncated journal
- Corrupt file
- Unexpected sequence
- Disk or filesystem issue

If corruption is detected:

1. Preserve the affected files.
2. Check storage and kernel errors.
3. Confirm backups or centralized copies.
4. Follow the supported recovery procedure.
5. Do not delete evidence immediately.

Verification does not prove that every expected event was generated or received.

---

## 23. Journal Disk Usage

Display:

```bash
sudo journalctl --disk-usage
```

Directories:

```bash
sudo du -sh /run/log/journal /var/log/journal 2>/dev/null
```

Filesystem:

```bash
df -hT /var/log
df -i /var/log
```

A full `/var` can affect:

- Logging
- Package management
- Services
- Databases
- Authentication
- Boot

Do not solve space incidents by deleting active log files blindly.

---

## 24. Journald Retention Controls

Useful settings include:

| Setting | Purpose |
|---|---|
| `SystemMaxUse=` | Maximum persistent journal use |
| `SystemKeepFree=` | Space journald should leave free |
| `RuntimeMaxUse=` | Maximum volatile journal use |
| `RuntimeKeepFree=` | Free space reserved on volatile filesystem |
| `MaxRetentionSec=` | Time-based retention |
| `MaxFileSec=` | Maximum time span per journal file |

Example drop-in:

```ini
[Journal]
SystemMaxUse=2G
SystemKeepFree=1G
MaxRetentionSec=30day
```

Retention design must consider:

- Incident investigation window
- Compliance
- Forwarding reliability
- Host storage
- Log volume
- Backup and SIEM retention

---

## 25. Rotating and Vacuuming the Journal

Rotate active journal files:

```bash
sudo journalctl --rotate
```

Vacuum archived files older than 14 days:

```bash
sudo journalctl --vacuum-time=14d
```

Reduce archived journal files toward 2 GiB:

```bash
sudo journalctl --vacuum-size=2G
```

Common controlled sequence:

```bash
sudo journalctl --rotate
sudo journalctl --vacuum-time=14d
```

Vacuuming removes historical data. Confirm retention requirements and preserve incident evidence first.

---

## 26. Journal Rate Limiting

Journald can suppress excessive messages to protect the system.

Relevant settings:

```text
RateLimitIntervalSec=
RateLimitBurst=
```

Symptoms:

- Messages indicate suppression.
- Application claims to log more than the journal contains.
- A failure loop floods logs.

Do not simply disable rate limiting. Fix the noisy source and size the logging pipeline appropriately.

Query journald messages:

```bash
sudo journalctl -u systemd-journald | grep -i suppress
```

---

## 27. Common Traditional Log Files

Depending on installed services and rsyslog rules:

| File | Typical content |
|---|---|
| `/var/log/messages` | General system messages |
| `/var/log/secure` | Authentication and authorization |
| `/var/log/cron` | Cron activity |
| `/var/log/maillog` | Mail services |
| `/var/log/boot.log` | Boot-related output |
| `/var/log/dnf.log` | DNF activity |
| `/var/log/audit/audit.log` | Linux Audit events |
| `/var/log/httpd/` | Apache logs |

List:

```bash
sudo find /var/log -maxdepth 2 -type f -printf '%p\n' | sort
```

Files vary by:

- Distribution
- Installed packages
- Application configuration
- rsyslog rules
- Container design
- Security policy

---

## 28. Safely Reading Text Logs

Last lines:

```bash
sudo tail -n 100 /var/log/messages
```

Follow:

```bash
sudo tail -F /var/log/messages
```

Search:

```bash
sudo grep -i 'error' /var/log/messages
```

Compressed rotated logs:

```bash
sudo zgrep -i 'error' /var/log/messages-*.gz
```

Time range with `awk` can be unreliable if formats vary. Prefer structured timestamps or purpose-built parsing where possible.

`tail -F` follows a filename across rotation more robustly than `tail -f`.

---

## 29. Rsyslog Health

Package:

```bash
rpm -q rsyslog
```

Service:

```bash
systemctl status rsyslog
```

Enablement:

```bash
systemctl is-enabled rsyslog
```

Logs:

```bash
sudo journalctl -u rsyslog -b
```

Process:

```bash
ps -ef | grep '[r]syslogd'
```

Configuration validation:

```bash
sudo rsyslogd -N1
```

Always validate before restarting or reloading.

---

## 30. Rsyslog Configuration Files

Main file:

```text
/etc/rsyslog.conf
```

Drop-ins:

```text
/etc/rsyslog.d/*.conf
```

List:

```bash
sudo find /etc/rsyslog.d -maxdepth 1 -type f -name '*.conf' -print | sort
```

Inspect effective text:

```bash
sudo grep -R --line-number --color=never \
  -v '^[[:space:]]*#' \
  /etc/rsyslog.conf /etc/rsyslog.d
```

Rsyslog supports:

- Legacy selector/action syntax
- Property-based filters
- Modern RainerScript
- Modules
- Rulesets
- Templates
- Queues

Prefer clear, supportable syntax that matches the organization’s standard.

---

## 31. Syslog Facilities

Facilities classify the source or purpose.

| Facility | Typical use |
|---|---|
| `auth` | Authentication |
| `authpriv` | Private authentication messages |
| `cron` | Scheduling services |
| `daemon` | System daemons |
| `kern` | Kernel |
| `mail` | Mail |
| `syslog` | Syslog subsystem |
| `user` | User-level messages |
| `local0`–`local7` | Custom application use |

Applications may use facilities differently. Confirm actual events.

Generate:

```bash
logger -p local0.notice -t module11-app "application notice"
```

---

## 32. Legacy Rsyslog Selectors

General form:

```text
FACILITY.PRIORITY    ACTION
```

Examples:

```text
authpriv.*           /var/log/secure
cron.*               /var/log/cron
*.info               /var/log/messages
```

Important:

```text
*.info
```

normally means informational and all more-severe priorities, not exactly `info`.

Exact priority:

```text
*.=info
```

Exclude a facility:

```text
mail.none
```

Multiple selectors:

```text
*.info;mail.none;authpriv.none;cron.none    /var/log/messages
```

Read the whole selector expression before interpreting a destination file.

---

## 33. Rsyslog Actions

An action defines what happens to matching messages.

Examples:

Write a file:

```text
*.notice    /var/log/notices.log
```

Forward UDP in legacy syntax:

```text
*.*    @logserver.example.com:514
```

Forward TCP in legacy syntax:

```text
*.*    @@logserver.example.com:514
```

Legacy meaning:

```text
@   UDP
@@  TCP
```

Modern RainerScript is clearer for queues, TLS, retries, and templates.

---

## 34. Modern RainerScript Filter

Example:

```rainerscript
if $programname == "inventory-api" then {
    action(
        type="omfile"
        file="/var/log/inventory-api.log"
    )
    stop
}
```

The `stop` statement prevents later rules from processing the same event.

Without `stop`, duplication may be expected if later rules also match.

Validate:

```bash
sudo rsyslogd -N1
```

---

## 35. Rsyslog Modules

Common module naming:

| Module | Purpose |
|---|---|
| `imjournal` | Input from systemd journal |
| `imuxsock` | Local Unix socket input |
| `imtcp` | TCP input |
| `imudp` | UDP input |
| `imrelp` | RELP input |
| `omfile` | File output |
| `omfwd` | Network forwarding |
| `omrelp` | RELP output |

Prefixes:

```text
im = input module
om = output module
```

Package installation may be required for TLS or RELP modules.

---

## 36. Journald and Rsyslog Integration

On RHEL, rsyslog commonly obtains journal events through:

```text
imjournal
```

Inspect:

```bash
sudo grep -R 'imjournal\\|imuxsock' \
  /etc/rsyslog.conf /etc/rsyslog.d 2>/dev/null
```

If an event exists in the journal but not in a text log, investigate:

- Is rsyslog installed and active?
- Is `imjournal` loaded?
- Does a selector match?
- Does `stop` prevent later processing?
- Can rsyslog write the destination?
- Is SELinux denying access?
- Is the destination filesystem full?
- Did rate limiting occur?

---

## 37. Validate Before Applying Rsyslog Changes

Syntax validation:

```bash
sudo rsyslogd -N1
```

More verbose validation:

```bash
sudo rsyslogd -N3
```

Check result:

```bash
echo $?
```

Expected success:

```text
0
```

After a valid approved change:

```bash
sudo systemctl restart rsyslog
```

Then verify:

```bash
sudo systemctl status rsyslog
sudo journalctl -u rsyslog --since "10 minutes ago"
logger -t module11-verify "rsyslog verification event"
```

Syntax success does not prove network, permissions, SELinux, certificates, or collector configuration.

---

## 38. Centralized Logging Benefits

Central collection provides:

- Logs after a host is lost
- Cross-host search
- Longer retention
- Access separation
- Security analytics
- Alerting
- Compliance reporting
- Incident timelines
- Reduced dependence on local disk

It also creates dependencies:

- Network
- DNS
- Certificates
- Collector capacity
- Queue storage
- Time synchronization
- Parsing
- Index lifecycle

Centralization must be monitored end to end.

---

## 39. Remote Logging Transport Comparison

| Transport | Strength | Limitation |
|---|---|---|
| UDP | Low overhead and simple | No delivery confirmation; messages can be lost |
| TCP | Ordered connection and retransmission | Connection alone does not guarantee collector processing |
| TCP with TLS | Encrypted and authenticated transport | Certificate and crypto lifecycle complexity |
| RELP | Application-level acknowledgments and reliable delivery design | Additional modules and configuration |

For sensitive or high-value logs, plain UDP is usually not sufficient.

---

## 40. TCP Forwarding with an Action Queue

Illustrative client rule:

```rainerscript
global(workDirectory="/var/lib/rsyslog")

action(
    name="centralForward"
    type="omfwd"
    target="logs.example.com"
    port="514"
    protocol="tcp"
    action.resumeRetryCount="-1"
    queue.type="LinkedList"
    queue.filename="central-fwd"
    queue.maxdiskspace="1g"
    queue.saveonshutdown="on"
)
```

Key ideas:

- Retry when collector is unavailable.
- Buffer messages in a queue.
- Use disk assistance when memory is insufficient.
- Set a bounded disk limit.
- Monitor queue growth.

Do not deploy this example without adapting DNS, transport security, queue sizing, permissions, SELinux, and collector requirements.

---

## 41. Remote TCP Receiver Concept

Illustrative server configuration:

```rainerscript
module(load="imtcp")

ruleset(name="remoteMessages") {
    action(
        type="omfile"
        file="/var/log/remote/messages.log"
    )
}

input(
    type="imtcp"
    port="514"
    ruleset="remoteMessages"
)
```

Production receiver work also requires:

- Firewall rule
- SELinux port and file contexts
- Directory ownership
- Rotation and retention
- Source authentication
- Transport encryption
- Capacity monitoring
- Per-host or per-tenant separation
- Parsing and timestamp policy

Do not open a log receiver to untrusted networks.

---

## 42. TLS-Encrypted Forwarding

TLS can provide:

- Confidentiality
- Integrity in transit
- Server authentication
- Optional client authentication

Rsyslog can use supported TLS stream drivers and certificate settings.

Plan:

- Trusted CA
- Server certificate identity
- Client certificates when required
- Private-key protection
- Expiration monitoring
- Rotation procedure
- Hostname verification
- Crypto-policy compatibility

Use the exact RHEL rsyslog TLS procedure for the installed version. Partial TLS configuration can silently weaken authentication or break forwarding.

---

## 43. RELP

Reliable Event Logging Protocol provides application-level acknowledgment for log delivery.

Typical modules:

```text
omrelp on sender
imrelp on receiver
```

Benefits:

- Improved delivery assurance
- Acknowledged transactions
- Useful where message loss is unacceptable

Requirements:

- `rsyslog-relp` and related packages
- Sender and receiver configuration
- Firewall and SELinux policy
- Queue design
- TLS when confidentiality is required

RELP reduces risk of message loss but does not replace monitoring or capacity planning.

---

## 44. Queue Concepts

Queue types may include:

- Direct
- Fixed array
- Linked list
- Disk

A common forwarding design uses a linked-list queue with disk assistance.

Important settings:

- Queue filename
- Maximum disk space
- Memory size
- High and low watermarks
- Batch size
- Save on shutdown
- Retry behavior

### Queue Questions

1. How long must the client survive a collector outage?
2. What is the event rate?
3. What is the average event size?
4. How much disk can the queue use?
5. What happens when the queue fills?
6. How will the backlog be monitored?
7. Can the collector absorb recovery bursts?

---

## 45. Basic Queue Capacity Estimate

Approximate:

```text
required bytes =
events per second
× average bytes per event
× outage seconds
× safety factor
```

Example:

```text
100 events/sec
× 500 bytes
× 3600 sec
= 180,000,000 bytes
```

Before overhead and safety margin, that is about 180 MB decimal.

Real planning must include:

- Queue metadata
- Protocol overhead
- Event bursts
- Filesystem reserve
- Retention
- Multiple actions

---

## 46. Preventing Forwarding Loops

A loop can occur when:

1. Client forwards to server.
2. Server processes the event.
3. Server forwards it back to client or itself.
4. Event repeats indefinitely.

Prevention:

- Separate local and remote rulesets.
- Use dedicated inputs and actions.
- Filter collector-generated events.
- Understand hostname and source metadata.
- Test with a unique tag.
- Monitor sudden event-rate growth.

Never test remote logging with an uncontrolled `*.*` rule before the routing path is understood.

---

## 47. Duplicate Logs

Possible causes:

- Event entered through two inputs.
- Two rules match and neither stops processing.
- Application writes a file and syslog simultaneously.
- Forwarder retries after uncertain acknowledgment.
- Collector ingests both local files and network events.
- Load-balanced receivers duplicate processing.

Investigate:

- Identical timestamps
- Message IDs or sequence numbers
- Input module
- Source address
- Rule path
- Collector pipeline

Some delivery systems prefer duplicates over loss. Deduplication must preserve legitimate repeated events.

---

## 48. Missing Logs

Ask where the event disappears:

```text
Application generated?
    ↓
Local journal received?
    ↓
Rsyslog input received?
    ↓
Rule matched?
    ↓
Queue accepted?
    ↓
Network sent?
    ↓
Collector received?
    ↓
Parser accepted?
    ↓
Index searchable?
```

Test each boundary.

Useful commands:

```bash
logger -p local0.notice -t module11-test "pipeline test"
sudo journalctl -t module11-test
sudo journalctl -u rsyslog
sudo rsyslogd -N1
sudo ss -ntp
sudo tcpdump -ni any port 514
```

Use authorized, narrow packet capture.

---

## 49. Delayed Logs

Possible causes:

- Client queue backlog
- Collector overload
- Network interruption
- DNS delay
- TLS negotiation failures
- Parser backlog
- Indexing delay
- Incorrect event timestamp
- Clock skew

Distinguish:

- Event creation time
- Client receipt time
- Forwarding time
- Collector receipt time
- Index time

A dashboard may display event time while operational metrics report ingest time.

---

## 50. Time Synchronization

Check:

```bash
timedatectl
```

Chrony:

```bash
chronyc tracking
chronyc sources -v
```

Important properties:

- Timezone
- NTP synchronization
- Clock offset
- Leap status
- Source health

Cross-host incident analysis is unreliable when clocks differ.

Use UTC for centralized correlation when possible:

```bash
journalctl --utc -o short-iso-precise
```

---

## 51. Realtime vs. Monotonic Time

### Realtime

Calendar time:

```text
2026-07-25 10:15:30
```

Can jump because of:

- Manual adjustment
- NTP correction
- VM resume
- Bad hardware clock

### Monotonic

Time since boot from a clock designed not to move backward.

View:

```bash
journalctl -o short-monotonic
```

Use monotonic time to order events within one boot. It cannot directly correlate separate hosts or boots.

---

## 52. Hostname and Source Identity

Central logs may identify sources by:

- Hostname
- FQDN
- IP address
- Machine ID
- Cloud instance ID
- Certificate identity
- Agent ID

Risks:

- Duplicate hostnames
- Hostname changes
- NAT
- Reused IP addresses
- Cloned machine IDs
- Untrusted message-provided hostname

Engineer II designs stable source identity and validates it at the collector.

---

## 53. Sensitive Data in Logs

Never intentionally log:

- Passwords
- Private keys
- Session tokens
- API secrets
- Full payment data
- Unnecessary personal data

Review:

- Application logging code
- Debug mode
- HTTP headers
- Command-line arguments
- Environment variables
- Database query logs

If secrets are discovered:

1. Restrict access.
2. Follow incident handling.
3. Rotate exposed credentials.
4. Correct the log source.
5. Apply approved redaction and retention steps.

Deleting one local line does not remove copies from collectors, backups, or indexes.

---

## 54. Log Permissions

Inspect:

```bash
sudo find /var/log -maxdepth 2 -type f -printf '%m %u %g %p\n' | sort
```

Access principles:

- Least privilege
- Separate operational and security roles
- Protect authentication and audit logs
- Avoid world-readable sensitive files
- Preserve service write access
- Use groups or ACLs according to policy

Do not recursively chmod `/var/log`. Different files require different ownership and permissions.

---

## 55. Log Integrity

Integrity controls may include:

- Restricted write access
- Remote forwarding
- Immutable or append-oriented storage
- Hashes
- Signed journal features
- Object-lock retention
- SIEM access controls
- Audit trails

For an evidence copy:

```bash
sha256sum evidence-file.log
```

Record:

- Collection command
- Source host
- Time and timezone
- Collector
- Hash
- Access history

A hash proves whether the copied file changed after hashing; it does not prove the source event was truthful.

---

## 56. Incident Log Collection Workflow

1. Define the incident time window.
2. Confirm timezone and clock synchronization.
3. Identify affected hosts and services.
4. Preserve original sources.
5. Collect focused logs.
6. Capture configuration and service state.
7. Hash collected artifacts when required.
8. Restrict access.
9. Build a timeline.
10. Separate facts, inference, and unknowns.

Example focused collection:

```bash
sudo journalctl \
  -u sshd.service \
  --since "2026-07-25 09:00:00" \
  --until "2026-07-25 09:30:00" \
  --utc \
  -o short-iso-precise \
  --no-pager
```

---

## 57. Evidence Quality

Good evidence is:

- Relevant
- Time-bounded
- Reproducible
- Minimally altered
- Access-controlled
- Attributed to a source
- Accompanied by context

Weak evidence:

- Screenshot without hostname or time
- Copied lines without source
- Keyword-only extract that omits surrounding events
- Local time without timezone
- File modified during collection
- Unverified event from an unknown source

---

## 58. Correlation Example

Incident:

```text
Customer request failed at 14:02:15 UTC.
```

Possible timeline:

```text
14:02:10 Load balancer marks backend unhealthy
14:02:11 Application starts returning 503
14:02:12 Database connection timeout appears
14:02:13 Kernel reports packet drops
14:02:15 Customer request fails
14:02:20 Network route recovers
14:02:23 Application health check succeeds
```

Do not assume the earliest visible error is the root cause. Compare change records, metrics, network state, and dependent services.

---

## 59. Logging and Containers

Containers often write to:

```text
stdout
stderr
```

The container runtime or orchestrator collects those streams.

Podman example:

```bash
podman logs CONTAINER
podman logs --since 30m CONTAINER
```

Systemd-managed container logs may also appear in:

```bash
journalctl -u CONTAINER_UNIT
```

Questions:

- Which log driver is configured?
- Does the application also write inside the container?
- Are container IDs ephemeral?
- Is metadata attached?
- Is multiline handling correct?
- What is the retention policy?

---

## 60. Multiline Logs

Stack traces and exceptions may span multiple lines.

Risks:

- Each line becomes a separate event.
- Parser loses event boundaries.
- Search results become confusing.
- Alerts trigger on partial messages.

Solutions may include:

- Structured JSON logging
- Application-side single-event formatting
- Collector multiline parser
- Known start-line patterns

Multiline rules must be tested against normal and malformed input to avoid combining unrelated events.

---

## 61. Structured Logging

Structured event example:

```json
{
  "timestamp": "2026-07-25T14:02:15.123456Z",
  "level": "error",
  "service": "inventory-api",
  "request_id": "req-12345",
  "message": "database timeout",
  "duration_ms": 3000
}
```

Benefits:

- Reliable field search
- Better alert rules
- Easier correlation
- Reduced parsing ambiguity

Requirements:

- Stable schema
- Field types
- Versioning
- Sensitive-data controls
- Timestamp standard
- Request or trace IDs

---

## 62. Common Logging Failure: Journal Has Logs, File Does Not

Check:

```bash
sudo journalctl -t IDENTIFIER --since "10 minutes ago"
systemctl status rsyslog
sudo journalctl -u rsyslog -b
sudo rsyslogd -N1
```

Inspect rules:

```bash
sudo grep -R --line-number 'IDENTIFIER\\|FACILITY' \
  /etc/rsyslog.conf /etc/rsyslog.d
```

Check destination:

```bash
df -hT /var/log
df -i /var/log
sudo ls -lZ /var/log/DESTINATION
```

Possible cause:

- No matching rule
- `stop` before destination
- Permission or SELinux denial
- Full filesystem
- rsyslog inactive
- imjournal state problem

---

## 63. Common Logging Failure: Client Cannot Reach Collector

Resolve:

```bash
getent hosts logs.example.com
```

Route:

```bash
ip route get COLLECTOR_IP
```

TCP test:

```bash
nc -vz logs.example.com 514
```

Connection state:

```bash
sudo ss -ntp | grep ':514'
```

Packet capture:

```bash
sudo tcpdump -ni any host COLLECTOR_IP and port 514
```

Also inspect:

- Client queue
- Firewall
- SELinux
- TLS certificate
- Collector listener
- Collector disk and service

---

## 64. Common Logging Failure: TLS Handshake

Possible causes:

- Expired certificate
- Wrong hostname
- Untrusted CA
- Missing client certificate
- Permission on private key
- Crypto-policy mismatch
- Clock incorrect

Collect:

```bash
timedatectl
sudo journalctl -u rsyslog --since "15 minutes ago"
```

Inspect certificate metadata with approved tools:

```bash
openssl x509 -in CERTIFICATE.pem -noout -subject -issuer -dates
```

Do not disable certificate verification to make the connection work.

---

## 65. Common Logging Failure: Full Queue Disk

Symptoms:

- Forwarding stops.
- Rsyslog reports queue errors.
- `/var` fills.
- Applications experience indirect failures.

Check:

```bash
df -hT /var
df -i /var
sudo journalctl -u rsyslog -p warning
sudo du -xhd1 /var/lib/rsyslog 2>/dev/null
```

Response:

1. Protect host stability.
2. Restore collector connectivity or capacity.
3. Confirm queue integrity.
4. Avoid deleting queue files manually.
5. Monitor backlog drain.
6. Correct sizing and alerting.

---

## 66. Common Logging Failure: Wrong Event Order

Check clocks:

```bash
timedatectl
chronyc tracking
chronyc sources -v
```

Compare:

- Event timestamp
- Receive timestamp
- Ingest timestamp
- Timezone
- Monotonic ordering on each host

Possible causes:

- Clock skew
- Buffered forwarding
- Queue replay
- Incorrect application timestamp
- Parser timezone assumption
- VM suspend and resume

---

## 67. Common Logging Failure: Rsyslog Restart Fails

Check:

```bash
sudo rsyslogd -N1
sudo systemctl status rsyslog
sudo journalctl -u rsyslog -b
```

Typical causes:

- Syntax error
- Missing module package
- Duplicate input port
- Bad file path
- Permission or SELinux denial
- Certificate path error
- Invalid queue directory

Rollback the specific approved change. Do not delete all rsyslog configuration.

---

## 68. Hands-On Lab 1 — Generate and Analyze Journal Events

This lab creates tagged journal messages. It does not change system logging configuration.

### Step 1 — Set a Unique Tag

```bash
lab_tag="module11-${USER}-$(date +%s)"
printf 'Lab tag: %s\n' "$lab_tag"
```

Use the same shell for all steps.

### Step 2 — Generate Events

```bash
logger -p user.info -t "$lab_tag" "phase=start status=ok"
logger -p user.notice -t "$lab_tag" "phase=check status=ok"
logger -p user.warning -t "$lab_tag" "phase=capacity status=warning usage=85"
logger -p user.err -t "$lab_tag" "phase=dependency status=failed code=42"
```

Send through `systemd-cat`:

```bash
echo "phase=systemd-cat status=ok" | systemd-cat -t "$lab_tag" -p info
```

### Step 3 — Query by Tag

```bash
sudo journalctl -t "$lab_tag" --since "10 minutes ago" --no-pager
```

### Step 4 — Query Warning and More Severe

```bash
sudo journalctl \
  -t "$lab_tag" \
  -p warning \
  --since "10 minutes ago" \
  --no-pager
```

### Step 5 — Show Precise UTC Timestamps

```bash
sudo journalctl \
  -t "$lab_tag" \
  --since "10 minutes ago" \
  --utc \
  -o short-iso-precise \
  --no-pager
```

### Step 6 — Inspect Structured Fields

```bash
sudo journalctl \
  -t "$lab_tag" \
  -n 1 \
  -o verbose \
  --no-pager
```

Find:

- `MESSAGE`
- `PRIORITY`
- `SYSLOG_IDENTIFIER`
- `_PID`
- `_UID`
- `_BOOT_ID`
- `_HOSTNAME`
- `_TRANSPORT`

### Step 7 — JSON Output

```bash
sudo journalctl \
  -t "$lab_tag" \
  --since "10 minutes ago" \
  -o json-pretty \
  --no-pager
```

### Step 8 — Count Events

```bash
sudo journalctl \
  -t "$lab_tag" \
  --since "10 minutes ago" \
  -o cat \
  --no-pager | wc -l
```

Expected: at least five messages.

### Step 9 — Explain Results

You should be able to explain:

- Why `-p warning` includes the error message.
- Which metadata was attached by journald.
- Difference between event text and trusted fields.
- Why UTC and precise timestamps help correlation.

---

## 69. Hands-On Lab 2 — Focused Evidence Bundle

This lab exports only your tagged test events.

Continue in the same shell used for Lab 1. Confirm that the tag is set:

```bash
test -n "${lab_tag:-}" && printf 'Using tag: %s\n' "$lab_tag"
```

If no tag is displayed, set `lab_tag` to the exact tag printed by Lab 1 before continuing.

### Step 1 — Create a Protected Directory

```bash
evidence_dir="$(mktemp -d -p "$PWD" 'module11-evidence.XXXXXX')"
chmod 700 "$evidence_dir"
printf 'Evidence directory: %s\n' "$evidence_dir"
```

### Step 2 — Export Human-Readable Events

```bash
sudo journalctl \
  -t "$lab_tag" \
  --since "30 minutes ago" \
  --utc \
  -o short-iso-precise \
  --no-pager >"$evidence_dir/events.log"
```

### Step 3 — Export Structured Events

```bash
sudo journalctl \
  -t "$lab_tag" \
  --since "30 minutes ago" \
  -o json \
  --no-pager >"$evidence_dir/events.jsonl"
```

### Step 4 — Record Host and Time Context

```bash
{
  printf 'collection_time_utc='
  date -u '+%Y-%m-%dT%H:%M:%S.%NZ'
  printf 'hostname='
  hostnamectl --static
  printf 'lab_tag=%s\n' "$lab_tag"
  printf 'boot_id='
  cat /proc/sys/kernel/random/boot_id
  timedatectl
} >"$evidence_dir/context.txt"

chmod 600 \
  "$evidence_dir/events.log" \
  "$evidence_dir/events.jsonl" \
  "$evidence_dir/context.txt"
```

### Step 5 — Hash the Bundle

```bash
(
  cd "$evidence_dir"
  sha256sum events.log events.jsonl context.txt >SHA256SUMS
)
```

### Step 6 — Verify

```bash
(
  cd "$evidence_dir"
  sha256sum -c SHA256SUMS
)
```

### Step 7 — Inspect

```bash
find "$evidence_dir" -maxdepth 1 -type f -printf '%m %u %g %p\n' | sort
```

The bundle is a lab artifact, not a formal forensic acquisition.

### Cleanup

After reviewing and when no longer required:

```bash
(
  set -euo pipefail
  : "${evidence_dir:?Evidence directory is not set}"

  case "$evidence_dir" in
    "$PWD"/module11-evidence.*) ;;
    *)
      printf 'Safety check failed: %s\n' "$evidence_dir" >&2
      exit 1
      ;;
  esac

  rm -f "$evidence_dir/events.log"
  rm -f "$evidence_dir/events.jsonl"
  rm -f "$evidence_dir/context.txt"
  rm -f "$evidence_dir/SHA256SUMS"
  rmdir "$evidence_dir"
)
```

The original journal entries expire according to normal retention; the lab does not alter them.

---

## 70. Hands-On Lab 3 — Validate Rsyslog and Trace a Test Message

This lab inspects the current configuration and sends one tagged event. It does not edit rsyslog files or restart the service.

### Step 1 — Confirm Package and Service

```bash
rpm -q rsyslog
systemctl status rsyslog --no-pager
```

If rsyslog is not installed, review the commands without installing it unless the practice system allows package changes.

### Step 2 — Validate Configuration

```bash
sudo rsyslogd -N1
```

Record the exit status:

```bash
echo $?
```

### Step 3 — Inspect Inputs

```bash
sudo grep -R --line-number 'imjournal\\|imuxsock' \
  /etc/rsyslog.conf /etc/rsyslog.d 2>/dev/null
```

### Step 4 — Send a Unique Event

```bash
rsyslog_tag="module11-rsyslog-${USER}-$(date +%s)"
logger -p local0.notice -t "$rsyslog_tag" "rsyslog path verification"
```

### Step 5 — Confirm Journal Receipt

```bash
sudo journalctl -t "$rsyslog_tag" --since "5 minutes ago" --no-pager
```

### Step 6 — Search Traditional Logs

```bash
sudo grep -R --fixed-strings "$rsyslog_tag" \
  /var/log/messages /var/log/syslog 2>/dev/null
```

The file location depends on distribution and rules. RHEL commonly uses `/var/log/messages`; Debian-family systems commonly use `/var/log/syslog`.

### Step 7 — Interpret

If the journal contains the event but no searched file does:

- Do not assume failure.
- Inspect the configured selectors and actions.
- Confirm whether `local0.notice` should be written locally.
- Check rsyslog service logs.

---

## 71. Production Scenario — Previous-Boot Service Failure

Request:

```text
Why did the application fail during the previous boot?
```

Start:

```bash
journalctl --list-boots
sudo journalctl -b -1 -u application.service
sudo journalctl -b -1 -p warning
sudo journalctl -k -b -1
```

Correlate:

- Dependency failures
- Mounts
- Network readiness
- DNS
- Credentials
- Resource exhaustion
- Package or configuration changes
- Boot timing

If previous boot data is absent, document the observability gap and correct persistent logging for future incidents.

---

## 72. Production Scenario — Authentication Investigation

Define:

- Username
- Source address
- Host
- Time range
- Authentication method

Queries:

```bash
sudo journalctl \
  -u sshd.service \
  --since "2026-07-25 09:00:00" \
  --until "2026-07-25 10:00:00" \
  --utc \
  -o short-iso-precise
```

Text file where applicable:

```bash
sudo grep 'USERNAME' /var/log/secure
```

Audit:

```bash
sudo ausearch -ts 09:00:00 -te 10:00:00 -m USER_LOGIN,USER_AUTH
```

Protect authentication evidence and avoid exposing unrelated user data.

---

## 73. Production Scenario — Collector Outage

Determine:

- When forwarding stopped
- Which clients are affected
- Whether local logging continues
- Queue size and growth
- Local disk free space
- Collector service and listener
- Network and TLS state

Client:

```bash
sudo journalctl -u rsyslog --since "1 hour ago"
df -hT /var
sudo ss -ntp
```

Collector:

```bash
sudo systemctl status rsyslog
sudo ss -lntup
df -hT /var/log
```

After recovery:

- Monitor backlog drain.
- Watch collector load.
- Confirm no queue overflow.
- Compare test event creation and receipt.
- Document any gap.

---

## 74. Production Scenario — `/var/log` Full

Inspect:

```bash
df -hT /var/log
df -i /var/log
sudo du -xhd1 /var/log | sort -h
sudo journalctl --disk-usage
```

Check deleted-open files:

```bash
sudo lsof +L1
```

Safe response:

1. Identify the growth source.
2. Protect active services.
3. Preserve incident evidence.
4. Use approved rotation or retention procedures.
5. Fix the noisy service or failed rotation.
6. Add monitoring.

Do not truncate or delete unknown active logs.

---

## 75. Production Scenario — Change Verification

After a patch or configuration change:

```bash
change_start_utc="2026-07-25 14:00:00"
```

Review:

```bash
sudo journalctl \
  --since "$change_start_utc" \
  --utc \
  -p warning \
  --no-pager
```

Specific service:

```bash
sudo journalctl \
  -u SERVICE \
  --since "$change_start_utc" \
  --utc \
  -o short-iso-precise \
  --no-pager
```

Confirm:

- Service state
- Expected restart
- No new errors
- Dependency health
- Application transaction
- Monitoring
- Customer impact

---

## 76. Production Scenario — No Logs from One Application

Ask:

1. Is the application running?
2. Where is it configured to log?
3. Is log level too restrictive?
4. Does it write stdout, file, syslog, or network?
5. Can it write the target?
6. Is the filesystem full?
7. Is rotation holding a stale file descriptor?
8. Is journald rate limiting?
9. Is rsyslog filtering it?
10. Is the collector parser rejecting it?

Commands:

```bash
systemctl status APPLICATION
systemctl cat APPLICATION
sudo journalctl -u APPLICATION
sudo lsof -p PID | grep -i log
```

---

## 77. Interview Questions and Model Answers

### 1. What is systemd-journald?

It is the systemd logging service that collects kernel, service, and local messages, attaches structured metadata, and stores them in journal files.

### 2. What is rsyslog?

It is a log-processing service that receives messages, applies rules, writes files, and forwards events to remote collectors.

### 3. How do journald and rsyslog work together on RHEL?

Journald collects events. Rsyslog commonly reads journal events through `imjournal`, then writes traditional files or forwards them.

### 4. How do you view logs from the current boot?

Use `journalctl -b`.

### 5. How do you view the previous boot?

Use `journalctl -b -1`, provided those journal entries persist.

### 6. How do you query one service for the last hour?

Use `journalctl -u SERVICE --since "1 hour ago"`.

### 7. What does `journalctl -p warning` show?

Warning-priority messages and all more-severe priorities.

### 8. What is the difference between persistent and volatile journal storage?

Persistent data under `/var/log/journal` survives reboot. Volatile data under `/run/log/journal` does not.

### 9. How do you check journal disk usage?

Use `journalctl --disk-usage`.

### 10. What does `journalctl --verify` do?

It verifies the internal consistency of journal files.

### 11. What are syslog facilities?

They classify the source or functional category of a message, such as `authpriv`, `cron`, `daemon`, or `local0`.

### 12. What are syslog priorities?

Severity levels from 0 `emerg` through 7 `debug`.

### 13. What does `*.info` mean in a traditional selector?

All facilities at informational priority and all more-severe priorities, subject to exclusions.

### 14. Why use `rsyslogd -N1`?

It validates rsyslog configuration syntax before applying a change.

### 15. What is the difference between UDP and TCP logging?

UDP has low overhead but no delivery acknowledgment. TCP provides a reliable byte stream and retransmission, but collector processing still requires queue and monitoring design.

### 16. Why use TLS for remote logs?

To encrypt events in transit and authenticate the remote endpoint using certificates.

### 17. What is RELP?

Reliable Event Logging Protocol provides application-level acknowledgment designed to reduce message loss.

### 18. Why are action queues important?

They buffer events when a remote collector is unavailable, reducing loss and allowing later delivery.

### 19. What happens when a queue fills?

Behavior depends on configuration, but messages may be blocked, discarded, or cause disk pressure. It must be monitored and sized.

### 20. Why is time synchronization essential?

Without synchronized clocks, cross-host timelines can be misleading and root cause analysis becomes unreliable.

### 21. Why can an event exist in the journal but not `/var/log/messages`?

Rsyslog may be stopped, no selector may match, an earlier rule may stop processing, or permissions, SELinux, or disk capacity may prevent writing.

### 22. Why might logs arrive late?

Client queues, outages, TLS or DNS delay, collector backlog, parsing delay, or timestamp errors.

### 23. How do you preserve a log extract as evidence?

Record source, time range, timezone, and collection command; write to a protected location; hash the copy; and control access.

### 24. Does a hash prove the original log event is true?

No. It proves the hashed copy has not changed since hashing. Source authenticity and completeness require other controls.

### 25. What does an Engineer II add to logging work?

Pipeline architecture, reliability and security design, queue capacity, time and identity standards, cross-team coordination, compliance, root cause, and prevention.

---

## 78. Quick Knowledge Check

1. Which command shows known boot histories?
2. Which option filters one systemd unit?
3. Which option follows new journal entries?
4. Where is volatile journal data stored?
5. Where is persistent journal data stored?
6. Which severity number is `err`?
7. Which command validates rsyslog configuration?
8. What module commonly reads systemd journal entries into rsyslog?
9. What does one `@` mean in legacy forwarding syntax?
10. What do two `@@` characters mean?
11. Which transport adds application-level acknowledgments?
12. Why is a disk-assisted queue useful?
13. Which command generates a syslog event?
14. Which command displays time synchronization state?
15. Why use `short-iso-precise`?

### Answers

1. `journalctl --list-boots`
2. `-u UNIT`
3. `-f`
4. `/run/log/journal`
5. `/var/log/journal`
6. 3
7. `rsyslogd -N1`
8. `imjournal`
9. UDP forwarding
10. TCP forwarding
11. RELP
12. It buffers events beyond memory during collector outages
13. `logger`
14. `timedatectl`; use `chronyc tracking` for chrony detail
15. It provides precise ISO timestamps that improve event correlation

---

## 79. Engineer I vs. Engineer II Expectations

| Area | Engineer I | Engineer II |
|---|---|---|
| Journal queries | Filters by unit, time, boot, and priority | Builds cross-host timelines and distinguishes event, receive, and ingest time |
| Rsyslog | Reads selectors and validates changes | Designs rulesets, templates, queues, TLS, RELP, and failure behavior |
| Troubleshooting | Finds local service and log errors | Traces an event through the complete pipeline |
| Centralization | Understands client and collector roles | Designs capacity, identity, reliability, security, and retention |
| Evidence | Exports focused logs | Defines preservation, hashing, access, and incident standards |
| Time | Checks timezone and NTP | Resolves skew, buffering, timestamp semantics, and ordering |
| Security | Protects log access | Prevents sensitive-data leakage and designs trusted transport and storage |
| Monitoring | Checks service status | Alerts on gaps, queue depth, lag, parsing failures, and collector saturation |
| Leadership | Escalates pipeline issues | Coordinates application, platform, network, security, and compliance teams |

---

## 80. Module Completion Checklist

- [ ] I can explain journald and rsyslog.
- [ ] I can query current and previous boots.
- [ ] I can filter by unit, priority, time, PID, and identifier.
- [ ] I understand structured journal fields.
- [ ] I can choose human and machine output formats.
- [ ] I understand persistent journal storage.
- [ ] I can inspect retention and disk usage.
- [ ] I know all eight syslog severity levels.
- [ ] I understand common facilities.
- [ ] I can interpret legacy selectors.
- [ ] I can validate rsyslog configuration.
- [ ] I understand UDP, TCP, TLS, and RELP tradeoffs.
- [ ] I understand action queues.
- [ ] I can troubleshoot missing and delayed logs.
- [ ] I understand time correlation.
- [ ] I can build a focused evidence bundle.
- [ ] I completed all safe labs.
- [ ] I can answer the interview questions without notes.

---

## 81. Command Revision Sheet

### Journal Basics

```bash
journalctl -b
journalctl -b -1
journalctl --list-boots
journalctl -k
journalctl -u SERVICE
journalctl -p warning
journalctl --since "1 hour ago"
journalctl -f
```

### Fields and Formats

```bash
journalctl -o verbose
journalctl -o short-iso-precise
journalctl --utc -o short-iso-precise
journalctl -o json-pretty
journalctl -F _SYSTEMD_UNIT
journalctl SYSLOG_IDENTIFIER=TAG
```

### Storage and Integrity

```bash
sudo journalctl --disk-usage
sudo journalctl --verify
sudo journalctl --rotate
sudo journalctl --vacuum-time=14d
```

### Rsyslog

```bash
systemctl status rsyslog
sudo journalctl -u rsyslog
sudo rsyslogd -N1
logger -p local0.notice -t TAG "MESSAGE"
```

### Time and Evidence

```bash
timedatectl
chronyc tracking
chronyc sources -v
sha256sum FILE
sha256sum -c SHA256SUMS
```

---

## 82. Official References

Verify production behavior against the documentation and man pages for the installed RHEL release:

- [RHEL 9 — Troubleshooting Problems by Using Log Files](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_basic_system_settings/assembly_troubleshooting-problems-using-log-files_configuring-basic-system-settings)
- [RHEL 9 — Configuring a Remote Logging Solution](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/security_hardening/assembly_configuring-a-remote-logging-solution_security-hardening)
- `man journalctl`
- `man systemd-journald`
- `man journald.conf`
- `man logger`
- `man rsyslogd`
- Rsyslog documentation installed with the package

---

## Next Module

**Module 12 — Scheduled Tasks, systemd Timers, and Log Rotation**

Topics will include:

- One-time scheduling with `at`
- Recurring jobs with cron
- User and system crontabs
- Environment and PATH problems
- systemd timer units
- Calendar and monotonic timers
- Persistent and randomized timers
- Timer troubleshooting
- Logrotate configuration
- Rotation, compression, retention, and post-rotate actions
- Safe scheduling labs
- Production scenarios and interview questions
