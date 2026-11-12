
sudo apt update && sudo apt upgrade -y

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt install -y   qemu-system-x86   libvirt-daemon-system   libvirt-clients
sudo apt install vim
sudo usermod -aG libvirt "$USER"
sudo apt install vagrant
vagrant plugin install vagrant-libvirt
sudo apt install virtiofsd
