# Moka — MVP

Rebuilt from scratch after the original source was lost. This covers the full
access-fee business model you described, with production patterns applied
throughout (typed backend, validated env config, idempotent payment
reconciliation, DB-level pricing config, non-root Docker containers).

## Business model, as implemented

No money moves between customer and provider through the app. Two separate
platform fees:

1. **Star-tier unlock** — a customer pays Moka to unlock contact details for
   providers at a given star tier (`POST /api/unlocks`). Tier 1 is free by
   default; tiers 2–5 cost a configurable fee. An unlock is valid 30 days.
   Provider contact info (email/phone) is stripped server-side for any tier
   the customer hasn't paid to unlock — this is enforced in the API response,
   not just hidden in the UI.
2. **Job application fee** — a provider pays Moka a flat fee to apply to any
   customer's posted job (`POST /api/jobs/:jobId/applications`). The customer
   accepts/rejects for free once the fee is paid and the application is live.

Fees live in a `PricingConfig` DB row (`prisma/seed.ts`), not hardcoded in
source, so you can change pricing without a redeploy.

## Structure

```
backend/                       Node.js + Express + TypeScript + Prisma + PostgreSQL
app/                           Flutter — single app for both customers and providers
.github/workflows/build-app.yml  CI: builds an installable APK on every push
```

`app/` is one Flutter project serving both sides of the marketplace. At
registration the person picks "Customer" or "Provider"; the account's `role`
(stored server-side, same as before) decides which tabs and screens they see
afterwards — customers get "My jobs" + "Providers", providers get "Open
jobs" + "Applications". Nothing about the API or business model changed,
only that it's one codebase/APK instead of two.

## Backend — running it

```bash
cd backend
cp .env.example .env        # fill in real Paystack + Firebase credentials
npm install
docker compose up -d postgres
npx prisma migrate dev --name init
npx prisma db seed
npm run dev                 # http://localhost:4000
```

`npm run build && npm start` for production, or `docker compose up --build`
for the full containerized stack.

**Note on this environment:** I verified the backend with `npm install` and
`npx tsc --noEmit` — it compiles clean. I could not run `npx prisma generate`
here because this sandbox blocks the domain Prisma downloads its query engine
from (`binaries.prisma.sh`). Run `npx prisma generate` (it's also called
automatically by `migrate dev`) on your own machine or CI before `npm run
build` — normal network access resolves this immediately.

### Where the previous audit's gaps went
- **Migrations workflow** → Prisma migrations (`prisma/migrations/`), tracked
  and repeatable, replacing ad-hoc schema changes.
- **Dev/prod environment separation** → `env.ts` validates all required
  config at boot (via Zod) and fails fast with a clear error if anything's
  missing, rather than failing confusingly at runtime.
- **Paystack webhooks** → fully implemented: raw-body HMAC signature
  verification, server-side re-verification against Paystack's API (never
  trusts the webhook payload alone), and idempotent reconciliation (a
  duplicate webhook delivery is a no-op).
- **RLS** → this MVP moved off Supabase to a plain Postgres + Prisma setup, so
  authorization is enforced at the application layer (every query is scoped
  by `req.user.id` / role in middleware), not via Postgres row-level security.
  If you want DB-level RLS as a second line of defense, that's a follow-up —
  say the word and I'll add it.

## Flutter app — running it

The app itself only ships `lib/` + `pubspec.yaml` (no `android/`/`ios/`
folders checked in). Generate them once, locally or in CI:
```bash
cd app
flutter create --platforms=android,ios --org com.moka --project-name moka .
flutter pub get
```
(`flutter create` on a directory that already has a `pubspec.yaml` only adds
the missing platform folders — it won't touch your `lib/` or `pubspec.yaml`.)

Firebase: run `flutterfire configure` in `app/` to generate
`firebase_options.dart` / `google-services.json` / `GoogleService-Info.plist`
against your Firebase project (same project as `FIREBASE_PROJECT_ID` in the
backend `.env`). Until you do, `main.dart` catches the missing-config error
so the app still runs — you just won't get push notifications.

Point at your backend:
```bash
flutter run --dart-define=API_BASE_URL=https://your-api.example.com/api
```
(defaults to `http://10.0.2.2:4000/api`, the Android-emulator route to your
machine's localhost, for local testing).

### CI: get an APK without installing Flutter or Android Studio

`.github/workflows/build-app.yml` builds an APK on every push to `app/**`
and uploads it as a workflow artifact (Actions tab → the run → Artifacts).
Trigger it manually (Actions → "Build Moka app (APK)" → "Run workflow") to
pick `debug` vs `release` and pass a real `API_BASE_URL` — e.g. your
backend's public URL, since `10.2.2.2` only resolves from an emulator, not
a physical device. Download the APK, transfer it to an Android phone, and
install it (enable "Install unknown apps" for whichever app you use to open
the file).

Update `_callbackUrlPrefix` in `provider_job_detail_screen.dart` /
`provider_directory_screen.dart` to match `PLATFORM_CALLBACK_URL` in the
backend `.env` — the checkout webview watches for that prefix to know when
Paystack has redirected back.

## What's intentionally left for you

These don't block the core flows above but are real gaps for a production
launch:
- Password reset / forgot-password flow
- Provider profile editing (bio, skills, portfolio photos)
- An admin surface for star-level promotion and editing `PricingConfig`
  (right now both are DB-only — no UI)
- Automated tests (the backend has `vitest` wired up in `package.json` but no
  test files yet)
- Job cancellation / dispute handling after a provider is assigned
- Rate limiting tuned for your real traffic (current limits are reasonable
  defaults, not load-tested)

Infra (hosting, CI/CD, env provisioning) is yours per your original plan —
the Dockerfile and docker-compose.yml give you a containerized starting
point.
