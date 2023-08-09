info="$(
  openstack server show "$EIRINI_STATION_USERNAME-eirini-station" --format json
)"

export STATION_NETWORK_NAME=$(openstack network list --format json | jq -r ".[0].Name")
export STATION_STATUS="$(jq -r ".status" <<<$info)"
export STATION_IP="$(jq -r ".addresses.\"$STATION_NETWORK_NAME\"[0]" <<<$info)"
export STATION_NAME="$(jq -r ".name" <<<$info)"
# export STATION_HISTORY_BACKUP="$HOME/eirini-station-history-backup"
