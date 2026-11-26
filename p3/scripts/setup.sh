#!/bin/sh

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

K3D_CONFIG="$SCRIPT_DIR/../confs/k3d/msn-cluster.yaml"
ENV_FILE="$SCRIPT_DIR/../confs/k8s/.env"
DATA_DIR="/home/afaugero/iot/data"
ARGOCD_DIR="$SCRIPT_DIR/../confs/k8s/argocd"

CLUSTER_NAME="msn"
CONTEXT="k3d-msn"

# 1. Check execution user
# k3d must run as a regular user, so the cluster lands in that user's ~/.kube/config
if [ "$(id -u)" -eq 0 ]; then
  echo "Run this script without sudo: $0" 1>&2
  exit 1
fi

# 2. Check dependencies
for cmd in k3d kubectl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: $cmd is not installed" 1>&2
    exit 1
  fi
done

# 3. Create directory for persistent data
if [ ! -d "$DATA_DIR" ]; then
  mkdir -p "$DATA_DIR"
  echo "Directory created: $DATA_DIR"
  if [ ! -d "$DATA_DIR/postgres"];then
    mkdir "$DATA_DIR/postgres"
    echo "Directory created: $DATA_DIR/postgres"
  fi
  if [ ! -d "$DATA_DIR/media"];then
    mkdir "$DATA_DIR/media"
    echo "Directory created: $DATA_DIR/media"
  fi
else
  echo "Directory already exists: $DATA_DIR"
fi

# 4. Create cluster if needed
if ! k3d cluster get "$CLUSTER_NAME" 1>/dev/null; then
  echo "Creating k3d cluster..."
  k3d cluster create --config "$K3D_CONFIG"
  echo "...cluster created"
else
  echo "Cluster $CLUSTER_NAME already exists, skipping"
fi

# 5. Select Kubernetes context
kubectl config use-context "$CONTEXT"

# 6. Wait for nodes
kubectl wait \
  --for=condition=Ready \
  nodes --all \
  --timeout=60s

# 7. Create namespaces
for ns in argocd dev; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done

# 8. Create or update secrets
kubectl create secret generic msn-env \
  -n dev \
  --from-env-file="$ENV_FILE" \
  --dry-run=client -o yaml | kubectl apply -f -


# 9. Set default namespace to "dev" (useful for development)
kubectl config set-context "$CONTEXT" --namespace=dev

# 10. Deploy ArgoCD
kubectl apply --server-side -k "$ARGOCD_DIR" -n argocd

# 11. Deploy ArgoCD application
kubectl apply -f "$ARGOCD_DIR/application.yaml"

echo "Deployment completed successfully!"
