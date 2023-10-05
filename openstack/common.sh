info="$(
  openstack server show "$EIRINI_STATION_USERNAME-eirini-station" --format json
)"
FLOATING_IP_DETAILS="$(
  openstack floating ip list --tags "$EIRINI_STATION_USERNAME-eirini-station" --format json
)"

STATION_IP="$(jq -r '.[0] | ."Floating IP Address"' <<<"$FLOATING_IP_DETAILS")"
STATION_NETWORK_NAME=$(openstack network list --format json | jq -r ".[0].Name")
STATION_STATUS="$(jq -r ".status" <<<"$info")"
STATION_NAME="$(jq -r ".name" <<<"$info")"
STATION_VOLUME="$(jq -r '.volumes[0] | .id' <<<"$info")"
STATION_HISTORY_BACKUP="$HOME/eirini-station-history-backup"
VMUSER=ccloud

export STATION_IP
export STATION_NETWORK_NAME
export STATION_STATUS
export STATION_NAME
export STATION_VOLUME
export STATION_HISTORY_BACKUP
export VMUSER
