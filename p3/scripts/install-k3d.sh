#!/bin/sh

set -e

. "$SCRIPT_DIR/common.sh"

if ! command -v k3d >/dev/null 2>&1; then
	msg "TODO k3d"
else
	msg "k3d already installed, skipping installation"
fi
