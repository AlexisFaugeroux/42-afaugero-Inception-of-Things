#!/bin/sh

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

K3D_CONFIG="$SCRIPT_DIR/../confs/k3d/msn-cluster.yaml"
SECRET_FILE="$SCRIPT_DIR/../confs/k8s/secret.env"
CONFIG_FILE="$SCRIPT_DIR/../confs/k8s/config.env"
DATA_DIR="/home/afaugero/iot/data"
KUSTOMIZE_DIR="$SCRIPT_DIR/../confs/k8s"
ARGOCD_DIR="$SCRIPT_DIR/../confs/k8s/argocd"

CLUSTER_NAME="msn"
CONTEXT="k3d-msn"

# 1. Check execution user
# k3d must run as a regular user, so the cluster lands in that user's ~/.kube/config
if [ "$(id -u)" -eq 0 ]; then
  echo "Run this script without sudo: $0" 1>&2
  exit 1
fi

# 2. Check dependencies and env files
for cmd in k3d kubectl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: $cmd is not installed" 1>&2
    exit 1
  fi
done

# Env files are ignored by Git: they must be created from their .example template
for f in "$SECRET_FILE" "$CONFIG_FILE"; do
  if [ ! -f "$f" ]; then
    echo "Error: $f not found. Copy $f.example and fill in the values." 1>&2
    exit 1
  fi
done

# 3. Create directories for persistent data
mkdir -p "$DATA_DIR/postgres" "$DATA_DIR/media"

# 4. Create cluster if needed
if ! k3d cluster get "$CLUSTER_NAME" 1>/dev/null 2>&1; then
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

# 8. Create or update secrets and configMaps
kubectl create secret generic msn-env-secret \
  -n dev \
  --from-env-file="$SECRET_FILE" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create configmap msn-env-config \
  -n dev \
  --from-env-file="$CONFIG_FILE" \
  --dry-run=client -o yaml | kubectl apply -f -

# 9. Set default namespace to "dev" (useful for development)
kubectl config set-context "$CONTEXT" --namespace=dev

# 10. Validate Kustomize manifests
echo "Validating Kustomize manifests..."

kubectl kustomize "$KUSTOMIZE_DIR" \
  --load-restrictor LoadRestrictionsNone >/dev/null

echo "Kustomize manifests are valid"

# 11. Deploy ArgoCD
kubectl apply --server-side -k "$ARGOCD_DIR" -n argocd
# Configure ArgoCD Kustomize build options
kubectl patch configmap argocd-cm \
  -n argocd \
  --type merge \
  -p '{"data":{"kustomize.buildOptions":"--load-restrictor LoadRestrictionsNone"}}'

# Restart repo-server to apply configuration
kubectl rollout restart deployment argocd-repo-server -n argocd

kubectl rollout status deployment argocd-repo-server \
  -n argocd \
  --timeout=120s

# 12. Deploy ArgoCD application
kubectl apply -f "$ARGOCD_DIR/application.yaml"

echo "Deployment completed successfully!"
