# Compte-Rendu TP7 — Gestion Multi-Utilisateur (Multi-User)

**Étudiante :** Hajer  
**Dépôt :** waiting_room_app (Branche `tp7`)  
**Application :** Single-Room Waiting Queue avec Flutter et Supabase  

---

## 1. Objectifs du TP7

L'objectif de ce TP est de transformer l'application de file d'attente (initialement anonyme et à accès universel) en une **application sécurisée multi-utilisateur** gérant l'authentification et le contrôle d'accès basé sur les rôles (**RBAC** - Role-Based Access Control) :
1. **Authentification des utilisateurs** : Inscription et connexion via Supabase Auth (Email + Mot de passe).
2. **Gestion des rôles** :
   - 👨‍⚕️ **Agent / Staff** : Gestionnaire de la file d'attente (médecin, secrétaire, guichetier).
   - 👤 **Client / Patient** : Usager attendant son tour dans la file d'attente.
3. **Contrôle d'accès et séparation des privilèges** :
   - L'**Agent** a les pleins pouvoirs : il visualise toute la file, peut ajouter n'importe quel client, appeler le client suivant (*Next Client*), et supprimer un client.
   - Le **Client** a une vue adaptée : il voit sa position personnalisée dans la file (*"Vous êtes #3 sur 7"*), peut rejoindre la file d'attente en un clic, mais le bouton *Next Client* et la suppression d'autres personnes lui sont **strictement interdits et désactivés**.
4. **Mode Démo & Hors-Ligne** : Des accès rapides démo permettent de tester et présenter instantanément les deux rôles sans dépendre d'une validation d'email externe.

---

## 2. Architecture Implémentée

```text
lib/
├── models/
│   ├── app_user.dart            # Modèle AppUser et enum UserRole (staff, client)
│   ├── client.dart
│   ├── sync_status.dart
│   └── app_connectivity.dart
├── services/
│   ├── auth_service.dart        # Service d'authentification Supabase + fallback démo
│   ├── geolocation_service.dart
│   ├── connectivity_service.dart
│   └── sync_service.dart
├── providers/
│   ├── auth_provider.dart       # State management Provider pour l'authentification
│   ├── queue_provider.dart
│   └── connectivity_provider.dart
├── screens/
│   ├── login_screen.dart        # Écran de connexion, inscription et accès démo
│   └── queue_screen.dart        # Écran principal avec contrôles adaptés selon le rôle
└── widgets/
    ├── client_card.dart
    ├── offline_banner.dart
    ├── loading_widget.dart
    └── queue_empty_widget.dart
```

---

## 3. Matrice des Droits et Privilèges (RBAC)

| Fonctionnalité | Rôle Client / Patient 👤 | Rôle Agent / Staff 👨‍⚕️ |
| :--- | :---: | :---: |
| **Connexion / Inscription** | ✅ | ✅ |
| **Voir la file d'attente** | ✅ | ✅ |
| **Bannière de position personnelle** | ✅ (*Position #X*) | ❌ (*Non concerné*) |
| **Rejoindre la file** | ✅ (*1-clic*) | ✅ (*Ajout libre*) |
| **Appeler le client suivant (Next Client)** | ❌ *(Bouton grisé / verrouillé)* | ✅ *(Bouton vert actif)* |
| **Supprimer un client (Swipe to dismiss)** | ❌ *(Interdit)* | ✅ *(Actif)* |
| **Synchronisation manuelle** | ✅ | ✅ |
| **Déconnexion** | ✅ | ✅ |

---

## 4. Tests et Validation

- **Tests unitaires et widgets exécutés** : `flutter test`
  - `test/providers/auth_provider_test.dart` : 6 tests validés (authentification, rôles, session, déconnexion).
  - `test/widgets/login_screen_test.dart` : 3 tests validés (bascule connexion/inscription, sélecteur de rôle, démo).
  - Tous les tests précédents (TP1 à TP6) continuent de passer sans régression.
- **Résultat global** : **54 / 54 tests passés avec succès** (`All tests passed!`).
- **Analyse statique Flutter** : `flutter analyze` : **0 erreur, 0 avertissement** (*No issues found!*).
