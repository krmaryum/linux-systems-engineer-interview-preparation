# Module 11 — Centralized Logging and Log Analysis

**Track:** Linux Systems Engineer I  
**Level:** Linux Systems Engineer I with Engineer II extensions  
**Primary platform:** Red Hat Enterprise Linux

## Overview

This module explains how Linux generates, stores, searches, forwards, protects, and analyzes operational logs. It covers systemd-journald, `journalctl`, rsyslog, syslog facilities and severities, persistent journals, local files, reliable remote forwarding, time correlation, incident evidence, and common logging failures.

## Learning Objectives

After completing this module, you should be able to:

- Explain the relationship between applications, journald, rsyslog, log files, and remote collectors.
- Query the system journal by boot, service, priority, process, field, and time range.
- Interpret realtime, monotonic, and UTC timestamps.
- Configure and verify persistent journal storage.
- Inspect journal disk use and retention controls safely.
- Explain syslog facilities, severities, selectors, actions, and templates.
- Validate rsyslog configuration before reloading the service.
- Design TCP, TLS, RELP, and queued remote-forwarding workflows.
- Generate controlled test events with `logger` and `systemd-cat`.
- Diagnose missing, delayed, duplicated, or unparseable logs.
- Collect a focused incident evidence bundle without altering source logs.
- Explain Engineer I and Engineer II logging responsibilities.

## Module Contents

- [Complete Study Notes](study-notes.md)
- Linux logging architecture
- Journal fields and structured metadata
- `journalctl` filtering and output formats
- Boot, kernel, service, user, and process logs
- Persistent versus volatile journal storage
- Disk usage, retention, vacuuming, and rate limiting
- rsyslog configuration model
- Facilities, severities, selectors, actions, and templates
- Remote logging over UDP, TCP, TLS, and RELP
- Action queues and outage behavior
- Time synchronization and cross-host correlation
- Security, permissions, integrity, and sensitive data
- Safe logging and incident-evidence labs
- Production scenarios and interview questions

## Key Commands

```bash
journalctl
journalctl -b
journalctl -b -1
journalctl --list-boots
journalctl -u SERVICE
journalctl -p warning
journalctl --since "1 hour ago"
journalctl -k
journalctl -o json-pretty
journalctl --disk-usage
journalctl --verify
systemctl status systemd-journald
systemctl status rsyslog
rsyslogd -N1
logger -t TAG "MESSAGE"
systemd-cat -t TAG
timedatectl
```

## Practical Outcome

You will generate tagged test events at multiple priorities, query structured journal fields, correlate events by time and process, export a focused evidence bundle with hashes, validate a sample rsyslog configuration, and clean up only the lab artifacts.

## Completion Requirement

Complete the labs and explain how you would investigate:

1. A service failure during the previous boot.
2. Logs visible in the journal but missing from `/var/log/messages`.
3. A client that stops forwarding during a collector outage.
4. Events from two servers that appear in the wrong order.
5. A remote logging rule that passes syntax validation but still receives nothing.

## Navigation

- [Previous: Module 10 — Linux Networking and SSH](../../01-shared-linux-foundation/module-10-networking-and-ssh/README.md)
- Next: Module 12 — Scheduled Tasks, systemd Timers, and Log Rotation
