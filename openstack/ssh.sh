#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$SCRIPT_DIR/env.sh"
if [[ -z "${STATION_IP:-}" ]]; then
  source "$SCRIPT_DIR/common.sh"
fi

station_profile_contents=$(
  cat <<-EOF
export STATION_IP=$STATION_IP
export VMUSER=$VMUSER
EOF
)

COMMON_PROFILE_PATH=".oh-my-zsh/custom/station.zsh"
LOCAL_STATION_PROFILE="$HOME/$COMMON_PROFILE_PATH"
mkdir -p "$(dirname "$LOCAL_STATION_PROFILE")"
echo "$station_profile_contents" >"$LOCAL_STATION_PROFILE"

for attempt in $(seq 10); do
  if
    ! scp \
      -A \
      -o "UserKnownHostsFile=/dev/null" \
      -o "StrictHostKeyChecking no" \
      "$LOCAL_STATION_PROFILE" "${VMUSER}@${STATION_IP}:/home/$VMUSER/$COMMON_PROFILE_PATH"
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
