#!/bin/bash
set -euo pipefail

# gcloud compute resource-policies create instance-schedule "$EIRINI_STATION_USERNAME-shutdown-schedule" \
#   --description="shut down the machine every day at 19:00 UTC" \
#   --project="cf-on-k8s-wg" \
#   --region="europe-west2" \
#   --vm-stop-schedule="0 19 * * *"
# gcloud compute instances create "$EIRINI_STATION_USERNAME-eirini-station" \
#   --project="cf-on-k8s-wg" \
#   --metadata=ssh-keys="$EIRINI_STATION_USERNAME:$(ssh-add -L)" \
#   --image-project="ubuntu-os-cloud" \
#   --image-family="ubuntu-2204-lts" \
#   --machine-type="e2-custom-8-16384" \
#   --boot-disk-size="100GB" \
#   --boot-disk-type="pd-ssd" \
#   --zone="europe-west2-a" \
#   --resource-policies="$EIRINI_STATION_USERNAME-shutdown-schedule"
echo Creating server "$EIRINI_STATION_USERNAME-eirini-station"
openstack server create "$EIRINI_STATION_USERNAME-eirini-station" \
  --flavor "g_c8_m16" \
  --image "SAP-compliant-ubuntu-22-04" \
  --boot-from-volume "100" \
  --wait >/dev/null
# --security-group ?
# --key-name ?

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"
echo "Done creating server"
echo "Name   $STATION_NAME"
echo "IP     $STATION_IP"
echo "Status $STATION_STATUS"
