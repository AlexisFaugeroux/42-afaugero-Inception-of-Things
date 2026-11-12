#!/bin/sh

set -e

. "$SCRIPT_DIR/common.sh"

if ! command -v kubectl 2>/dev/null; then
	# Install requirements
	MISSING=""
	for pkg in ca-certificates curl gnupg; do
		if ! dpkg-query --show --showformat='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
			MISSING="$MISSING $pkg"
		fi
	done
	if [ -n "$MISSING" ];then
		msg "Installing missing dependencies..."
		apt-get update
		apt-get install -y $MISSING
		msg "..done"
	fi

	# Add Kubernetes official GPG key - it verifies kubernetes's packages signatures
	msg "Adding GPG key..."
	curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.37/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
	sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg # allow unprivileged APT programs to read this keyring
	msg "...done"

	# Add Kubernetes repository to Apt sources
	msg "Adding kubernetes repository to Apt sources..."
	# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
	echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.37/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
	chmod 644 /etc/apt/sources.list.d/kubernetes.list   # helps tools such as command-not-found to work correctly
	apt-get update
	msg "...done"

	msg "Installing package..."
	apt-get install -y kubectl

	# Check install
	if ! command -v kubectl 2>&1; then
		msg "Verication check failed: kubectl is not installed"
		exit 1
	fi

	msg "kubectl installation complete"
else
	msg "kubectl already installed, skipping installation"
fi

