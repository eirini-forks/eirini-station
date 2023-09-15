#!/bin/bash
set -euo pipefail

# SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# source "$SCRIPT_DIR/common.sh"

# echo "Backing up history file into: '$STATION_HISTORY_BACKUP'"
# scp -r "$EIRINI_STATION_USERNAME@$STATION_IP:~/.zsh_history" "$STATION_HISTORY_BACKUP" || true

# gcloud compute instances delete "$EIRINI_STATION_USERNAME-eirini-station" \
#   --project="cf-on-k8s-wg" \
#   --zone="europe-west2-a"
# gcloud compute resource-policies delete "$EIRINI_STATION_USERNAME-shutdown-schedule" \
#   --project="cf-on-k8s-wg" \
#   --region="europe-west2"

openstack server delete "$EIRINI_STATION_USERNAME-eirini-station" --wait

openstack floating ip delete "$STATION_IP"

openstack delete volume "$STATION_VOLUME"
