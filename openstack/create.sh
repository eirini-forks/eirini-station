#!/bin/bash
set -euo pipefail


echo Creating server "$EIRINI_STATION_USERNAME-eirini-station"
openstack server create "$EIRINI_STATION_USERNAME-eirini-station" \
  --flavor "g_c8_m16" \
  --image "SAP-compliant-ubuntu-20-04" \
  --boot-from-volume "100" \
  --wait >/dev/null \
  --network "korifi-dev_private" \
  --security-group "default" \
  --key-name "my_mac" \
  --tag "$EIRINI_STATION_USERNAME-eirini-station"

openstack floating ip create "$EIRINI_STATION_FLOATING_NETWORK" \
  --tag "$EIRINI_STATION_USERNAME-eirini-station" 

FLOATING_IP_DETAILS="$(
  openstack floating ip list --tags "$EIRINI_STATION_USERNAME-eirini-station" --format json
  )"
FLOATING_IP="$(jq -r '.[0] | ."Floating IP Address"' <<<$FLOATING_IP_DETAILS)"

openstack server add floating ip "$EIRINI_STATION_USERNAME-eirini-station" $FLOATING_IP 

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"
echo "Done creating server"
echo "Name   $STATION_NAME"
echo "IP     $STATION_IP"
echo "Status $STATION_STATUS"