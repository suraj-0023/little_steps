# LittleSteps — Build Log

A running record of every session: what we did, why, and what's next.  
Most recent entry is always at the top.

---

## 2026-05-19 — Major Feature Batch: Navigation Overhaul, Baby Profiles, Letters, Export & Bug Fixes

### What
- Replaced bottom navigation bar with hamburger drawer containing all navigation (Home, Timeline, Stories, Growth, Letters, Export, Reel, Family, Settings)
- Added baby nickname support with family-wide display toggle (admin/editor only); `Baby.displayName` getter respects preference
- Made baby DOB optional; added unborn baby flow with Expected Delivery Date field in setup
- Fixed default DOB date picker showing February (was incorrectly subtracting 90 days)
- Multiple photo gallery upload in a single flow
- Text note and voice note sections in memory detail view (labeled separately with styled containers)
- Public/private toggle on Letters to Future with collapsible FAQ InfoCard explaining lock mechanics
- 4 PDF export templates: Soft Pastel, Bold Modern, Classic Scrapbook, Minimal Clean
- Photo Reel: animated text overlays (fade + slide effects) for baby name, caption, date, and tags with progress bar
- Fixed growth section "something went wrong" error by removing composite index requirement (client-side sort added)
- Fixed story generation failure: root cause was Timestamp range queries; changed to ISO string comparisons
- Firebase App Check: `AndroidProvider.debug` for dev, `AndroidProvider.playIntegrity` for prod
- Added Google Cloud Speech-to-Text dependency for voice note transcription in story generator

### Why
- Bottom nav was cluttered with too many features; hamburger drawer scales better and keeps all screens accessible
- Families wanted to use nickname as the primary display name for babies
- Support for expectant parents tracking before birth (not just from birth)
- Story generation was silently failing in production due to Firestore Timestamp vs ISO string type mismatch
- Growth chart was crashing due to missing composite index; client-side sorting eliminates that requirement
- Speech-to-Text enriches story context with transcribed voice note content

### Impact
- All major navigation now accessible from any screen via hamburger menu
- Stories now generate correctly with rich context (captions + transcribed voice notes)
- Growth chart works out-of-box without manual index creation
- App Check improves security posture for Firebase access
- Expectant parent flow enables app usage before baby is born

### Technical Detail
- `AppShell` uses `GlobalKey<ScaffoldState>` with static `openDrawer()` method for cross-screen drawer access
- `ShellRoute` expanded to include Letters, Export, Reel, Settings, Family so drawer is available on all screens
- `Baby.displayName` getter: returns `nickname` if `useNicknameDisplay && nickname != null`, else `firstName`
- `BabySetupScreen`: Step 1 adds nickname field; Step 2 has "Baby not born yet" toggle + EDD picker; DOB made nullable
- `story_generator.ts`: ISO string date range (`startStr`/`endStr`) replaces Timestamp.fromDate().toDate() queries; Speech-to-Text integration
- `GrowthRepository`: removed `.orderBy('date')`, client-side sort added via `...sort((a, b) => a.date.compareTo(b.date))`
- `PdfTemplate` enum with 4 coded styles dispatched in `buildMemoryPdf` switch statement
- `flutter analyze`: 0 errors, 0 warnings
- Files changed: 20+ feature screens, 2 models, 3 repositories, router, shell, drawer, Cloud Function, package.json

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
