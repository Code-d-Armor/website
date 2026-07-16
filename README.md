# DevFest Perros-Guirec

Site web de la conférence **DevFest Perros-Guirec**, organisée par l'association Code d'Armor. Ce site est construit avec [Jekyll](https://jekyllrb.com/), un générateur de sites statiques en Ruby.

> **Note :** Tout le contenu du site (textes, descriptions, messages) doit être rédigée en **français**.

## Démarrage rapide

```shell
# Installer les dépendances
bundle install

# Lancer le serveur de développement
bundle exec jekyll serve --trace
# Site accessible sur http://localhost:4000
```

## Scripts d'optimisation

Le projet inclut des scripts pour gérer les images (conversion JPG/PNG → WebP).

### Commandes principales

```shell
# Convertir les images (mode sûr - garde les fichiers sources)
./scripts/optimize-images.sh

# Convertir, remplacer les URLs et supprimer les fichiers sources
./scripts/optimize-images.sh --full

# Vérifier l'intégrité des références d'images
./scripts/audit-images.sh
```

Pour plus de détails, voir [scripts/README.md](./scripts/README.md).

## Prérequis

- Ruby 2.5 ou supérieur
- Bundler (gestionnaire de dépendances Ruby)

## Installation

### 1. Installer Ruby et les dépendances système

```shell
apt-get install ruby-full build-essential zlib1g-dev
```

### 2. Configurer l'environnement Ruby

```shell
echo '# Install Ruby Gems to ~/gems' >> ~/.bashrc
echo 'export GEM_HOME="$HOME/gems"' >> ~/.bashrc
echo 'export PATH="$HOME/gems/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### 3. Installer Jekyll et les dépendances du projet

```shell
gem install jekyll bundler
bundle install
```

## Démarrage rapide

Lancer le serveur de développement local :

```shell
bundle exec jekyll serve --trace
```

