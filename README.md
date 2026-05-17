# LittleSteps

> *Every smile, every step, every story — forever captured and beautifully told.*

A multi-user Android baby memory app built with Flutter and Firebase. Capture photos, auto-tag them with on-device ML, let AI write monthly story narratives, and give the whole family — grandparents included — a beautiful, living memory book.

---

## Features

- **Collage home screen** — masonry photo grid auto-arranged by month, grouped and sorted automatically
- **Smart tagging** — Google ML Kit labels every photo on-device (bath time, outdoors, family, etc.) with zero data leaving the phone
- **AI monthly stories** — Claude Haiku reads the month's tags and writes a warm narrative of your baby's month
- **Milestone tracking** — standard checklist (first smile, first steps, first word) plus AI suggestions based on photo content and baby's age
- **Family circle** — invite grandparents and relatives via QR code or link; role-based access (Admin / Editor / Contributor / Viewer)
- **Growth journal** — log height, weight, and head circumference with percentile growth charts
- **Letters to the Future** — write messages locked until a date you choose (1st birthday, 18th birthday, etc.)
- **Export** — PDF collage, print-ready album, auto-generated video reel (MP4) shareable via WhatsApp
- **On This Day** — daily push notification surfacing a memory from the same date in a previous year
- **Offline-first** — core timeline and milestone screens work with no connectivity

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart) |
| State management | Riverpod 2.x |
| Navigation | GoRouter |
| Backend | Firebase (Auth, Firestore, Storage, Functions, FCM, Analytics, Crashlytics) |
| On-device ML | Google ML Kit (labeling, face detection, OCR), OpenCV (color correction) |
| Video | FFmpegKit Flutter |
| AI (cloud) | Anthropic Claude API Haiku — proxied via Cloud Functions |
| Local cache | Hive / Isar |
| Charts | fl_chart |

---

## Project Structure

```
lib/
├── main.dart                  # App entry, flavor detection
├── app.dart                   # MaterialApp, theme, GoRouter init
├── core/                      # Theme tokens, constants, extensions
├── features/
│   ├── auth/                  # Google sign-in, session
│   ├── baby/                  # Baby profile, multi-baby switching
│   ├── collage/               # Masonry grid, photo picker
│   ├── memory/                # Single memory view, EXIF, tags
│   ├── timeline/              # Chronological events, milestone overlay
│   ├── stories/               # Monthly AI narrative
│   ├── growth/                # Height/weight logs, charts
│   ├── letters/               # Letters to the Future
│   ├── export/                # PDF, video reel, share
│   ├── family/                # Invite flow, roles
│   └── settings/              # Preferences, account
└── shared/                    # MemoryCard, TagChip, LoadingOverlay

functions/src/
├── story-generator.ts         # Monthly story via Claude API
├── on-this-day.ts             # Scheduled daily notification
├── monthly-digest.ts          # End-of-month PDF trigger
├── resize-image.ts            # Auto-resize on Storage upload
└── invite-handler.ts          # Family invite link generation
```

---

## Roadmap

| Phase | Timeline | Focus |
|---|---|---|
| 1 — Foundation | Weeks 1–6 | Auth, collage, baby profile, family invites |
| 2 — AI & Intelligence | Weeks 7–12 | ML Kit tagging, Claude stories, milestone AI, image editing |
| 3 — Stories & Export | Weeks 13–18 | PDF, video reels, Letters to Future, growth journal |
| 4 — Polish & Scale | Weeks 19–24 | Performance, onboarding, Play Store submission |

---

## Getting Started

### Prerequisites

| Tool | Version |
|---|---|
| Flutter SDK | 3.19+ |
| Dart SDK | 3.3+ |
| Android Studio | Hedgehog+ |
| Node.js | 18.x LTS |
| Firebase CLI | Latest |
| FlutterFire CLI | Latest |

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/suraj-0023/little-footprints.git
cd little-footprints

# 2. Install Flutter dependencies
flutter pub get

# 3. Configure Firebase
flutterfire configure

# 4. Install Cloud Functions dependencies
cd functions && npm install && cd ..

# 5. Run on Android emulator (dev flavor)
flutter run --flavor dev -t lib/main_dev.dart
```

### Environment

The `ANTHROPIC_API_KEY` is stored only in Firebase Functions config and is never committed to this repo:

```bash
firebase functions:config:set anthropic.key="YOUR_KEY_HERE"
```

---

## Security

- All data is scoped to `familyId` — zero cross-family data access
- Firebase Security Rules enforce role-based access at the document level
- Photos served via signed URLs generated server-side (no public Storage URLs)
- On-device ML ensures photos are never sent to a third-party server for tagging
- Letters to the Future are encrypted client-side before storage
- Claude API key is stored only in Firebase Functions environment config

---

## Build Log

See [docs/evolution.md](docs/evolution.md) for a session-by-session record of everything built and why.

---

Built with [Claude Code](https://claude.com/claude-code)
