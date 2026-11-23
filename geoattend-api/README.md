# GeoAttend API (Phase 1: authentication)

Node.js + Express + TypeScript, PostgreSQL via Prisma. Everything here is free to run.

## What exists in Phase 1

| Endpoint | Purpose |
|---|---|
| `POST /api/v1/auth/login` | Email + password (+ `portal`: employee / hod / admin) |
| `POST /api/v1/auth/register` | Employee self sign-up |
| `POST /api/v1/auth/refresh` · `/logout` | Rotate / revoke the refresh token |
| `POST /api/v1/auth/forgot` → `/verify-code` → `/reset` | 4-digit code flow |
| `GET/PATCH /api/v1/auth/me` | Profile |
| `POST /api/v1/auth/change-password` | Settings screen |
| `GET /health`, `GET /health/db` | Wake-up checks |

The whole database schema (all ER-diagram tables) is already in `prisma/schema.prisma`, so later phases add code, not migrations.

## Starting blank (no demo data)

`npx prisma db seed` now creates **only** the first admin (from `ADMIN_*` in `.env`) and the default working hours.
You then add workplaces, departments and employees from the app.
To wipe everything and start again: `npm run db:blank` (it asks you to confirm).
For the sample people and history instead: `npm run db:seed:demo`.

## Phase 2 (workplaces, departments, employees, admin overview)

| Endpoint | Who | Purpose |
|---|---|---|
| `GET /workplaces`, `GET /workplaces/:id` | any signed-in user | Admins see all, others only active ones |
| `POST /workplaces`, `PATCH /workplaces/:id` | admin | Add / edit (also used by Geofence: lat, lng, radius 50-500) |
| `GET /departments`, `GET /departments/:id` | admin, HOD | With HOD name and employee count |
| `POST /departments`, `PATCH /departments/:id` | admin | Add / edit |
| `GET /departments/hod-candidates` | admin | People who can be made HOD |
| `PUT /departments/:id/hod` | admin | Assign HOD (see rules below) |
| `GET/POST /employees`, `GET/PATCH /employees/:id` | admin | Employee management |
| `GET /admin/overview` | admin | Dashboard numbers |

