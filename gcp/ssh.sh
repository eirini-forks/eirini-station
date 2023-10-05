#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if [[ "$STATION_STATUS" != "RUNNING" ]]; then
  echo "Station is not running. Run 'station start' to start it"
  exit 1
fi

ZSH_CUSTOM_DIR="/home/$EIRINI_STATION_USERNAME/.oh-my-zsh/custom"
for attempt in $(seq 10); do
  if ! ssh \
    -A "$EIRINI_STATION_USERNAME@$STATION_IP" \
    "mkdir -p $ZSH_CUSTOM_DIR; echo export STATION_IP=$STATION_IP > $ZSH_CUSTOM_DIR/station_ip.zsh"; then
    sleep 1
    continue
  fi

  ssh \
    -A \
    -o "UserKnownHostsFile=/dev/null" \
    "$@" \
    "${EIRINI_STATION_USERNAME}@${STATION_IP}"
  exit 0
done

echo "Unable to ssh to the station after $attempt attempts"
exit 1
