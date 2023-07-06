#!/bin/bash
#
# This script runs on the hypervisor, from the iso-build step.

set -xeuo pipefail

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPTDIR}/common.sh"

# Log output automatically
LOGDIR="${ROOTDIR}/_output/ci-logs"
LOGFILE="${LOGDIR}/$(basename "$0" .sh).log"
if [ ! -d "${LOGDIR}" ]; then
    mkdir -p "${LOGDIR}"
fi
echo "Logging to ${LOGFILE}"
# Set fd 1 and 2 to write to the log file
exec &> >(tee >(awk '{ print strftime("%Y-%m-%d %H:%M:%S"), $0; fflush() }' >"${LOGFILE}"))

API_EXTERNAL_BASE_PORT="${1}"
SSH_EXTERNAL_BASE_PORT="${2}"
LB_EXTERNAL_BASE_PORT="${3}"

cd ~/microshift/test

# Start the web server to host the kickstart files and ostree commit
# repository.
bash -x ./bin/start_webserver.sh

# Build all of the needed VMs
for scenario in scenarios/*.sh; do
    time bash -x ./bin/scenario.sh create "${scenario}"
done

# Set up port forwarding
bash -x ./bin/manage_vm_connections.sh remote -a "${API_EXTERNAL_BASE_PORT}" -s "${SSH_EXTERNAL_BASE_PORT}" -l "${LB_EXTERNAL_BASE_PORT}"

# Kill the web server
pkill caddy || true

echo "Boot phase complete"