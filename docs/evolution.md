# LittleSteps — Build Log

A running record of every session: what we did, why, and what's next.  
Most recent entry is always at the top.

---

## 2026-05-19 — AI Provider Migration: Gemini 2.0 Flash + Imagen 3

**What:** Replaced Anthropic Claude Haiku with Google Gemini 2.0 Flash for story text and Imagen 3 for story illustration generation.

**Why:** User preference — consolidate AI on Google's ecosystem (Gemini + Imagen 3 via Vertex AI), removing the need for an Anthropic API key.

**Impact:** Monthly stories now also generate a watercolor-style illustration using Imagen 3. The illustration appears as a hero image on the story detail screen and as a card banner on the stories list. No API key management required — Vertex AI auth is automatic via Firebase service account.

**Technical Detail:**
- `functions/src/story_generator.ts`: Gemini via `@google-cloud/vertexai` SDK; Imagen 3 via Vertex AI REST endpoint with `google-auth-library` ADC
- `story.dart`: Added `illustrationUrl` field
- `story_detail_screen.dart`: `_IllustrationHero` widget at top of screen
- `stories_screen.dart`: `_StoryCard` shows 140px illustration banner
- `CLAUDE.md` + `docs/MANUAL_STEPS.md`: Updated setup instructions (enable Vertex AI API, no key needed)

---

## 2026-05-18 — Bug Fix Batch: Session 2 Remaining Fixes

**What:** Fixed 7 remaining bugs identified by code review agents: sign-out navigation, Firestore rules stories write permission, Cloud Function Timestamp type mismatch, story repository null check, memory voice note cleanup, collage concurrent upload guard, and onboarding redirect synchronization.

**Why:** Bug-hunting agents identified these issues from the previous session; they were deferred due to context limits.

**Impact:** Sign-out now correctly navigates to auth screen. New users see onboarding before auth. Cloud Function story queries use correct Firestore Timestamp types instead of ISO strings. Concurrent uploads are guarded. Voice notes are properly cleaned up on memory deletion. Onboarding completion is synced to ensure proper navigation flow.

**Technical Detail:**
- `settings_screen.dart`: `context.go('/auth')` after sign-out + SnackBar error feedback
- `firestore.rules`: stories write rule changed to `allow write: if false` (Cloud Functions Admin SDK only)
- `functions/src/story_generator.ts`: ISO string dates → `admin.firestore.Timestamp.fromDate(...)` for range queries
- `story_repository.dart`: added `!doc.exists` null check before `doc.data()!`
- `memory_repository.dart`: `deleteMemory` now deletes `voice.m4a` from Storage (best-effort, catch errors)
- `collage_screen.dart`: early return in `_pickAndUpload` if upload already in progress
- `onboarding_provider.dart` + `main_dev.dart` + `main_prod.dart` + `app_router.dart`: `onboardingDoneSync` top-level bool read in `main()` for synchronous router redirect

---

## 2026-05-18 — Initial GitHub Push (Phases 0–2 Complete)

**What**: First commit of the LittleSteps project to GitHub. Includes all Phase 0 (foundation), Phase 1 (core features), and Phase 2 (AI & intelligence) work.

**Why**: Establishing version control baseline for the project.

**Impact**: Full working app with Google Sign-In, Firebase Auth/Firestore/Storage, memory upload with ML Kit auto-tagging, timeline with milestones, family invite QR codes, FCM notifications, and monthly story generator (requires Cloud Functions deployment for AI stories).

**Technical Detail**:
- `lib/features/` — auth, baby, collage, memory, timeline, stories, growth, family, settings
- `lib/core/` — router (GoRouter + ShellRoute), theme, constants, services (FCM), utilities (ML tagger)
- `lib/shared/` — reusable widgets
- `functions/src/` — story_generator Cloud Function (TypeScript, calls Claude Haiku API)
- `android/` — Kotlin DSL Gradle, Firebase config, core library desugaring enabled

---

## 2026-05-17 — Project Setup

**What:**
- Created the `Little Footprints` project folder on Desktop
- Added all 6 planning documents (project brief, architecture, roadmap, Claude Code prompts, UI/UX spec, developer onboarding guide)
- Initialized git repository locally
- Created `CLAUDE.md` with Claude Code workflow instructions (GitHub push process, Flutter commands, code navigation, architecture rules)
- Created `docs/evolution.md` (this file) and `docs/project_summary.md`
- Created `README.md` for GitHub

**Why:**
- Project kickoff — establishing the foundation before writing any Flutter code

**What's next:**
- Create GitHub repo at `github.com/suraj-0023/little-footprints` and push
- Begin Phase 1: Flutter project scaffold, Firebase setup, auth, collage grid, baby profile, family invites

---

## 2026-05-17 — Steps 1.3 + 1.4: Memory Upload + Masonry Collage

**What:**
- `ExifData` model (takenAt, GPS coords, camera make/model)
- `Memory` model with full Firestore serialization
- `ExifExtractor` utility (JPEG byte parser, falls back to file mtime)
- `MemoryRepository`: `uploadMemory` (compress → thumbnail → Storage upload → Firestore doc), `watchMemories` (real-time stream), `getMemory`, `updateCaption`, `addTags`, `deleteMemory`
- `memoriesProvider` (StreamProvider), `memoriesByMonthProvider` (grouped by "MMMM yyyy")
- `UploadNotifier` + sealed `UploadState` (idle/inProgress/success/error)
- `MemoryCard` widget: `CachedNetworkImage` thumbnail, caption gradient overlay
- `MemoryDetailScreen`: full-screen photo, editable caption, tag chips, delete with confirm dialog
- `CollageScreen` (full implementation):
  - `SliverMasonryGrid` grouped by month with count badge
  - Upload FAB → bottom sheet (camera / gallery) → compress → upload
  - Upload progress spinner replaces FAB during upload
  - Shimmer loading state (6 placeholder cards)
  - Empty state with icon + guidance text
