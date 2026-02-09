#!/usr/bin/env bash
set -euo pipefail

#############################################
# CONFIG (override via env)
#############################################

BOARD_ID=$(awk '/Serial/ {print $3}' /proc/cpuinfo)

MQTT_HOST="${MQTT_HOST:-18.100.207.236}"
MQTT_PORT="${MQTT_PORT:-1883}"
MQTT_USER="${MQTT_USER:-storeyes}"
MQTT_PASS="${MQTT_PASS:-12345}"
MQTT_TOPIC="${MQTT_TOPIC:-storeyes/$BOARD_ID/alert-processor}"
QOS="${QOS:-1}"
RETAIN="${RETAIN:-false}"
TIMEOUT="${TIMEOUT:-5}"
RETRIES="${RETRIES:-3}"

#############################################
# CHECK ALERT PROCESSOR STATUS
#############################################

ALERT_STATUS_FILE="$HOME/alert-processor-status.txt"

if [[ ! -f "$ALERT_STATUS_FILE" ]]; then
    echo "ℹ️ Alert processor status file not found. Skipping..."
    exit 0
fi

ALERT_LINES=($(cat "$ALERT_STATUS_FILE"))
ALERT_STATUS="${ALERT_LINES[0]:--1}"
TOTAL_ALERTS="${ALERT_LINES[1]:--1}"
PROCESSED_ALERTS="${ALERT_LINES[2]:--1}"

#############################################
# BUILD JSON PAYLOAD
#############################################

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

RAW_PAYLOAD=$(cat <<EOF
{
  "board_id": "$BOARD_ID",
  "timestamp": "$TIMESTAMP",
  "alert-processor": {
    "status": "$ALERT_STATUS",
    "total": "$TOTAL_ALERTS",
    "processed": "$PROCESSED_ALERTS"
  }
}
EOF
)

if command -v jq >/dev/null 2>&1; then
    FINAL_PAYLOAD=$(echo "$RAW_PAYLOAD" | jq -c .)
else
    FINAL_PAYLOAD="$RAW_PAYLOAD"
fi

#############################################
# MQTT RETRY LOOP
#############################################

attempt=1
while [[ $attempt -le $RETRIES ]]; do
    echo "📡 Publishing alert processor status (attempt $attempt/$RETRIES)"

    if timeout "$TIMEOUT" mosquitto_pub \
        -h "$MQTT_HOST" \
        -p "$MQTT_PORT" \
        -u "$MQTT_USER" \
        -P "$MQTT_PASS" \
        -t "$MQTT_TOPIC" \
        -m "$FINAL_PAYLOAD" \
        -q "$QOS" \
        $( [[ "$RETAIN" == "true" ]] && echo "-r" ); then

        echo "✅ Alert processor status sent"
        exit 0
    fi

    echo "⚠️ Publish failed. Retrying..."
    sleep 2
    ((attempt++))
done

echo "❌ Failed after $RETRIES attempts"
exit 1

