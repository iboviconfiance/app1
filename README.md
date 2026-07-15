# KLAS+ — Plateforme éducative

Application éducative complète pour le système scolaire congolais (Collège, Lycée Général, Lycée Technique, Lycée commercial).

## Stack technique

| Couche | Technologies |
|--------|-------------|
| Frontend | Flutter, Material Design 3, Provider, GoRouter |
| Backend | Node.js, Express.js, JWT |
| Base de données | PostgreSQL |
| ORM / Migrations | Sequelize |
| Architecture | Clean Architecture, Repository Pattern, MVC |

## Structure du projet

```
KLAS+/
├── backend/                 # API REST Node.js
│   ├── src/
│   │   ├── config/          # Configuration
│   │   ├── domain/entities/ # Modèles métier
│   │   ├── application/services/  # Logique applicative
│   │   ├── infrastructure/
│   │   │   ├── database/
│   │   │   │   ├── models/      # Modèles Sequelize
│   │   │   │   └── migrations/  # Migrations PostgreSQL
│   │   │   └── repositories/    # Accès aux données
│   │   └── presentation/
│   │       ├── controllers/     # Contrôleurs MVC
│   │       ├── routes/          # Routes REST
│   │       └── middleware/      # Auth JWT, validation
│   └── tests/               # Tests unitaires & intégration
├── frontend/                # Application Flutter
│   └── lib/
│       ├── config/
│       ├── providers/
│       ├── services/
│       └── screens/
├── docker-compose.yml
├── .env.example
└── README.md
```

## Modèles de données

- **User** — nom, prénom, téléphone, mot de passe, classe, série, établissement
- **Classroom** — classes scolaires (6ème → Terminale)
- **Series** — séries (A, C, D, F1-F4, Électricité, etc.)
- **Subject** — matières (Maths, Français, Anglais, etc.)
- **Course** — cours PDF/vidéo avec favoris et historique
- **Exercise** — QCM, quiz, examens blancs avec correction auto
- **Exam** — BEPC, BAC Général, BAC Technique, BET
- **Subscription** — Gratuit, Individuel, Familial
- **Payment** — Airtel Money, MTN Mobile Money
- **WorkGroup** — groupes de travail collaboratifs

## Hiérarchie scolaire

### Collège
6ème, 5ème, 4ème, 3ème

### Lycée Général
Seconde, Première, Terminale — Séries : A, C, D

### Lycée Technique
Seconde, Première, Terminale — Séries : F1, F2, F3, F4, Électricité, Électronique, Bâtiment, Mécanique, Informatique

### Matières (par série)
Mathématiques, Français, Anglais, Physique, SVT, Philosophie, Technologie, Dessin Technique

---

## Démarrage rapide

### Option A — Docker (recommandé, stack complète)

**Prérequis :** [Docker Desktop](https://www.docker.com/products/docker-desktop/) installé et démarré.

```bash
# Lancer PostgreSQL + API + Frontend Flutter Web
docker compose up --build

# Ou en arrière-plan
docker compose up --build -d
```

| Service    | URL |
|------------|-----|
| Application | http://localhost:8080 |
| API REST    | http://localhost:3000/api/health |
| PostgreSQL  | localhost:5432 |

**Compte démo :** `+237670000001` / `password123`

```bash
# Arrêter
docker compose down

# Tout supprimer (données incluses)
docker compose down -v
```

#### Fichiers Docker

| Fichier | Rôle |
|---------|------|
| `docker-compose.yml` | Orchestration des 3 services |
| `backend/Dockerfile` | API Node.js + migrations + seed |
| `backend/docker-entrypoint.sh` | Attente PostgreSQL, migrate, seed, start |
| `frontend/Dockerfile` | Build Flutter Web + Nginx |
| `frontend/nginx.conf` | SPA + proxy `/api` → backend |

#### Variables Docker (optionnel, fichier `.env` à la racine)

```env
DB_PASSWORD=klasplus_secret
JWT_SECRET=votre_secret_jwt
API_PORT=3000
FRONTEND_PORT=8080
```

---

### Option B — Développement local

**Prérequis :** Node.js 20+, PostgreSQL 16+, Flutter 3.16+

```bash
# 1. Base de données
docker compose up -d postgres

# 2. Backend
cd backend
cp .env.example .env
npm install
npm run db:migrate
npm run db:seed
npm run dev

# 3. Frontend
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_URL=http://localhost:3000/api
```

> Android émulateur : `--dart-define=API_URL=http://10.0.2.2:3000/api`

---

## API REST

### Authentification
| Méthode | Route | Description |
|---------|-------|-------------|
| POST | `/api/auth/register` | Inscription |
| POST | `/api/auth/login` | Connexion |
| POST | `/api/auth/forgot-password` | Mot de passe oublié |
| POST | `/api/auth/reset-password` | Réinitialisation |

### Utilisateur
| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/api/users/profile` | Profil |
| PUT | `/api/users/profile` | Mise à jour profil |

### Dashboard & Progression
| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/api/dashboard` | Progression, cours/exercices récents, abonnement |

### École
| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/api/school/hierarchy` | Hiérarchie complète |
| GET | `/api/school/classrooms` | Classes |
| GET | `/api/school/series` | Séries |
| GET | `/api/school/subjects` | Matières |

### Cours
| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/api/courses` | Liste des cours |
| GET | `/api/courses/:id` | Détail |
| POST | `/api/courses/:id/favorite` | Ajouter favori |
| GET | `/api/courses/:id/download` | Télécharger |
| POST | `/api/courses/:id/progress` | Suivi progression |

### Exercices & Examens
| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/api/exercises` | Liste |
| POST | `/api/exercises/:id/submit` | Soumettre (correction auto) |
| GET | `/api/exams` | Liste examens |
| POST | `/api/exams/:id/submit` | Soumettre examen |

### Abonnement & Paiements
| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/api/subscriptions/plans` | Forfaits |
| POST | `/api/subscriptions/subscribe` | S'abonner (Airtel/MTN) |
| GET | `/api/subscriptions/payments` | Historique paiements |

### Groupes de travail
| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/api/work-groups` | Mes groupes |
| POST | `/api/work-groups` | Créer |
| POST | `/api/work-groups/join` | Rejoindre (code) |
| GET | `/api/work-groups/:id` | Détail + membres |

---

## Tests

```bash
cd backend

# Tests unitaires
npm run test:unit

# Tests d'intégration (PostgreSQL requis)
npm run test:integration

# Tous les tests
npm test
```

---

## Variables d'environnement

Copiez `.env.example` vers `.env` :

```env
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=klasplus
DB_USER=klasplus
DB_PASSWORD=klasplus_secret
JWT_SECRET=change_me_in_production
JWT_EXPIRES_IN=7d
FRONTEND_URL=http://localhost:8080
```

---

## Forfaits

| Plan | Prix | Fonctionnalités |
|------|------|-----------------|
| Gratuit | 0 FCFA | Accès limité, 5 exercices/mois |
| Individuel | 5 000 FCFA | Accès illimité, tous exercices |
| Familial | 12 000 FCFA | Jusqu'à 5 comptes, support prioritaire |

**Paiements :** Airtel Money et MTN Mobile Money uniquement.

---

## Licence

Projet éducatif — KLAS+ © 2024