#!/bin/sh

set -e

. "$SCRIPT_DIR/common.sh"

if command -v k3d >/dev/null 2>&1; then
	rm $(which k3d)
	msg "k3d uninstallation complete"
else
	msg "Nothing to uninstall"
fi
