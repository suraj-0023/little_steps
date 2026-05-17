# LittleSteps — Build Log

A running record of every session: what we did, why, and what's next.  
Most recent entry is always at the top.

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
