#!/bin/sh

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# k3d must run as a regular user, so the cluster lands in that user's ~/.kube/config
if [ "$(id -u)" -eq 0 ]; then
  echo "Run this script without sudo: $0" 1>&2
  exit 1;
fi

# 1. Create cluster
if ! k3d cluster get msn 1>/dev/null ; then
  echo "Creating k3d cluster..."
  k3d cluster create --config "$SCRIPT_DIR/../confs/k3d/msn-cluster.yaml"
  echo "...cluster created"
else
  echo "Cluster msn already exists, skipping"
fi

# 2. Create namespaces
for ns in argocd dev; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done

# 3. Set default namespace to "dev" (useful for development)
kubectl config set-context k3d-msn --namespace=dev
