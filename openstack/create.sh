#!/bin/bash
set -euo pipefail

echo Creating server "$EIRINI_STATION_USERNAME-eirini-station"
openstack server create "$EIRINI_STATION_USERNAME-eirini-station" \
  --flavor "g_c8_m16" \
  --image "ubuntu-22.04-amd64-vmware" \
  --boot-from-volume "100" \
  --wait \
  --network "korifi-dev_private" \
  --security-group "default" \
  --key-name "$OS_USERNAME" \
  --tag "$EIRINI_STATION_USERNAME-eirini-station" >/dev/null

openstack floating ip create "$(openstack network list --format json | jq -r ".[0].Name")" \
  --tag "$EIRINI_STATION_USERNAME-eirini-station"

FLOATING_IP_DETAILS="$(
  openstack floating ip list --tags "$EIRINI_STATION_USERNAME-eirini-station" --format json
)"
FLOATING_IP="$(jq -r '.[0] | ."Floating IP Address"' <<<"$FLOATING_IP_DETAILS")"

openstack server add floating ip "$EIRINI_STATION_USERNAME-eirini-station" "$FLOATING_IP"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"
echo "Done creating server"
echo "Name   $STATION_NAME"
echo "IP     $STATION_IP"
echo "Volume $STATION_VOLUME"
echo "Status $STATION_STATUS"
