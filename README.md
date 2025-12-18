# USB Keyboard Layout Manager

Configure automatiquement la disposition de vos claviers USB sous Linux.

## Le problème

Vous avez un clavier USB (8BitDo, Keychron, etc.) et vous voulez qu'il utilise une disposition spécifique (US International, AZERTY, etc.) automatiquement quand vous le branchez. Normalement, il faut le reconfigurer à chaque fois.

## La solution

Ce script configure automatiquement vos claviers dès qu'ils sont branchés, et réapplique la config même après une mise à jour du système.

## Installation rapide

1. Ouvrez un terminal
2. Allez dans le dossier du projet :
   ```
   cd kbd-auto-layout
   ```
3. Installez avec :
   ```
   sudo ./install.sh
   ```

C'est tout ! Vos claviers seront maintenant configurés automatiquement.

## Configurer vos claviers

### Option 1 : Interface graphique (recommandé)

Tapez simplement :
```
kbd-auto-layout
```

Suivez les instructions à l'écran pour choisir votre clavier et sa disposition.

*Note : nécessite `gum` (`sudo pacman -S gum` sur Arch)*

### Option 2 : Modifier le fichier de config

Éditez le fichier `~/.config/kbd-auto-layout/keyboards.yaml` :

```yaml
keyboards:
  - name: "8BitDo"      # Nom de votre clavier (tel qu'il apparaît dans le système)
    layout: us          # Disposition (us, fr, de, es, etc.)
    variant: intl       # Variante (intl, azerty, etc.)
    model: pc105

  - name: "Keychron"
    layout: us
    variant: intl
    model: pc105
```

Pour trouver le nom exact de votre clavier :
```
kbd-auto-layout list
```

## Commandes utiles

| Commande | Description |
|----------|-------------|
| `kbd-auto-layout` | Lancer le configurateur |
| `kbd-auto-layout list` | Voir les claviers détectés |
| `kbd-auto-layout reload` | Réappliquer les configs maintenant |

## Si ça ne marche pas

1. **Vérifiez que le clavier est détecté** :
   ```
   kbd-auto-layout list
   ```
   Votre clavier doit apparaître dans la liste.

2. **Réappliquez manuellement** :
   ```
   kbd-auto-layout reload
   ```

3. **Consultez les logs** :
   ```
   cat /var/log/kbd-auto-layout.log
   ```

## Désinstallation

```
sudo ./uninstall.sh
```

Vos configurations personnelles dans `~/.config/kbd-auto-layout/` ne sont pas supprimées.

## Prérequis

- Linux avec X11 (pas encore compatible Wayland)
- Outils X11 : `setxkbmap`, `xinput` (généralement déjà installés)

Optionnel :
- `gum` : pour l'interface graphique
- `yq` : pour un meilleur parsing YAML
