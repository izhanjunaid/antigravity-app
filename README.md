# 🎓 Ibex Classroom

A modern school management and learning platform built with Flutter Web — deployed as a **Progressive Web App (PWA)** on Vercel with full iOS Safari installability.

---

## 🚀 Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.41.4 (Dart SDK ^3.11.1) |
| **Backend / DB** | Supabase (PostgreSQL + Auth + Storage + Realtime) |
| **Routing** | go_router v17 |
| **State** | Provider |
| **Deployment** | Vercel |
| **CI/CD** | GitHub Actions |
| **PWA** | Offline-first service worker, manifest.json, iOS splash |

---

## 🛠️ Local Development

### Prerequisites
- Flutter 3.41.4 stable (`flutter --version`)
- Chrome browser

### Run locally
```bash
cd flutter_app

# Option A: VS Code — use the "Ibex Classroom (Web)" launch config

# Option B: Terminal
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

### Build for production locally
```bash
cd flutter_app

flutter build web \
  --release \
  --pwa-strategy=offline-first \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --base-href "/"

# Output is in: build/web/
```

---

## 🌐 Vercel Deployment

### First-time Setup

1. **Install Vercel CLI**
   ```bash
   npm install -g vercel
   ```

2. **Login & link project**
   ```bash
   cd flutter_app
   vercel login
   vercel link   # Creates .vercel/project.json
   ```

3. **Set environment variables in Vercel dashboard**
   - Go to: Project → Settings → Environment Variables
   - Add:
     - `SUPABASE_URL` = `https://your-project.supabase.co`
     - `SUPABASE_ANON_KEY` = `eyJ...`

4. **Deploy**
   ```bash
   vercel --prod
   ```

### Manual deploy (bypassing CI)
```bash
cd flutter_app
bash build.sh   # Requires env vars to be set locally
vercel build/web --prod --token=$VERCEL_TOKEN
```

---

## ⚙️ GitHub Actions CI/CD

The pipeline at `.github/workflows/deploy.yml` automatically:
1. Runs `flutter analyze`
2. Runs `flutter test`
3. Builds Flutter Web in release mode
4. Deploys to Vercel production

### Required GitHub Secrets
Go to: Repository → Settings → Secrets and Variables → Actions → New repository secret

| Secret | Description |
|---|---|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Your Supabase anon/public key |
| `VERCEL_TOKEN` | From [vercel.com/account/tokens](https://vercel.com/account/tokens) |
| `VERCEL_ORG_ID` | From `.vercel/project.json` (run `vercel link` first) |
| `VERCEL_PROJECT_ID` | From `.vercel/project.json` (run `vercel link` first) |

---

## 📱 PWA Installation

### iOS Safari
1. Open the app URL in Safari
2. Tap the **Share** button (box with arrow)
3. Scroll down and tap **"Add to Home Screen"**
4. Tap **Add** — the app installs with a custom icon

### Android Chrome
1. Open the app URL in Chrome
2. Tap the **three-dot menu** (⋮)
3. Tap **"Add to Home Screen"** or **"Install App"**
4. Confirm installation

### Desktop (Chrome/Edge)
1. Look for the **install icon** in the address bar
2. Click it and confirm

---

## 🏗️ Project Structure

```
flutter_app/
├── .github/
│   └── workflows/
│       └── deploy.yml          # CI/CD pipeline
├── .vscode/
│   └── launch.json             # VS Code debug configs
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart   # Config via dart-define
│   │   ├── models/
│   │   └── services/
│   ├── features/               # Feature modules (auth, dashboard, etc.)
│   └── shared/                 # Shared widgets, themes
├── web/
│   ├── index.html              # Full PWA meta tags + iOS splash
│   ├── manifest.json           # PWA manifest (W3C compliant)
│   ├── generate_splash.py      # Script to generate iOS splash images
│   ├── icons/                  # App icons (192, 512, maskable)
│   └── splash/                 # iOS launch images (generated)
├── build.sh                    # Vercel build script
└── vercel.json                 # Vercel deployment config
```

---

## 🔐 Security

- Supabase credentials are injected via `--dart-define` at **compile time** — they are embedded in the compiled JS but this is expected for Supabase's public anon key design.
- RLS (Row Level Security) is enforced at the database level — the anon key alone cannot bypass it.
- Security headers (X-Frame-Options, XSS-Protection, etc.) are applied via `vercel.json`.

---

## 🐛 Troubleshooting

| Issue | Fix |
|---|---|
| App shows blank page on refresh | Vercel `rewrites` handles SPA routing — ensure `vercel.json` is committed |
| Supabase 401 errors | Check that `SUPABASE_URL` and `SUPABASE_ANON_KEY` are correctly set in Vercel env vars |
| iOS "Add to Home Screen" not working | Ensure you're on HTTPS and `apple-mobile-web-app-capable` is in `index.html` |
| Build fails on Vercel | Check build logs for Flutter download issues — the Flutter tarball is ~500MB |
| Service worker not updating | Hard refresh with Ctrl+Shift+R or clear site data |