- `flutter analyze`: zero issues

**Why:**
- Steps 1.3 and 1.4 — the core experience: photos in, masonry collage out

**What's next:**
- Step 1.5: Family invite system (QR code, roles, invite Cloud Function)

---

## 2026-05-17 — Step 1.2: Baby Profile Setup

**What:**
- Updated `AndroidManifest.xml`: camera, storage, notification permissions + UCropActivity
- Added flavor string resources (`app_name`) for dev and prod
- `Baby` model with Firestore serialization and `firstName` getter
- `BabyRepository`: `createBaby` (batch-writes family + baby docs + updates user), `watchBaby`, `updateBaby`, `uploadCoverPhoto` with image compression
- `babyRepositoryProvider`, `currentBabyProvider`, `newFamilyIdProvider` (Riverpod)
- `BabyAvatar` widget: `CircleAvatar` with `CachedNetworkImage` or initials fallback
- `BabySetupScreen`: 3-step `PageView` with animated step indicator
  - Step 1: Baby name text field
  - Step 2: Date-of-birth picker (calendar dialog)
  - Step 3: Cover photo picker (gallery) + skip option
  - On finish: creates family + baby in Firestore, updates user doc, navigates to `/home`
- `flutter analyze`: zero issues

**Why:**
- Step 1.2 — new users land here after first sign-in; no other screen is accessible until setup is complete

**What's next:**
- Step 1.3: Memory upload (image picker → EXIF extraction → Firebase Storage → Firestore)

---

## 2026-05-17 — Step 1.1: Firebase Init + Auth Feature

**What:**
- Placed `google-services.json` in `android/app/`
- Created `firebase_options.dart` from project credentials
- Updated `main.dart` to initialize Firebase before `runApp`
- Built `AppUser` model with `UserRole` enum and Firestore serialization
- Built `AuthRepository` with Google Sign-In, user upsert, sign-out, FCM token update
- Wired `authRepositoryProvider`, `authStateProvider`, `currentUserProvider` (Riverpod)
- Updated `AuthScreen` to call real Google Sign-In with loading state and error handling
- Updated router: redirects new users to `/baby/setup`, existing users to `/home`
- `flutter analyze`: zero issues

**Why:**
- Step 1.1 of build plan — authentication is the gate for all other features

**Blocked on (user action required):**
1. Firebase Console → Authentication → Sign-in method → Enable **Google**
2. Firebase Console → Project settings → Your apps → **Add fingerprint**: `AE:71:2D:BA:82:AF:0A:A2:61:6B:98:F4:D9:BF:9D:5E:E0:5D:FF:FD`
3. Download updated `google-services.json` and replace `android/app/google-services.json`
4. Firebase Console → Firestore Database → Create database (production mode)
5. Firebase Console → Storage → Get started

**What's next (after user actions above):**
- Step 1.2: Baby profile setup screen (name, DOB, cover photo, Firestore family creation)

---

## 2026-05-17 — Phase 0: Flutter Scaffold + Core + Router

**What:**
- Created Flutter project `little_steps` with dev/prod flavor configuration (`minSdk 24`, `compileSdk 36`)
- Set up complete feature-first folder structure under `lib/features/` (11 features)
- Installed all 196 dependencies via `flutter pub get`
- Downloaded Nunito and Lora fonts from Google Fonts
- Built full theme system: `AppColors`, `AppTextStyles`, `AppTheme.light()`
- Created constants: `AppConstants`, `AppStrings`
- Created extensions: `BuildContextExtensions`, `DateTimeExtensions`
- Created `AppLogger` utility
- Set up GoRouter with all routes and `ShellRoute` for bottom nav
- Built `AppShell` with 5-tab `NavigationBar` (Home, Timeline, Stories, Growth, Family)
- Wrote `main.dart` entry point with Hive init and `ProviderScope`
- Created `AuthScreen` UI (purple gradient, Google sign-in button placeholder)
- Created stub screens for all 6 feature tabs
- `flutter analyze` passes with zero issues

**Why:**
- Phase 0 goal: runnable skeleton before any Firebase or auth code

**What's next:**
- Firebase Console setup (user action required — create project, enable services)
- Step 0.3/0.4: Firebase CLI config, `flutterfire configure`, place `google-services.json`
- Step 1.1: Wire real Firebase Auth + Google Sign-In

---

## 2026-05-17 — Build Attempt #1 / Environment Check

**What:**
- Attempted to start Flutter project scaffold (Step 0.1)
- Discovered Flutter SDK, Android Studio, and Java are not installed on this machine
- Created `docs/dev_environment_setup.md` with step-by-step install guide

**Why:**
- Can't run `flutter create` or verify any code without the toolchain

**What's next:**
- User installs Flutter, Android Studio, Java, Firebase CLI, FlutterFire CLI
- Run `flutter doctor` to confirm zero critical errors
- Then start Step 0.1 of build plan

---

_Add new entries above this line, newest first._
