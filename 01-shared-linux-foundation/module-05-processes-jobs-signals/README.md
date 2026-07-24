# Module 05 — Processes, Jobs, Signals, and Resource Usage

**Track:** Shared Linux Foundation  
**Level:** Linux Systems Engineer I and II  
**Primary platform:** Red Hat Enterprise Linux

## Overview

This module explains how Linux creates, schedules, monitors, prioritizes, and terminates processes. It covers shell job control, Linux signals, process states, CPU and memory analysis, `/proc`, zombie processes, OOM events, and safe production troubleshooting.

## Learning Objectives

After completing this module, you should be able to:

- Explain PID, PPID, process ownership, and parent-child relationships.
- Identify running processes with `ps`, `pgrep`, `pidof`, `pstree`, and `top`.
- Explain common Linux process states.
- Manage foreground, background, stopped, and persistent jobs.
- Send appropriate signals and terminate processes safely.
- Use `nice` and `renice` to adjust CPU scheduling priority.
- Interpret CPU, memory, load-average, and process metrics.
- Inspect process information through `/proc`.
- Explain zombie and orphan processes.
- Investigate high CPU, memory pressure, blocked I/O, and OOM events.

## Module Contents

- [Complete Study Notes](study-notes.md)
- Process lifecycle, PID, and PPID
- Process states and `STAT` flags
- `ps`, `top`, `pgrep`, `pidof`, and `pstree`
- Foreground and background job control
- `nohup`, `disown`, and persistent sessions
- Linux signals and safe termination
- `nice`, `renice`, and `ionice`
- CPU, memory, load, and thread analysis
- `/proc` process inspection
- Zombie, orphan, and OOM troubleshooting
- Hands-on lab
- Production scenarios
- Interview questions and knowledge check

## Key Commands

```bash
ps -ef
ps aux
ps -eo pid,ppid,user,stat,ni,%cpu,%mem,etime,cmd --sort=-%cpu
pgrep -a process_name
pstree -p
top
jobs -l
bg %1
fg %1
kill -TERM PID
kill -KILL PID
nice -n 10 command
renice 10 -p PID
free -h
vmstat 1 5
pidstat -p PID 1
systemd-cgls
```

## Practical Outcome

You will create and control background jobs, stop and continue a process, send signals safely, adjust process priority, inspect `/proc`, and analyze a short controlled CPU workload.

## Completion Requirement

Complete the hands-on lab, explain the production scenarios aloud, and finish the knowledge check before proceeding.

## Navigation

- [Previous: Module 04 — Permissions, ACLs, and Special Bits](../module-04-permissions-acls-special-bits/README.md)
- Next: Module 06 — systemd Services and Linux Boot Process
