#!/bin/sh

set -e

: "${K3S_TOKEN:?Missing K3S_TOKEN, check env file}"

curl -sfL https://get.k3s.io | K3S_TOKEN="$K3S_TOKEN" K3S_KUBECONFIG_MODE="644" \
  sh -s - server \
  --node-ip 192.168.56.110 \
  --flannel-iface eth1 \
  --disable metrics-server \
  --disable local-storage

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "Waiting for Kubernetes API..."

until kubectl get --raw=/readyz >/dev/null 2>&1; do
  sleep 2
done

echo "Waiting for Kubernetes node registration..."

# Attendre qu'au moins un noeud soit enregistré (180 secondes max)
attempt=0
until [ -n "$(kubectl get nodes -o name 2>/dev/null)" ]; do
  attempt=$((attempt + 1))

  if [ "$attempt" -ge 90 ]; then
    echo "ERROR: No Kubernetes node registered after 180 seconds"
    exit 1
  fi

  sleep 2
done

echo "Waiting for Kubernetes node Ready..."

kubectl wait --for=condition=Ready nodes --all --timeout=180s

echo "192.168.56.110 app1.com" >> /etc/hosts
echo "192.168.56.110 app2.com" >> /etc/hosts
echo "192.168.56.110 app3.com" >> /etc/hosts

kubectl apply -f /opt/iot_config/app1/config.yaml
kubectl apply -f /opt/iot_config/app1/config_html.yaml
kubectl apply -f /opt/iot_config/app1/deployment.yaml
kubectl apply -f /opt/iot_config/app1/service.yaml

kubectl apply -f /opt/iot_config/app2/config.yaml
kubectl apply -f /opt/iot_config/app2/config_html.yaml
kubectl apply -f /opt/iot_config/app2/deployment.yaml
kubectl apply -f /opt/iot_config/app2/service.yaml

kubectl apply -f /opt/iot_config/app3/config.yaml
kubectl apply -f /opt/iot_config/app3/config_html.yaml
kubectl apply -f /opt/iot_config/app3/deployment.yaml
kubectl apply -f /opt/iot_config/app3/service.yaml

kubectl apply -f /opt/iot_config/ingress.yaml
