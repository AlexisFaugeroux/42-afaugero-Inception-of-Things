#!/bin/sh

# Function to print message to terminal
msg() {
	echo "$@" >&3 # redirects to 3 as 3 means terminal in install scripts
}