Rules worth knowing:
- **New employees get a random password nobody knows.** They set their own with "Forgot Password" on the login screen (the code is emailed; in development it is printed in the terminal).
- **Assigning a HOD** promotes that person to the `hod` role, moves them into the department, and returns the previous HOD to `employee` if they head no other department. The person must sign in again to see the new role.
- **Deactivating an employee** signs them out everywhere and blocks login.
- Department, workplace and job title are sent **by name** (matching the app's dropdowns).
- The dashboard counts people with no attendance record as absent only after `ABSENT_AFTER_HOUR` (default 12:00, company time zone `TIMEZONE`) on weekdays, until the end-of-day absent job exists (Phase 5). Attendance numbers stay at 0 until Phase 3 (clock-in) exists.

No new migration is needed: the full schema was created in Phase 1.

## Phases 3-6 (attendance, leave, corrections, team, reports, notifications)

| Endpoint | Who | Purpose |
|---|---|---|
| `GET /attendance/me` | employee | Today + last 90 days (approved leave days included) |
| `POST /attendance/verify-location` | employee | Server-side geofence check (distance, radius) |
| `POST /attendance/clock-in`, `/clock-out` | employee | Server checks distance, fake GPS, accuracy; uses the **server clock** |
| `POST /attendance/sync` | employee | Offline clock-ins/outs captured on the phone |
| `POST /leave`, `GET /leave/mine`, `DELETE /leave/:id` | employee | Request, list, cancel (while pending) |
| `GET /leave/pending`, `PATCH /leave/:id/decision` | HOD, admin | **Two-stage**: HOD then HR (admin) |
| `POST /corrections`, `GET /corrections/mine` | employee | Ask to fix a clock-in/out |
| `GET /corrections/pending`, `PATCH /corrections/:id/decision` | HOD, admin | Approving rewrites the attendance record |
| `GET /team/attendance?date=&department=` | HOD, admin | Who was present/late/absent/on leave |
| `GET /reports?type=&date=&department=` | HOD, admin | Weekly, Monthly, By employee, Summary |
| `GET /notifications`, `POST /notifications/:id/read`, `/read-all` | everyone | In-app notifications |

Rules worth knowing:
- **Geofence is judged by the server.** The phone sends coordinates, accuracy and Android's "mock location" flag. Fake GPS is refused (and logged), and a fix worse than `MAX_GPS_ACCURACY_METERS` is refused.
- **Late** = clock-in after the employee's schedule start + grace period (default 08:00 + 15 min), in the company time zone.
- **Offline sync** keeps the time the employee actually clocked in, re-checks the geofence, rejects anything in the future or older than `OFFLINE_MAX_DAYS`, and is safe to retry.
- **Absent is derived, not stored.** A weekday with no record counts as absent (today only after `ABSENT_AFTER_HOUR`); approved leave counts as leave; weekends and days before the hire date are skipped. So no nightly job is needed.
- **Leave** goes to the employee's HOD first, then to HR (admin). With no HOD (or if the HOD is the requester) it goes straight to HR. Overlapping requests are refused.
- **Correction** approval changes the stored times and recomputes late/present.
- Notifications are created by events: clock-in, late alert to the HOD, leave and correction requests and decisions.
- HODs only ever see their own department, whatever the app sends.

Run the unit tests (no database needed): `npm test`.

## 1. Install the tools (free)

- Node.js 20 or newer (nodejs.org)
- PostgreSQL: either **install it locally**, or run `docker compose up -d` (Docker Desktop is free for personal use), or use a free **Neon** database (neon.com).
- VS Code with the free **REST Client** extension (to run `api.http`)

## 2. Set up

```bash
cd geoattend-api
npm install                      # also runs "prisma generate"
cp .env.example .env             # Windows: copy .env.example .env
```

Edit `.env`:
- `DATABASE_URL`: local default works with `docker compose`. For Neon, paste the **non-pooled** connection string (turn "Pooled connection" off).
- `JWT_SECRET`: generate one with
  `node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"`

Create the tables and demo data:

```bash
npx prisma migrate dev --name init   # creates prisma/migrations/ (commit this folder)
npx prisma db seed                   # demo company data and logins
npm run dev                          # http://localhost:3000
```

Demo logins (also printed by the seed):

| Role | Email | Password |
|---|---|---|
| Admin | admin@geoattend.app | Admin@123 |
| HOD (Sales) | james.wilson@geoattend.app | Hod@1234 |
| Employee | emmanuella@geoattend.app | Employee@123 |

## 3. Test it before touching the app

Open `api.http` in VS Code and click **Send Request** on each block: health, login, `/me`, a wrong-portal login (expect 403), register, forgot password.
In development the reset code is **printed in the terminal** where `npm run dev` runs, so no email setup is needed yet.

## 4. Deploy for free (Render + Neon)

1. Push `geoattend-api/` to a GitHub repository (the `.env` file is git-ignored; never commit it).
2. Neon: create a project, copy the non-pooled connection string.
3. Render: **New → Web Service**, connect the repo, runtime Node, plan **Free**, then set:
   - Build command: `npm ci --include=dev && npm run build && npx prisma migrate deploy`
   - Start command: `npm start`
   - Health check path: `/health`
   - Environment: `DATABASE_URL` (Neon string), `JWT_SECRET`, `NODE_ENV=production`, `COMPANY_NAME`
   (`render.yaml` in this folder describes the same thing.)
4. Seed the Neon database once from your computer: set `DATABASE_URL` in `.env` to the Neon string, then run `npx prisma db seed`.
5. Your API URL is `https://<your-service>.onrender.com`. Test `https://<your-service>.onrender.com/health`.

The free server sleeps when idle, so open `/health` and `/health/db` a few minutes before a demo to wake it.

Reset emails in production need SMTP. With Gmail: turn on 2-step verification, create an **App password**, then set `SMTP_HOST=smtp.gmail.com`, `SMTP_PORT=587`, `SMTP_USER=<your gmail>`, `SMTP_PASS=<app password>`, `MAIL_FROM`.

## 5. Connect the Flutter app

See the Flutter README ("Connecting to the API"). In short:

```bash
# Android emulator (default URL http://10.0.2.2:3000/api/v1)
flutter run
# iOS simulator (default URL http://localhost:3000/api/v1)
flutter run
# Physical phone or deployed API
flutter run --dart-define=API_URL=https://<your-service>.onrender.com/api/v1
```

## Project layout

```
prisma/        schema.prisma (all tables), seed.ts
src/
  app.ts, server.ts
  config/env.ts            validated environment variables
  middleware/              auth (JWT), validate (zod), rateLimit, errorHandler
  modules/auth/            routes -> controller -> service  (one folder per feature)
  utils/                   jwt, crypto, mailer, audit, serializers
api.http                   requests to try in VS Code
```

Each Flutter feature (`attendance`, `leave`, ...) gets a matching `src/modules/<feature>/` folder in the next phases.

## Rules enforced

- Passwords: 6+ characters with a number (same as the app), stored with bcrypt.
- The server decides the role; a wrong login screen gets a clear 403.
- Refresh tokens are random, stored hashed, rotated on every use, and revoked on logout, password reset and password change.
- Reset codes: 4 digits, hashed, valid 3 minutes, 5 attempts, never revealed to unknown emails.
- Login and code endpoints are rate limited.
- Every sign-in, sign-up, profile and password change is written to `audit_logs`.
