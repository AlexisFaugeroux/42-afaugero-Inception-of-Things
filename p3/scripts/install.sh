
#!/bin/sh

set -e

GREEN='\033[0;32m'

if ! command -v curl >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y curl
fi

# Install Docker if not install

if ! command -v docker >/dev/null 2>&1; then

    # Add Docker's official GPG key:
    sudo apt update
    sudo apt install -y ca-certificates curl

    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg \
        -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

    sudo apt-get update
    sudo apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    # Démarrer Docker
    sudo systemctl enable --now docker

fi

printf "${GREEN}Docker install\n"

# Install kube control
if ! command -v kubectl >/dev/null 2>&1; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
fi

# Install k3d if not install
if ! command -v k3d >/dev/null 2>&1; then
    curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

