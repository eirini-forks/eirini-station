#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"
echo "Deleting server"

openstack server delete "$EIRINI_STATION_USERNAME-eirini-station" --wait

openstack floating ip delete "$STATION_IP"

openstack volume delete "$STATION_VOLUME"
