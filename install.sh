#!/usr/bin/env bash
set -euo pipefail

ENDPOINT="${1:-http://localhost:13305}"
TIMEOUT="${2:-300}"
INTERVAL="${3:-5}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNLOAD_SCRIPT="${SCRIPT_DIR}/lemonade_unload.sh"

if [[ ! -f "$UNLOAD_SCRIPT" ]]; then
    echo "Error: lemonade_unload.sh not found at ${UNLOAD_SCRIPT}" >&2
    exit 1
fi

SERVICE_DIR="${HOME}/.config/systemd/user"
mkdir -p "$SERVICE_DIR"

cat > "${SERVICE_DIR}/lemonade-unload.service" <<EOF
[Unit]
Description=Unload idle lemonade LLM models
After=network.target

[Service]
Type=oneshot
ExecStart=bash ${UNLOAD_SCRIPT} --endpoint ${ENDPOINT} --timeout ${TIMEOUT}
EOF

cat > "${SERVICE_DIR}/lemonade-unload.timer" <<EOF
[Unit]
Description=Unload idle lemonade models every ${INTERVAL} minutes

[Timer]
OnBootSec=${INTERVAL}m
OnUnitActiveSec=${INTERVAL}m

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now lemonade-unload.timer

echo "Installed successfully."
echo "  Endpoint : ${ENDPOINT}"
echo "  Timeout  : ${TIMEOUT}s"
echo "  Interval : every ${INTERVAL} minutes"
echo ""
echo "Check status : systemctl --user status lemonade-unload.timer"
echo "View logs    : journalctl --user -u lemonade-unload.service"
