# LittleSteps — Project Summary

**Last Updated:** 2026-05-29  
**Current Phase:** Phase 2 complete, Phase 3 in progress (Phases 0–2 complete, Phase 3 tests and core features complete)

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
| Cloud AI | Gemini 2.0 Flash + Imagen 3 (via Vertex AI) |
| Local cache | Hive / Isar |

---

## Feature Status

| Feature | Phase | Status |
|---|---|---|
| Firebase Auth (Google Sign-In) | 1 | ✅ Complete |
| Photo upload + EXIF extraction | 1 | ✅ Complete |
| Masonry collage grid | 1 | ✅ Complete |
| Baby profile (name, DOB, photo) | 1 | ✅ Complete |
| Family invites (QR + link, roles) | 1 | ✅ Complete |
| Push notifications (FCM) | 1 | ✅ Complete |
| ML Kit image tagging | 2 | ✅ Complete |
| Monthly AI story (Claude Haiku) | 2 | ✅ Complete |
| AI milestone suggestions | 2 | ✅ Complete (13 types) |
| Image editor (enhance + annotate) | 2 | On-device tagging only |
| On This Day notifications | 2 | ✅ Complete |
| PDF collage export | 3 | Not started |
| Video reel (FFmpegKit) | 3 | Not started |
| Letters to the Future | 3 | In progress |
| Growth journal + charts | 3 | ✅ Complete |
| Voice notes | 3 | ✅ Complete |
| Performance audit | 4 | Not started |
| Onboarding flow | 4 | ✅ Complete |
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
