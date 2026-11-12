#!/bin/sh

set -e

. "$SCRIPT_DIR/common.sh"

# Install docker if not already installed
if ! command -v docker >/dev/null 2>&1; then
	# Install requirements
	MISSING=""
	for pkg in ca-certificates curl; do
		if ! dpkg-query --show --showformat='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
			MISSING="$MISSING $pkg"
		fi
	done
	if [ -n "$MISSING" ]; then
		msg "Installing missing packages $MISSING..."
		apt-get update
		apt-get install -y $MISSING
		msg "...installation done"
	fi

	# Add Docker's official GPG key - it verifies docker's packages signatures
	msg "Adding GPG key..."
	install -m 0755 -d /etc/apt/keyrings
	curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
	chmod a+r /etc/apt/keyrings/docker.asc
	msg "...done"

	# Add docker repository to Apt sources
	msg "Adding docker repository to Apt sources..."
	tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

	apt-get update
	msg "...done"

	# Install docker packages
	msg "Installing docker packages..."
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
		if [ "$i" -ge 30 ]; then
			msg "Docker is not responding after 30s:" >&2
			docker info >&2 || true
			exit 1
		fi
		sleep 1
	done
	msg "...done"
	
	# Add user to docker group
	if ! id -nG "$TARGET_USER"| grep -qw docker; then
		usermod -aG docker "$TARGET_USER"
		msg "user $TARGET_USER added to docker group: log out and login back to use docker without sudo"
	fi

	msg "...docker installation completed"
else
	msg "Docker already installed, skipping installation"
fi
