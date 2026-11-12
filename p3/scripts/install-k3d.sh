#!/bin/sh

set -e

. "$SCRIPT_DIR/common.sh"

if ! command -v k3d >/dev/null 2>&1; then
	curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

	msg "k3d installation complete"
else
	msg "k3d already installed, skipping installation"
fi
