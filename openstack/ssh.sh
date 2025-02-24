#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ -z "${STATION_IP:-}" ]]; then
  source "$SCRIPT_DIR/common.sh"
fi

common_profile_path=".oh-my-zsh/custom/station.zsh"
local_station_profile="$HOME/$common_profile_path"
station_profile_contents=$(
  cat <<-EOF
export STATION_IP=$STATION_IP
export VMUSER=$VMUSER
EOF
)

mkdir -p "$(dirname "$local_station_profile")"
echo "$station_profile_contents" >"$local_station_profile"

for attempt in $(seq 10); do
  if
    ! scp \
      -A \
      -o "UserKnownHostsFile=/dev/null" \
      -o "StrictHostKeyChecking no" \
      "$local_station_profile" "${VMUSER}@${STATION_IP}:/home/$VMUSER/$common_profile_path"
  then
    sleep 1
    continue
  fi

  ssh \
    -A \
    -o "UserKnownHostsFile=/dev/null" \
    -o "StrictHostKeyChecking no" \
    "$@" \
    "${VMUSER}@${STATION_IP}"
  exit 0
done

echo "Unable to ssh to the station after $attempt attempts"
exit 1
