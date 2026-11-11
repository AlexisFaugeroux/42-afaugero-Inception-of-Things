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

# Install docker if not already installed
if ! command -v docker >/dev/null 2>&1; then
	msg "Installing docker..."
	# Install requirements
	MISSING=""
	for pkg in ca-certificates curl; do
		if ! dpkg-query --show --showformat='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
			MISSING="$MISSING $pkg"
		fi
	done
	if [ -n "$MISSING" ]; then
		msg "	Installing missing packages $MISSING..."
		apt-get update
		apt-get install -y $MISSING
		msg "	...installation done"
	fi

	# Add Docker's official GPG key - it verifies docker's packages signatures
	msg "	adding GPG key..."
	install -m 0755 -d /etc/apt/keyrings
	curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
	chmod a+r /etc/apt/keyrings/docker.asc
	msg "	...done"

	# Add docker repository to Apt sources
	msg "	adding docker repository to Apt sources..."
	tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

	apt-get update
	msg "	...done"

	# Install docker packages
	msg "	installing docker packages..."
	apt-get install -y \
		docker-ce \
		docker-ce-cli \
		containerd.io \
		docker-buildx-plugin \
		docker-compose-plugin

	# Check install
	if ! systemctl is-active --quiet docker; then
		systemctl enable --now docker
	fi

	i=0
	until docker info >/dev/null 2>&1; do
		i=$((i + 1))
		if [ "$i" -ge 30]; then
			msg "Docker is not responding after 30s:" >&2
			docker info >&2 || true
			exit 1
		fi
		sleep 1
	done
	msg "	...done"
	
	# Add user to docker group
	if ! id -nG "$TARGET_USER"| grep -qw docker; then
		usermod -aG docker "$TARGET_USER"
		msg "	user $TARGET_USER added to docker group: log out and login back to use docker without sudo"
	fi

	msg "...installation done"
else
	msg "Docker already installed, skipping installation"
fi

if ! command -v k3d >/dev/null 2>&1; then
	msg "TODO k3d"
else
	msg "k3d already installed, skipping installation"
fi
