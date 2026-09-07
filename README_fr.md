<h1>
  <img src="https://avatars.githubusercontent.com/u/3909721?s=200&v=4" width="32px" alt="Logo de Alby Hub">
  Alby Hub, empaqueté pour YunoHost
</h1>

Portefeuille Lightning auto-hébergé (noeud LDK intégré + Nostr Wallet Connect)

[![🌐 Site officiel](https://img.shields.io/badge/Site_officiel-darkgreen?style=for-the-badge)](https://albyhub.com/)
[![Version : 1.24.0~ynh1](https://img.shields.io/badge/Version-1.24.0~ynh1-rgb(18,138,11)?style=for-the-badge)](https://github.com/getAlby/hub/releases/tag/v1.24.0)

> ⚠️ **Alby Hub gère des fonds Bitcoin et Lightning.** Lors de la première
> configuration, une **phrase de récupération** vous sera montrée — conservez-la
> hors ligne, en dehors de ce serveur. Une sauvegarde YunoHost ne remplace pas
> la phrase de récupération. Lisez la clause de non-responsabilité dans
> `doc/DISCLAIMER.md` et le guide de sauvegarde/récupération dans
> `doc/BACKUP.md` avant d'y déposer des fonds.

## Présentation

Alby Hub est un portefeuille Lightning auto-hébergé : il exécute un noeud LDK
intégré ainsi qu'un serveur Nostr Wallet Connect (NWC) sur votre propre
domaine. Vous détenez vos propres clés et pouvez y connecter des applications,
portefeuilles et automations compatibles NWC.

Ce paquet installe le binaire serveur amont en mode HTTP derrière le nginx de
YunoHost, sur un domaine dédié.

- Noeud Lightning `LDK` intégré (ni Bitcoin Core, ni LND ni CLN requis)
- Authentification native Alby Hub (pas de SSO YunoHost devant)
- État du portefeuille persistant dans un répertoire de données dédié
- Schéma de sauvegarde arrêt → instantané → archive → redémarrage
- Mises à niveau prudentes qui ne touchent jamais l'état du portefeuille en cas d'échec

Prise en charge de `amd64` et `arm64`.

## Distribution via le catalogue Nostr

Ce paquet est distribué via le catalogue d'applications YunoHost basé sur
Nostr (déclaration signée publiée sur relais) plutôt que par le catalogue
officiel GitHub `YunoHost/apps`. Contactez un administrateur pour publier une
nouvelle version ; voir les instructions d'installation ci-dessous.

## Installation

```
# installation (branche `main` de test) :
sudo yunohost app install https://github.com/<org>/alby-hub_ynh
```

Ouvrez ensuite l'URL de l'application et terminez la création du portefeuille
dans l'interface d'Alby Hub.

## Documentation

- `doc/DISCLAIMER.md` — sécurité financière
- `doc/BACKUP.md` — sauvegarde/restauration, check-list post-restauration
- `doc/ADMIN.md` — service, journaux, mise à niveau et suppression

## Infos développeur

🛠️ Dépôt amont : <https://github.com/getAlby/hub>

Les pull requests sont bienvenues et doivent cibler la branche `main`.
