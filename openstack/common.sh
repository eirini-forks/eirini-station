info="$(
  openstack server show "$EIRINI_STATION_USERNAME-eirini-station" --format json
)"
FLOATING_IP_DETAILS="$(
  openstack floating ip list --tags "$EIRINI_STATION_USERNAME-eirini-station" --format json
)"
export STATION_IP="$(jq -r '.[0] | ."Floating IP Address"' <<<$FLOATING_IP_DETAILS)"
export STATION_NETWORK_NAME=$(openstack network list --format json | jq -r ".[0].Name")
export STATION_STATUS="$(jq -r ".status" <<<$info)"
export STATION_NAME="$(jq -r ".name" <<<$info)"
export STATION_VOLUME="$(jq -r '.volumes[0] | .id' <<<$info)"
export STATION_HISTORY_BACKUP="$HOME/eirini-station-history-backup"
