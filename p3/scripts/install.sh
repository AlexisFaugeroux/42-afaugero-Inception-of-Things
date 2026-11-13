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

# Shared environment
export TARGET_USER="${SUDO_USER:-$USER}"

. "$SCRIPT_DIR/common.sh"

msg "Starting IoT installation..."
msg ""
msg "=== Docker installation ==="
"$SCRIPT_DIR/install-docker.sh"
msg ""
msg "=== kubectl installation ==="
"$SCRIPT_DIR/install-kubectl.sh"
msg ""
msg "=== k3d installation ==="
"$SCRIPT_DIR/install-k3d.sh"
msg ""
msg "Installation completed successfully!"

msg ""
printf "Create the k3d cluster now? [y/n] " 1>&3 2>&1
read -r answer || answer=""

case "$answer" in
  [yY]*)
    sudo -u "$TARGER_USER" -H sh "$SCRIPT_DIR/setup.sh" 1>&3 2>&1
    ;;
  *)
    msg "Skipped. Create it later with: $SCRIPT_DIR/setup.sh"
    ;;
esac
