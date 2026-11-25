#!/bin/bash
set -e
: "${K3S_TOKEN:?K3S_TOKEN manquqnt (p1/.env)}"

NODE_IP="192.168.56.110"
IFACE=$(ip -o -4 addr show | awk -v ip="$NODE_IP" '$4 ~ ip {print $2}')

apt-get update -y
apt-get install -y curl

curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.36.5+k3s1" K3S_TOKEN="$K3S_TOKEN" sh -s - server \
	--node-ip "$NODE_IP" \
	--flannel-iface "$IFACE" \
	--write-kubeconfig-mode 644

