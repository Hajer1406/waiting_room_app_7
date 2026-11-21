# 🤖 Utilisation de l'Intelligence Artificielle — TP7 (Gestion Multi-Utilisateur)

Ce document décrit comment l'intelligence artificielle a été utilisée comme assistant de conception et de développement au cours du **TP7 : Ajouter la gestion multi-utilisateur (et explication du multi-tenant)** sur l'application **Waiting Room**.

---

## 1. Informations sur l'Agent et l'Environnement

| Champ | Valeur |
| :--- | :--- |
| **Agent IA** | Antigravity (Google DeepMind) |
| **Modèles utilisés** | Gemini 3.8 Flash (High) & Claude Sonnet 4.6 (Thinking) |
| **Environnement / IDE** | Antigravity IDE (Architecture VS Code) sur Windows 11 |
| **Projet** | `waiting_room_app` (Flutter 3.x / Dart) |
| **Branche Git** | `tp7` |
| **Backend** | Supabase (Authentication, PostgreSQL, Realtime) |
| **Date de réalisation** | 21 novembre 2026 |

---

## 2. Objectifs du TP7

Le TP7 a pour objectif de faire évoluer l'application de salle d'attente partagée (qui était jusqu'alors anonyme et ouverte à tous) vers une **application sécurisée multi-utilisateur** intégrant un contrôle d'accès basé sur les rôles (**RBAC** - *Role-Based Access Control*) :

1. **Authentification des utilisateurs** :
   - Mise en place de l'inscription (*Sign Up*) et de la connexion (*Sign In*) avec Supabase Auth (Email + Mot de passe).
   - Gestion de la session active et de la déconnexion (*Sign Out*).
2. **Gestion des rôles (RBAC)** :
   - 👨‍⚕️ **Rôle Agent / Staff** : Médecin, secrétaire ou guichetier chargé de gérer et faire avancer la file d'attente.
   - 👤 **Rôle Client / Patient** : Usager attendant son tour dans la file d'attente.
3. **Contrôle d'accès et séparation stricte des privilèges dans l'interface** :
   - L'**Agent** dispose des privilèges complets : vue globale de la file, ajout de n'importe quel client, appel du prochain client (*Next Client*), et suppression de clients.
   - Le **Client** bénéficie d'une interface adaptée : une bannière personnalisée lui indique sa position exacte dans la file (*« Vous êtes dans la file : Position #2 sur 6 »*), un bouton en 1-clic lui permet de rejoindre la file, tandis que les actions d'administration (*Next Client* et suppression d'autres clients) lui sont **strictement interdites et désactivées**.
4. **Interface d'Authentification Épurée et Professionnelle** :
   - Formulaire d'authentification soigné Material 3, sans éléments superflus de débogage, avec validation stricte des champs (email, mot de passe, nom et sélection de rôle).
   - Gestion claire des messages d'erreur et explications adaptées aux retours de Supabase.
5. **Compréhension de la notion optionnelle Multi-Tenant** :
   - Analyse et documentation de l'architecture multi-locataire (isolation des files par cabinet/organisation via un `tenant_id` et des politiques Supabase Row Level Security).

---

## 3. Architecture Technique en Couches

L'architecture en couches de l'application a été enrichie tout en préservant le code des TP précédents :

```text
lib/
├── main.dart                               # Initialisation Supabase, MultiProvider et routage dynamique (Login/Queue)
├── models/
│   ├── app_user.dart                       # Modèle AppUser et enum UserRole (staff, client)
│   ├── client.dart                         # Modèle Client (lat, lng, syncStatus...)
│   ├── sync_status.dart                    # Suivi du statut de synchronisation
│   ├── app_connectivity.dart               # États de connectivité réseau
│   └── queue_state.dart                    # États de chargement de la file
├── services/
│   ├── auth_service.dart                   # Service d'authentification Supabase Auth + gestion des sessions
│   ├── geolocation_service.dart            # Service GPS (TP6)
│   ├── connectivity_service.dart           # Surveillance réseau (TP6)
│   └── sync_service.dart                   # Synchronisation hors-ligne (TP6)
├── providers/
│   ├── auth_provider.dart                  # Provider d'état pour l'authentification et les droits d'accès
│   ├── queue_provider.dart                 # Provider de la file d'attente et pagination
│   └── connectivity_provider.dart          # Provider de surveillance réseau
├── screens/
│   ├── login_screen.dart                   # Écran d'authentification (Connexion / Inscription / Démo)
│   └── queue_screen.dart                   # Écran principal avec adaptation des contrôles selon le rôle
└── widgets/
    ├── client_card.dart                    # Carte affichant les détails d'un client
    ├── offline_banner.dart                 # Bannière de statut réseau
    ├── loading_widget.dart                 # Indicateur de chargement
    └── queue_empty_widget.dart             # État vide de la file
```

---

## 4. Matrice des Droits et Privilèges (RBAC)

| Fonctionnalité | Rôle Client / Patient 👤 | Rôle Agent / Staff 👨‍⚕️ |
| :--- | :---: | :---: |
| **Connexion / Inscription par Email** | ✅ | ✅ |
| **Accès Démo 1-Clic** | ✅ | ✅ |
| **Visualisation de la file d'attente** | ✅ | ✅ |
| **Bannière de position personnelle** | ✅ (*Position #X*) | ❌ (*Non concerné*) |
| **Bouton rapide « Rejoindre la file »** | ✅ (*Auto-inscription*) | ✅ (*Ajout libre*) |
| **Appel du client suivant (Next Client)** | ❌ *(Bouton grisé / verrouillé)* | ✅ *(Bouton vert actif)* |
| **Suppression d'un client (Swipe to dismiss)** | ❌ *(Désactivé)* | ✅ *(Actif)* |
| **Synchronisation manuelle** | ✅ | ✅ |
| **Déconnexion (Logout)** | ✅ | ✅ |

---

## 5. Résumé Chronologique des Discussions avec l'Agent IA (Antigravity)

### 5.1 Clarification du sujet du TP7 et de la notion de Multi-Tenant
* **Question de l'étudiante** :
  > *« TP7 ... 100 points : Ajouter la gestion multi-utilisateur. Optionnel : ajouter une fonctionnalité multi-tenant — que signifie ça ? »*
* **Explication apportée par l'IA** :
  - **Multi-utilisateur** : Sécurisation de l'application par comptes individuels et gestion des rôles (Admin/Agent vs Client/Patient).
  - **Multi-tenant (Multi-locataire)** : Architecture où une unique instance applicative sert plusieurs organisations (cabinets médicaux, cliniques, guichets) de façon strictement étanche grâce à un identifiant d'organisation (`tenant_id`) et des règles RLS dans la base de données.
* **Cadrage du périmètre** :
  - L'étudiante a validé la mise en œuvre du **multi-utilisateur complet** (authentification, rôles, contrôle d'accès) sur une nouvelle branche Git `tp7`.

### 5.2 Création de la branche Git `tp7` et mise en place des modèles
* **Action de l'IA** :
  - Création et bascule sur la branche `tp7` (`git checkout -b tp7`).
  - Implémentation du modèle utilisateur `AppUser` et de l'enum `UserRole` dans `lib/models/app_user.dart`.
  - Intégration du rôle dans les métadonnées de l'utilisateur Supabase (`user_metadata['role']`).

### 5.3 Développement des services et providers d'authentification
* **Action de l'IA** :
  - Création de `AuthService` (`lib/services/auth_service.dart`) : encapsule les appels `signUp`, `signInWithPassword`, `signOut` et propose une méthode de démonstration rapide `signInAsDemo`.
  - Création de `AuthProvider` (`lib/providers/auth_provider.dart`) : gère l'état réactif de l'utilisateur connecté, les notifications aux widgets (`ChangeNotifier`), et expose les getters `isStaff` et `isClient`.

### 5.4 Création de l'interface graphique d'authentification (`LoginScreen`)
* **Action de l'IA** :
  - Développement de `lib/screens/login_screen.dart` avec un design soigné Material 3.
  - Bascule interactive entre les modes **Connexion** et **Inscription**.
  - En mode inscription : saisie du nom et choix du rôle via des `ChoiceChip`.
  - Boutons de démonstration rapide permettant de basculer en un clic entre le profil **Agent** et le profil **Client**.

### 5.5 Adaptation de l'écran principal (`QueueScreen`) et du point d'entrée (`main.dart`)
* **Action de l'IA** :
  - Affichage dans l'`AppBar` du nom de l'utilisateur connecté et de son badge de rôle, avec bouton de déconnexion.
  - Pour le **Client** : affichage d'une bannière informative lui indiquant sa position dans la file (*Position #X sur Y*), bouton rapide pour rejoindre la file, verrouillage du bouton *Next Client*, et désactivation du glissement pour supprimer les clients.
  - Pour l'**Agent** : conservation du plein contrôle sur la file (bouton *Next Client* vert actif, suppression autorisée).
  - Mise à jour de `main.dart` avec routage dynamique : si l'utilisateur est connecté, affichage de `QueueScreen`, sinon redirection vers `LoginScreen`.

### 5.6 Stratégie de tests et validation sans régression
* **Action de l'IA** :
  - Rédaction de 6 tests unitaires pour `AuthProvider` (`test/providers/auth_provider_test.dart`).
  - Rédaction de 3 tests de widgets pour `LoginScreen` (`test/widgets/login_screen_test.dart`).
  - Exécution complète des vérifications :
    - `flutter analyze` : **0 erreur, 0 avertissement** (*No issues found!*).
    - `flutter test` : **54 tests passés avec succès** (45 tests antérieurs préservés + 9 nouveaux tests TP7).
  - Commit final et push de la branche `tp7` vers GitHub.

---

## 6. Guide de Démonstration pour l'Évaluation

Pour tester et présenter le TP7 à l'enseignant :

1. **Lancement de l'application** :
   ```bash
   flutter run -d chrome
   # ou sur Windows desktop :
   flutter run -d windows
   ```
2. **Test du rôle Client (Patient)** :
   - Sur l'écran de bienvenue, cliquez sur le bouton rapide **« Client (Patient) »**.
   - Vous arrivez sur la file d'attente. L'AppBar affiche `Patient Sarah • Client / Patient`.
   - Cliquez sur **« Rejoindre »** : le patient est ajouté dans la file et la bannière passe au vert en indiquant sa position exacte (ex. *Position #1 sur 1*).
   - Constatez que le bouton en bas affiche **`Next Client (Réservé aux Agents)`** et est désactivé.
   - Cliquez sur l'icône de déconnexion dans l'AppBar.
3. **Test du rôle Agent (Médecin / Staff)** :
   - Cliquez sur le bouton rapide **« Agent (Dr) »**.
   - L'AppBar affiche `Dr. Martin • Agent / Staff`.
   - Le bouton vert **`Next Client`** est actif et cliquable : en appuyant dessus, le premier client de la file est appelé et traité.
   - L'agent peut également glisser un client vers la gauche pour le supprimer de la file.

---

## 7. Bilan du TP7

Le TP7 est **pleinement fonctionnel et validé**. L'application respecte les principes de sécurité, sépare clairement les privilèges administratifs des droits des usagers, et conserve une compatibilité totale avec les fonctionnalités de résilience (géolocalisation, persistance locale SQLite et synchronisation) développées lors des ateliers précédents.
