# Branche mayab : P1 et P2 (version de Maya)

Cette branche contient uniquement mon travail sur la P1 et la P2,
pour comparaison avec la version du groupe (branche principale).

- VM principale : Debian 13, lancée avec QEMU/KVM
- Provider Vagrant : libvirt
- Box : debian/trixie64
- P1 : token K3s aléatoire généré dans p1/.env (gitignoré), 1 CPU / 1 Go par VM
- P2 : 3 applis (hello-kubernetes) + Ingress Traefik, app2 en 3 replicas

La P3 et les schémas sont sur la branche principale (travail d'Alexis).
