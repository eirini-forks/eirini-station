#!/bin/bash
set -euo pipefail

openstack server start "${EIRINI_STATION_USERNAME}-eirini-station" 

