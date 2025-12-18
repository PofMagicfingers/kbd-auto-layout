# TODO - kbd-auto-layout

## Completed

- [x] Structure du projet (config/, udev/)
- [x] Configuration YAML (`~/.config/kbd-auto-layout/keyboards.yaml`)
- [x] Script principal avec lecture YAML (yq ou fallback awk)
- [x] Script GUI interactif avec gum (`kbd-auto-layout-gui`)
- [x] Lancement GUI par défaut (style rclone)
- [x] Règles udev (claviers + modules DKMS)
- [x] Commande `reload` pour réappliquer manuellement
- [x] Script d'installation (`install.sh`)
- [x] Script de désinstallation (`uninstall.sh`)
- [x] Suppression du code dupliqué (triple setxkbmap → retry loop)
- [x] Lock avec flock au lieu de pgrep
- [x] Documentation CLAUDE.md

## À faire

- [ ] README.md avec instructions complètes
- [ ] Support Wayland (wlr-randr, etc.)
- [ ] Détection automatique des claviers pour suggérer configs
- [ ] Tests automatisés
