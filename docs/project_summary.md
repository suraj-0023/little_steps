# LittleSteps — Project Summary

**Last Updated:** 2026-05-17  
**Current Phase:** Pre-build (setup complete, Phase 1 not yet started)

---

## What We're Building

A multi-user Android baby memory app built in Flutter. Parents capture photos, the app auto-tags them, AI writes monthly story narratives, and the whole family (grandparents, relatives) can contribute and view memories — all beautifully arranged in a chronological collage.

**Tagline:** *"Every smile, every step, every story — forever captured and beautifully told."*

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter 3.x, Dart, Riverpod 2.x, GoRouter |
| Backend | Firebase (Auth, Firestore, Storage, Functions, FCM) |
| On-device ML | Google ML Kit, OpenCV, FFmpegKit |
| Cloud AI | Claude API Haiku (via Cloud Functions) |
| Local cache | Hive / Isar |

---

## Feature Status

| Feature | Phase | Status |
|---|---|---|
| Firebase Auth (Google Sign-In) | 1 | Not started |
| Photo upload + EXIF extraction | 1 | Not started |
| Masonry collage grid | 1 | Not started |
| Baby profile (name, DOB, photo) | 1 | Not started |
| Family invites (QR + link, roles) | 1 | Not started |
| Push notifications (FCM) | 1 | Not started |
| ML Kit image tagging | 2 | Not started |
| Monthly AI story (Claude Haiku) | 2 | Not started |
| AI milestone suggestions | 2 | Not started |
| Image editor (enhance + annotate) | 2 | Not started |
| On This Day notifications | 2 | Not started |
| PDF collage export | 3 | Not started |
| Video reel (FFmpegKit) | 3 | Not started |
| Letters to the Future | 3 | Not started |
| Growth journal + charts | 3 | Not started |
| Voice notes | 3 | Not started |
| Performance audit | 4 | Not started |
| Onboarding flow | 4 | Not started |
| Multi-baby support | 4 | Not started |
| Play Store submission | 4 | Not started |

---

## Roadmap

| Phase | Weeks | Goal |
|---|---|---|
| 1 — Foundation | 1–6 | Core app end-to-end: photos in, timeline out, family sharing live |
| 2 — AI & Intelligence | 7–12 | Smart tagging, story generation, milestone AI, image editing |
| 3 — Stories & Export | 13–18 | PDF, video reels, Letters to Future, growth journal |
| 4 — Polish & Scale | 19–24 | Performance, onboarding, Play Store submission |

---

## Key Design Decisions

- **No print dependency** — India-first, export via WhatsApp/Google Drive instead
- **Free in v1** — no paywall, grow the user base first
- **On-device ML** — ML Kit and FFmpeg run locally; photos never leave the device for tagging
- **Claude API only via Cloud Functions** — API key never exposed to the client
- **Offline-first** — core timeline/milestone screens work with no connectivity
- **Grandparent-accessible UX** — simplified contributor interface, zero friction
