#!/bin/sh

set -e

. "$SCRIPT_DIR/common.sh"

if command -v k3d >/dev/null 2>&1; then
	msg "TODO uninstall k3d"
else
	msg "Nothing to uninstall"
fi
