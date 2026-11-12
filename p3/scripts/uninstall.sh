#!/bin/sh

set -e

# Script must run as root
if [ "$(id -u)" -ne 0 ]; then
	echo "Run this script with sudo: sudo $0" >&2
	exit 1
fi

# Resolve script directory
export SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0)")" && pwd)"

LOG=/var/log/iot-install.log
: > "$LOG" # empty the log at each run
exec 3>&1 1>>"$LOG" 2>&1 # fd 3 = terminal, stdout and stderr = logfile

# On failure, tell where to look
trap 'status=$?; [ "$status" -ne 0 ] && msg "Installation failed, see $LOG"' EXIT

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)

. "$SCRIPT_DIR/common.sh"

msg "Start uninstalling"
msg ""
msg "=== kubectl uninstallation ==="
"$SCRIPT_DIR/uninstall-kubectl.sh"
# Uninstall k3d before docker as it requires docker to run
msg ""
msg "=== k3d uninstallation ==="
"$SCRIPT_DIR/uninstall-k3d.sh"
msg ""
msg "=== Docker uninstallation ==="
"$SCRIPT_DIR/uninstall-docker.sh"
msg ""
msg "Uninstallation complete"
