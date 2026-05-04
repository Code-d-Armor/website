# Scripts d'optimisation

Ce dossier contient les scripts utilitaires pour le projet DevFest Perros-Guirec.

## Scripts disponibles

### `optimize-images.sh`

Convertit les images JPG/PNG au format WebP pour améliorer les performances.

**Usage :**

```bash
# Mode sûr (par défaut) - convertit les images sans supprimer les originales
./scripts/optimize-images.sh

# Mode complet - remplace les URLs et supprime les fichiers sources
./scripts/optimize-images.sh --full

# Qualité personnalisée (défaut: 85)
./scripts/optimize-images.sh --quality 90
```

**Options :**

| Option | Description |
|--------|-------------|
| `--full` | Remplace les références dans les fichiers et supprime les sources |
| `--quality N` | Définit la qualité WebP (1-100) |
| `--help` | Affiche l'aide |

**Exemple de sortie :**

```
╔════════════════════════════════════════════════════════════╗
║     Image Optimization for DevFest Perros-Guirec          ║
╚════════════════════════════════════════════════════════════╝

📁 Processing: /home/user/workspace/conference/assets
  Converting: devfest_2026.jpg → devfest_2026.webp
    ✓ Saved 245KB (73%)

Summary
-------
Files converted: 42
Original size:   15.3MB
Optimized size:  4.2MB
Saved:           11.1MB (72%)
```

### `audit-images.sh`

Audite les références d'images et identifie les opportunités d'optimisation.

**Usage :**

```bash
./scripts/audit-images.sh
```

**Vérifications effectuées :**

- Références d'images cassées (fichiers référencés mais manquants)
- Images sans version WebP
- Images trop volumineuses (>500KB)
- Statistiques globales (nombre d'images, ratio WebP, taille totale)

**Exemple de sortie :**

```
╔════════════════════════════════════════════════════════════╗
║            Image Reference Audit Report                    ║
╚════════════════════════════════════════════════════════════╝

🔍 Checking for broken image references...
  ✓ No broken references found

🔄 Checking for WebP optimization opportunities...
  ⚠ No WebP: image.jpg (1.2MB)

📊 Image Statistics
  Total images: 747
  WebP images:  286
  WebP ratio:   38.2%
  Total size:   53MB
```

## Dépendances

Les scripts nécessitent les outils suivants :

```bash
# Installation sur Debian/Ubuntu
sudo apt-get install webp imagemagick bc
```

| Package | Utilisation |
|---------|-------------|
| `webp` | Conversion en format WebP (cwebp) |
| `imagemagick` | Manipulation d'images |
| `bc` | Calculs mathématiques |

## Intégration CI/CD

Pour intégrer l'audit dans une CI :

```yaml
# .github/workflows/audit.yml
name: Image Audit
on: [pull_request]

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install dependencies
        run: sudo apt-get install webp imagemagick bc
      - name: Run image audit
        run: ./scripts/audit-images.sh
```
