#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"
echo "Deleting server"

if [[ -f "$STATION_HISTORY_BACKUP" ]]; then
  echo "Backing up history file into: '$STATION_HISTORY_BACKUP'"
  scp -r "$VMUSER@$STATION_IP:~/.zsh_history" "$STATION_HISTORY_BACKUP" || true
fi

openstack floating ip delete "$STATION_IP"
openstack server delete "$EIRINI_STATION_USERNAME-eirini-station" --wait
openstack volume delete "$STATION_VOLUME"

rm -f "$LOCAL_STATION_PROFILE"
