# ScanVault — Mobile Document Workspace

> Mobile-First Progressive Web App (PWA) for document scanning, PDF management, OCR, annotations, signatures, and offline-first storage.

---

## 📱 Core Architecture Principles

1. **Mobile First**: Optimized primarily for viewports 320px–430px (iPhone, Pixel, Galaxy) with responsive scaling up to 1440px+ desktop.
2. **Offline First**: All scanning, image processing, OCR, and PDF rendering operate offline using browser-local IndexedDB (Dexie).
3. **Touch First**: All interactive elements adhere to standard $\ge 44\text{px} \times 44\text{px}$ touch targets with safe-area inset support (`env(safe-area-inset-*)`).
4. **Zero Binary Storage in SQL**: PostgreSQL holds metadata and relational synchronization only; actual PDF/image blobs stay client-side or in dedicated object stores.
5. **Type Safety**: End-to-end TypeScript strict mode from database to UI.

---

## 🛠️ Technology Stack

### Frontend (`apps/web`)
- **Framework**: React 19 + TypeScript + Vite 6
- **Styling**: Tailwind CSS (Mobile-first breakpoints & safe-area utilities)
- **Routing**: React Router 7
- **Offline Storage**: Dexie IndexedDB (`ScanVaultLocalDB`)
- **Icons**: Lucide React
- **Validation**: Zod
- **Testing**: Vitest + React Testing Library

### Backend (`apps/server`)
- **Runtime**: Node.js 24 LTS + Express
- **Language**: TypeScript (strict mode)
- **Database ORM**: Prisma ORM 7 (`@prisma/adapter-pg`)
- **Database**: PostgreSQL 18
- **Security**: Helmet, CORS, Zod environment validation, centralized error handling

### Shared (`packages/shared`)
- Shared DTOs, API response wrappers, and common type definitions.

---

## 📁 Repository Structure

```
ScanVault/
├── apps/
│   ├── web/                     # React + TypeScript + Vite + Tailwind + Dexie
│   │   ├── public/              # PWA manifest, service worker, icons
│   │   ├── src/
│   │   │   ├── components/      # Reusable UI components & Error Boundary
│   │   │   ├── layouts/         # Responsive RootLayout with safe-area support
│   │   │   ├── lib/             # Dexie IndexedDB client abstraction
│   │   │   ├── pages/           # Application views
│   │   │   └── styles/          # Mobile-first CSS & safe-area utilities
│   │   └── vite.config.ts       # Vite configuration with /api/v1 proxy
│   └── server/                  # Express + TypeScript + Prisma 7 backend
│       ├── src/
│       │   ├── config/          # Zod environment validation
│       │   ├── lib/             # Prisma 7 adapter-pg connection pool
│       │   ├── middleware/      # Centralized error handler & 404 handler
│       │   └── routes/          # API v1 routes (/api/v1/health)
│       └── tests/               # Vitest API & env tests
├── packages/
│   └── shared/                  # Shared TypeScript types & API contracts
├── prisma/
│   └── schema.prisma            # Prisma 7 PostgreSQL schema (8 core models)
├── .env.example
├── .gitignore
├── package.json                 # Monorepo root using npm workspaces
├── tsconfig.base.json
└── README.md
```

---

## 🚀 Getting Started

### 1. Prerequisites
- **Node.js**: $\ge 22.0.0$ (Node 24 LTS recommended)
- **npm**: $\ge 10.0.0$
- **PostgreSQL**: Running locally (default port: `5432`)

### 2. Installation
```bash
npm install
```

### 3. Environment Variables
Copy `.env.example` to `.env` in the root directory:
```bash
cp .env.example .env
```
Update `DATABASE_URL` with your local PostgreSQL credentials:
```env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/scanvault
PORT=4000
NODE_ENV=development
SESSION_SECRET=development_super_secret_session_key_min_32_characters_long
```

### 4. Database Setup & Prisma 7
Generate the Prisma 7 client:
```bash
npm run prisma:generate
```
Run migrations:
```bash
npm run prisma:migrate
```

### 5. Running Development Servers
Start both Frontend and Backend concurrently:
```bash
npm run dev
```
Or run individually:
- **Frontend**: `npm run dev:web` (Accessible at `http://localhost:5173`)
- **Backend**: `npm run dev:server` (Accessible at `http://localhost:4000`)

---

## 🧪 Testing, Linting & Verification

```bash
# Typecheck all workspaces
npm run typecheck

# Run all unit tests
npm run test

# Build production bundle
npm run build
```

---

## 📲 Mobile Development & Testing

1. **Responsive Viewport Testing (Desktop Chrome)**:
   - Open DevTools (`F12` or `Ctrl+Shift+I`)
   - Click the Device Toggle icon (`Ctrl+Shift+M`)
   - Test presets: iPhone 14/15 Pro (393px), Pixel 7 (412px), iPhone SE (375px), Galaxy S20 (360px).
2. **Physical Device Testing (Local Network)**:
   - Vite is configured with `host: true`.
   - Access via your computer's local IP (e.g. `http://192.168.1.X:5173`) from your mobile browser.

---

## 🗺️ Product Roadmap

- [x] **01 Foundation** (Monorepo, React 19, Express, Prisma 7, Dexie IndexedDB, PWA setup)
- [ ] **02 New Mobile UI** (Clean mobile workspace, bottom sheets, navigation shell)
- [ ] **03 Authentication + Google OAuth** (Sessions, secure cookies, accounts)
- [ ] **04 Local Document Vault** (IndexedDB blob engine, folders, tagging)
- [ ] **05 Camera Scanner** (Live edge detection, auto-capture, multi-page)
- [ ] **06 Image Editor** (Perspective crop, magic filters, rotation, clean-up)
- [ ] **07 PDF Engine** (Client-side PDF generation, compression, page sizes)
- [ ] **08 Document Management** (Search, batch actions, export, sharing)
- [ ] **09 OCR + Search** (On-device text extraction, full-text search)
- [ ] **10 PDF Tools** (Merge, split, extract, reorder, compress)
- [ ] **11 Annotation + Signature** (Drawing canvas, vector signatures, text stamps)
- [ ] **12 PWA + Production Security** (Service worker caching, offline sync, hardening)
