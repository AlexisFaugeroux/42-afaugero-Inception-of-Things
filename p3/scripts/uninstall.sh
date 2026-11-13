#!/bin/sh 
GREEN='\033[0;32m'

k3d=$(which k3d)
docker=$(command -v docker)
if [ ${k3d} ]; then
	echo "${GREEN}[INFO] Uninstalling k3d..."
	sudo rm ${k3d}
fi
if [ ${docker} ]; then
	echo "${GREEN}[INFO] Stopping docker services..."
	sudo systemctl stop docker
	sudo systemctl stop docker.socket
	echo "${GREEN}[INFO] Uninstalling docker engine..."
	sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	sudo apt-get purge -y docker docker-engine docker.io containerd runc
	sudo rm -rf /var/lib/docker
	sudo rm -rf /var/lib/containerd
	sudo rm -rf ~/.docker
	sudo apt-get autoremove -y
fi
if [ $(command -v kubectl) ]; then
	echo "${GREEN}[INFO] Uninstalling kubectl/k3s..."
	sudo rm /usr/local/bin/kubectl
fi
