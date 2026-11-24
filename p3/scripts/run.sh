#!/bin/sh

sudo k3d cluster create --config k3d_config.yaml
sudo kubectl create namespace argocd
sudo kubectl create namespace dev
sudo kubectl apply --server-side -k . -n argocd
sudo kubectl apply -f src/ingress.yaml
sudo kubectl apply -f src/argocd.app.yaml

