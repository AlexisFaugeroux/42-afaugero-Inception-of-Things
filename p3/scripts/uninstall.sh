#!/bin/sh

set -e

# Script must run as root
if [ "$(id -u)" -ne 0 ]; then
	echo "Run this script with sudo: sudo $0" >&2
	exit 1
fi

LOG=/var/log/iot-install.log
: > "$LOG" # empty the log at each run
exec 3>&1 1>>"$LOG" 2>&1 # fd 3 = terminal, stdout and stderr = logfile

# Function to print message to terminal
msg() {
	echo "$@" >&3
}

# On failure, tell where to look
trap 'status=$?; [ "$status" -ne 0 ] && msg "Installation failed, see $LOG"' EXIT

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)

# Uninstall k3d first as it requires docker to run
if command -v k3d >/dev/null 2>&1; then
	msg "TODO uninstall k3d"
else
	msg "k3d: nothing to uninstall"
fi

# Unsintall docker
if command -v docker >/dev/null 2>&1; then
	msg "Uninstalling docker..."

	# Uninstall packages and configuration files
	msg "	unsinstalling packages..."
	apt-get purge -y \
		docker-ce \
		docker-ce-cli \
		docker-buildx-plugin \
		containerd.io \
		docker-compose-plugin \
		docker-ce-rootless-extras
	msg "	...done"

	# Delete data (images, containers, volumes)
	msg "	deleting images, containers and volumes ..."
	rm -rf /var/lib/docker /var/lib/containerd /etc/docker
	msg "	...done"

	# Remove docker repository from Apt sources and GPG key
	msg "	removing GPG key and docker repository from sources..."
	rm -f /etc/apt/sources.list.d/docker.sources /etc/apt/keyrings/docker.asc
	apt-get update
	msg "	...done"

	# Delete docker group
	msg "	deleting docker group..."
	if getent group docker >/dev/null; then
		groupdel docker
	fi
	msg "	...done"

	# Delete Docker CLI configuration
	msg "	deleting docker CLI configuration files..."
	rm -rf "$TARGET_HOME/.docker"
	msg "	...done"

	msg "...uninstallation complete"
else
	msg "Docker: nothing to uninstall"
fi
