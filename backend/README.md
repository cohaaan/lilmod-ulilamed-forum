# Lilmod Ulilamed — Django API

Django 5 + Django REST Framework + PostgreSQL + JWT auth.

## Quick start (Docker)

From the repo root:

```bash
docker compose up --build
```

API: http://localhost:8000  
Admin: http://localhost:8000/admin/

Create a superuser:

```bash
docker compose exec web python manage.py createsuperuser
```

## Local development (without Docker)

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# Start Postgres locally, then:
python manage.py migrate
python manage.py runserver
```

## Auth API (`/api/v1/`)

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/auth/register/` | No | Register; returns user + JWT tokens |
| POST | `/auth/login/` | No | Login with email + password |
| POST | `/auth/refresh/` | No | Refresh access token |
| POST | `/auth/logout/` | Yes | Blacklist refresh token (`{"refresh": "..."}`) |
| GET | `/me/` | Yes | Current member profile |

### Register example

```bash
curl -X POST http://localhost:8000/api/v1/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "isaac@example.com",
    "password": "securepass123",
    "display_name": "Isaac Cohen",
    "handle": "isaac_c"
  }'
```

### Login example

```bash
curl -X POST http://localhost:8000/api/v1/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username": "isaac@example.com", "password": "securepass123"}'
```

Note: SimpleJWT expects the field name `username`, but the value is the member's email.

## Release 1 progress

- [x] Django/DRF/Postgres scaffold
- [x] JWT auth (register, login, refresh, logout, me)
- [x] `MemberProfile` model
- [x] Django Admin
- [ ] Forum models (Category, Subforum, Thread, Post)
- [ ] Forum API endpoints
- [ ] Seed data

See [`../MVPPLAN.md`](../MVPPLAN.md) for the full roadmap.
