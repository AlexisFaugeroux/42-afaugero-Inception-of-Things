#!/bin/sh

set -e

. "$SCRIPT_DIR/common.sh"

if command -v kubectl 2>/dev/null; then
	apt-get purge -y kubectl
	apt-get autoremove -y
	msg "kubectl uninstallation complete"
else
	msg "Nothing to uninstall"
fi
