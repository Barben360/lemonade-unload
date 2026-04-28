# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Automatically unload idle LLM models from a running [AMD lemonade server](https://lemonade-server.ai/) via a systemd user timer. The lemonade server keeps models in GPU memory indefinitely; this tooling frees that memory after a configurable idle period.

## Scripts

- **`lemonade_unload.sh`** — one-shot script: checks idle time for all loaded models and unloads if any exceeds the threshold. Run directly to test.
- **`install.sh [endpoint] [timeout_s] [interval_min]`** — installs systemd user timer (defaults: `http://localhost:13305`, 300s, 5min).
- **`uninstall.sh`** — removes the timer and service.

## Key Design Detail: Idle Time Calculation

The lemonade health endpoint (`GET /api/v1/health`) returns a `last_use` field per loaded model. This is a `CLOCK_MONOTONIC` millisecond timestamp — the same reference as `/proc/uptime`. Idle time is computed as:

```
idle_s = (uptime_ms - last_use) / 1000
```

No state file is needed; idle time is derived directly from the server response.

The unload API (`POST /api/v1/unload`) unloads **all** models at once — there is no per-model unload.

## Testing

```bash
# Run immediately against a local server (unloads any model idle ≥ 0s)
bash lemonade_unload.sh --timeout 0

# Check status after install
systemctl --user status lemonade-unload.timer
journalctl --user -u lemonade-unload.service
```

## Dependencies

`curl`, `jq`, `awk` — all standard on typical Linux systems.
