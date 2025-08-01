#!/bin/bash
set -euo pipefail

export OS_COMPUTE_API_VERSION="2.52"

echo Creating server "$EIRINI_STATION_USERNAME-eirini-station"
openstack server create "$EIRINI_STATION_USERNAME-eirini-station" \
  --flavor "g_c8_m16" \
  --image "SAP-compliant-ubuntu-24-04" \
  --boot-from-volume "200" \
  --wait \
  --network "korifi-dev_private" \
  --security-group "default" \
  --key-name "$USER" \
  --tag "$EIRINI_STATION_USERNAME-eirini-station" >/dev/null

openstack floating ip create "$(openstack network list --format json | jq -r ".[0].Name")" \
  --description "$EIRINI_STATION_USERNAME-eirini-station" \
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
