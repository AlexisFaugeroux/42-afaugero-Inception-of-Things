#!/bin/sh

set -e

. "$SCRIPT_DIR/common.sh"

if command -v docker >/dev/null 2>&1; then
	# Uninstall packages and configuration files
	apt-get purge -y \
		docker-ce \
		docker-ce-cli \
		docker-buildx-plugin \
		containerd.io \
		docker-compose-plugin \
		docker-ce-rootless-extras
	msg "...done"

	# Delete data (images, containers, volumes)
	msg "Deleting images, containers and volumes ..."
	rm -rf /var/lib/docker /var/lib/containerd /etc/docker
	msg "...done"

	# Remove docker repository from Apt sources and GPG key
	msg "Removing GPG key and docker repository from sources..."
	rm -f /etc/apt/sources.list.d/docker.sources /etc/apt/keyrings/docker.asc
	apt-get update
	msg "...done"

	# Delete docker group
	msg "Deleting docker group..."
	if getent group docker >/dev/null; then
		groupdel docker
	fi
	msg "...done"

	# Delete Docker CLI configuration
	msg "Deleting docker CLI configuration files..."
	rm -rf "$TARGET_HOME/.docker"
	msg "...done"

	msg "Docker uninstallation complete"
else
	msg "Nothing to uninstall"
fi
