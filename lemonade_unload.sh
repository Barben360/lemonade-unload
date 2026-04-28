#!/usr/bin/env bash
set -euo pipefail

ENDPOINT="http://localhost:13305"
TIMEOUT=300

while [[ $# -gt 0 ]]; do
    case "$1" in
        --endpoint) ENDPOINT="$2"; shift 2 ;;
        --timeout)  TIMEOUT="$2";  shift 2 ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

uptime_ms=$(awk '{printf "%d", $1 * 1000}' /proc/uptime)

health=$(curl -sf "${ENDPOINT}/api/v1/health") || {
    echo "Could not reach lemonade server at ${ENDPOINT}, skipping."
    exit 0
}

model_count=$(echo "$health" | jq '.all_models_loaded | length')
if [[ "$model_count" -eq 0 ]]; then
    echo "No models loaded, nothing to do."
    exit 0
fi

should_unload=0
while IFS= read -r model_json; do
    model_name=$(echo "$model_json" | jq -r '.model_name')
    last_use=$(echo "$model_json" | jq -r '.last_use')
    idle_s=$(awk -v now="$uptime_ms" -v lu="$last_use" 'BEGIN { printf "%d", (now - lu) / 1000 }')

    if [[ "$idle_s" -ge "$TIMEOUT" ]]; then
        echo "Model '${model_name}' has been idle for ${idle_s}s (threshold: ${TIMEOUT}s) — will unload."
        should_unload=1
    else
        echo "Model '${model_name}' is still active (idle: ${idle_s}s, threshold: ${TIMEOUT}s)."
    fi
done < <(echo "$health" | jq -c '.all_models_loaded[]')

if [[ "$should_unload" -eq 1 ]]; then
    curl -sf -X POST "${ENDPOINT}/api/v1/unload" > /dev/null
    echo "All models unloaded successfully."
fi
