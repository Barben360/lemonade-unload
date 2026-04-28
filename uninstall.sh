#!/usr/bin/env bash
set -euo pipefail

SERVICE_DIR="${HOME}/.config/systemd/user"

systemctl --user disable --now lemonade-unload.timer 2>/dev/null || true
systemctl --user stop lemonade-unload.service 2>/dev/null || true

rm -f "${SERVICE_DIR}/lemonade-unload.service" "${SERVICE_DIR}/lemonade-unload.timer"

systemctl --user daemon-reload

echo "Uninstalled lemonade-unload timer and service."
