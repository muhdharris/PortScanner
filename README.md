# PortScanner

A TCP port scanner in Ruby. Scans a target host across a port list and prints the
results as a table.

Written to understand what actually happens on the wire during a port scan, rather
than to wrap an existing library.

## What it does

- Scans a target IP or hostname across a set of ports
- Runs each port in its own thread, so the scan takes as long as the slowest port
  rather than the sum of all of them
- Uses a non-blocking connect with `IO.select` and a 2 second timeout
- Reports each port as Open or Closed, with a summary count

```bash
ruby port_scanner.rb
```

Prompts for a target and a port choice — either the defaults (21, 22, 23, 25, 53,
80, 443, 3306, 8080) or your own list.

## Requirements

```bash
gem install terminal-table
```

## How it works

The interesting part is `scan_port`. A blocking `connect` would hold the thread for
the full timeout on a closed port, which is why the scanner uses
`connect_nonblock` and then waits on `IO.select` — the thread is released while the
kernel finishes the handshake.

That is also why the threading matters: with a blocking connect, N closed ports
means N × 2 seconds. With non-blocking connects and threads, the whole scan finishes
in about 2 seconds regardless of how many ports are open.

## Legal note

Only scan hosts you own or have written permission to test. Scanning systems you
do not control is unlawful in most jurisdictions regardless of intent.
