# LittleSteps — Master Build Plan

**Last Updated:** 2026-05-17
**Current Status:** Phase 0 complete — scaffold, theme, router done. Next: Step 1.1 Auth (needs Firebase setup first)
**Single source of truth** for all Claude Code sessions. Tick checkboxes as each task completes.
**How to use:** On session start, read this file, find the first unticked checkbox, and continue from there.

> **Before Step 0.1:** Complete all steps in [`docs/dev_environment_setup.md`](dev_environment_setup.md) first. `flutter doctor` must pass with zero critical errors.

---

## Table of Contents

1. [Global Setup](#0-global-setup)
2. [Phase 1 — Foundation (Weeks 1–6)](#phase-1--foundation-weeks-16)
3. [Phase 2 — AI & Intelligence (Weeks 7–12)](#phase-2--ai--intelligence-weeks-712)
4. [Phase 3 — Stories & Export (Weeks 13–18)](#phase-3--stories--export-weeks-1318)
5. [Phase 4 — Polish & Scale (Weeks 19–24)](#phase-4--polish--scale-weeks-1924)
6. [Firebase Security Rules Reference](#firebase-security-rules-reference)
7. [Cloud Functions Reference](#cloud-functions-reference)
8. [pubspec.yaml Reference](#pubspecyaml-reference)

---

## 0 — Global Setup

### 0.1 Flutter Project Scaffold

- [x] Run `flutter create --org com.littlesteps --platforms android little_steps` in parent directory
- [x] Delete default `lib/main.dart` counter app content
- [x] Create entry point files:
  - `lib/main.dart` — calls `runApp` with flavor detection via `const String.fromEnvironment('FLAVOR', defaultValue: 'prod')`
  - `lib/main_dev.dart` — sets `FLAVOR=dev`, calls shared `bootstrap(AppFlavor.dev)`
  - `lib/main_prod.dart` — sets `FLAVOR=prod`, calls shared `bootstrap(AppFlavor.prod)`
  - `lib/bootstrap.dart` — initializes Hive, Firebase, then runs `MyApp`
  - `lib/app.dart` — returns `ProviderScope` wrapping `MaterialApp.router` with `AppTheme.light()` and `AppRouter.router`
- [x] Create Android flavor product flavors in `android/app/build.gradle.kts`:
  - `dev` flavor: `applicationIdSuffix ".dev"`, `versionNameSuffix "-dev"`
  - `prod` flavor: no suffix
- [x] Set `minSdk 24` in `android/app/build.gradle.kts`
- [x] Set `compileSdk 36`, `targetSdk 36`
- [ ] Add `google-services.json` for both flavors under `android/app/src/dev/` and `android/app/src/prod/` (after Firebase setup)

### 0.2 pubspec.yaml — Full Dependency List

- [x] Paste the following into `pubspec.yaml` and run `flutter pub get`:

```yaml
name: little_steps
description: Baby memory app — LittleSteps
publish_to: none
version: 1.0.0+1

environment:
  sdk: ">=3.3.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.3
  firebase_storage: ^12.3.2
  firebase_messaging: ^15.1.3
  firebase_analytics: ^11.3.3
  firebase_crashlytics: ^4.1.3
  cloud_functions: ^5.1.3

  # State management & navigation
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  go_router: ^14.2.7

  # Google sign-in
  google_sign_in: ^6.2.1

  # ML Kit
  google_mlkit_image_labeling: ^0.13.0
  google_mlkit_face_detection: ^0.11.0

  # Image
  image_picker: ^1.1.2
  cached_network_image: ^3.3.1
  flutter_image_compress: ^2.2.0
  photo_manager: ^3.3.0

  # Local cache
  hive_flutter: ^1.1.0
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1

  # Video
  ffmpeg_kit_flutter_full_gpl: ^6.0.3

  # PDF
  pdf: ^3.10.8
  printing: ^5.12.0

  # Charts
  fl_chart: ^0.68.0

  # Encryption (Letters feature)
  encrypt: ^5.0.3
  pointycastle: ^3.7.4

  # Utilities
  intl: ^0.19.0
  path_provider: ^2.1.3
  permission_handler: ^11.3.1
  share_plus: ^9.0.0
  url_launcher: ^6.3.0
  uuid: ^4.4.2
  equatable: ^2.0.5
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  logger: ^2.3.0
  connectivity_plus: ^6.0.3
  geolocator: ^12.0.0
  geocoding: ^3.0.0
  local_notifications: ^17.2.2   # flutter_local_notifications

  # UI extras
  flutter_staggered_grid_view: ^0.7.0
  lottie: ^3.1.2
  shimmer: ^3.0.0
  qr_flutter: ^4.1.0
  mobile_scanner: ^5.2.3
  image_cropper: ^8.0.2
  flutter_colorpicker: ^1.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.11
  riverpod_generator: ^2.4.3
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  isar_generator: ^3.1.0+1
  mockito: ^5.4.4

flutter:
  uses-material-design: true
  fonts:
    - family: Nunito
      fonts:
        - asset: assets/fonts/Nunito-Regular.ttf
        - asset: assets/fonts/Nunito-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Nunito-Bold.ttf
          weight: 700
    - family: Lora
      fonts:
        - asset: assets/fonts/Lora-Regular.ttf
        - asset: assets/fonts/Lora-Italic.ttf
          style: italic
  assets:
    - assets/images/
    - assets/animations/
    - assets/fonts/
```

- [x] Download Nunito and Lora font files from Google Fonts into `assets/fonts/`
- [x] Create placeholder asset directories: `assets/images/`, `assets/animations/`

### 0.3 Firebase Console Setup

- [ ] Create Firebase project named `little-steps-prod`
- [ ] Add Android app with package name `com.littlesteps.little_steps`
- [ ] Add Android app for dev flavor with package name `com.littlesteps.little_steps.dev`
- [ ] Enable **Authentication** → Sign-in providers: Google
- [ ] Enable **Firestore Database** → Start in production mode (rules added in step 0.5)
- [ ] Enable **Firebase Storage** → Start in production mode
- [ ] Enable **Cloud Functions** → Node.js 20 runtime
- [ ] Enable **Firebase Cloud Messaging** (FCM) — no additional config needed
- [ ] Enable **Firebase Analytics** — accept default settings
- [ ] Enable **Crashlytics** — follow Android setup wizard
- [ ] Download `google-services.json` for each app and place in correct flavor directories
- [ ] Run `flutterfire configure` and select the prod project → generates `lib/firebase_options.dart`
- [ ] Run `flutterfire configure --out lib/firebase_options_dev.dart` for dev project

### 0.4 Firebase CLI Commands

```bash
# Install Firebase CLI globally (once)
npm install -g firebase-tools

# Install FlutterFire CLI (once)
dart pub global activate flutterfire_cli

# Login
firebase login

# Initialize project (run from repo root)
firebase init
# Select: Firestore, Storage, Functions (TypeScript), Emulators
# Emulators to enable: Auth, Functions, Firestore, Storage

# Set Claude API key in functions config
firebase functions:config:set anthropic.key="YOUR_ANTHROPIC_API_KEY"

# Start emulators for local dev
firebase emulators:start --only auth,firestore,storage,functions
```

- [ ] Run all commands above; confirm emulator UI is accessible at `localhost:4000`

### 0.5 Cloud Functions Project Init

- [ ] `cd functions && npm install`
- [ ] Verify `functions/package.json` has TypeScript, `firebase-admin`, `firebase-functions`, `@anthropic-ai/sdk`, `node-fetch` as dependencies:

```json
{
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^6.0.0",
    "@anthropic-ai/sdk": "^0.27.0",
    "node-fetch": "^3.3.2"
  },
  "devDependencies": {
    "typescript": "^5.4.0",
    "@types/node": "^20.0.0"
  }
}
```

- [ ] Confirm `functions/tsconfig.json` targets `ES2020`, `module: commonjs`
- [ ] Create stub exports in `functions/src/index.ts` (each function imported and re-exported — stubs until Phase 2)

### 0.6 Core — Theme System

- [x] Create `lib/core/theme/app_colors.dart` — defines `AppColors` class with static const fields:
  - `primary = Color(0xFF6C3FC5)`
  - `secondary = Color(0xFFF5A623)`
  - `surface = Color(0xFFFDFBFF)`
  - `card = Color(0xFFFFFFFF)`
  - `textPrimary = Color(0xFF1A1A2E)`
  - `textSecondary = Color(0xFF6B6B8A)`
  - `error = Color(0xFFB00020)`
  - `success = Color(0xFF4CAF50)`
- [x] Create `lib/core/theme/app_text_styles.dart` — defines `AppTextStyles` with `TextStyle` getters using Nunito for body/UI and Lora for story/letter text
- [x] Create `lib/core/theme/app_theme.dart` — `AppTheme.light()` returns `ThemeData` with:
  - `colorScheme` built from `AppColors` via `ColorScheme.fromSeed`
  - `fontFamily: 'Nunito'`
  - `cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))`
  - `inputDecorationTheme` with rounded borders, filled background
  - `elevatedButtonTheme` with primary color and 12dp radius
- [x] Create `lib/core/constants/app_strings.dart` — all UI strings as static const
- [x] Create `lib/core/constants/app_constants.dart` — `kBaseUnit = 8.0`, `kCardRadius = 16.0`, `kMaxImageSizeMb = 10`, `kThumbnailSize = 400`
- [ ] Create `lib/core/extensions/context_extensions.dart` — `context.theme`, `context.colorScheme`, `context.textTheme`, `context.screenWidth`, `context.screenHeight`
- [ ] Create `lib/core/extensions/datetime_extensions.dart` — `toFormattedString()`, `isToday`, `monthYear` getters
- [ ] Create `lib/core/utils/logger.dart` — wraps the `logger` package, exports `AppLogger` singleton with `d/i/w/e` methods

**Verification:** Run `flutter analyze` — zero issues. Run app in dev flavor, confirm purple `MaterialApp` background with no errors.

### 0.7 Core — Router Setup

- [ ] Create `lib/core/router/app_router.dart`:
  - Top-level `final routerProvider = Provider<GoRouter>((ref) => ...)`
  - Routes: `/` → redirect to `/auth` or `/home` based on auth state
  - `/auth` → `AuthScreen`
  - `/home` → `CollageScreen` (shell route with bottom nav)
  - `/home/timeline` → `TimelineScreen`
  - `/home/stories` → `StoriesScreen`
  - `/home/growth` → `GrowthScreen`
  - `/memory/:memoryId` → `MemoryDetailScreen`
  - `/baby/setup` → `BabySetupScreen`
  - `/baby/profile` → `BabyProfileScreen`
  - `/family` → `FamilyScreen`
  - `/family/invite` → `InviteScreen`
  - `/settings` → `SettingsScreen`
  - `/letters` → `LettersScreen`
  - `/letters/new` → `NewLetterScreen`
  - `/export` → `ExportScreen`
- [ ] Wire `routerProvider` into `app.dart`'s `MaterialApp.router`

**Verification:** Hot reload with no navigation errors; `flutter analyze` still passes.

---

## Phase 1 — Foundation (Weeks 1–6)

### Step 1.1 — Auth Feature

**Files to create:**
- `lib/features/auth/models/app_user.dart`
- `lib/features/auth/repositories/auth_repository.dart`
- `lib/features/auth/providers/auth_providers.dart`
- `lib/features/auth/screens/auth_screen.dart`

**What to implement:**

- [ ] `AppUser` — Freezed model with fields: `uid`, `displayName`, `email`, `photoUrl`, `familyId`, `role` (enum: admin/editor/contributor/viewer), `babyId`, `fcmToken`. Add `toFirestore()` and `fromFirestore()` factory.
- [ ] `AuthRepository` — class with injected `FirebaseAuth`, `GoogleSignIn`, `FirebaseFirestore`:
  - `Stream<AppUser?> authStateChanges()` — maps `FirebaseAuth.instance.authStateChanges()` to `AppUser?` by reading `users/{uid}` document
  - `Future<AppUser> signInWithGoogle()` — calls `GoogleSignIn().signIn()`, then `signInWithCredential`, then upserts `users/{uid}` doc
  - `Future<void> signOut()` — calls both `FirebaseAuth.signOut()` and `GoogleSignIn.signOut()`
  - `Future<void> updateFcmToken(String uid, String token)` — updates `users/{uid}.fcmToken`
- [ ] `authRepositoryProvider` — `Provider<AuthRepository>` returning singleton
- [ ] `authStateProvider` — `StreamProvider<AppUser?>` using `ref.watch(authRepositoryProvider).authStateChanges()`
- [ ] `AuthScreen`:
  - Purple gradient background (`primary` → slightly darker)
  - Lottie animation (`assets/animations/baby_logo.json`) at top center
  - App name in Nunito Bold 32sp
  - Tagline in Nunito Regular 16sp textSecondary color
  - "Sign in with Google" `ElevatedButton` with Google logo SVG
  - On tap: calls `ref.read(authRepositoryProvider).signInWithGoogle()`, on success navigates to `/baby/setup` (new user) or `/home` (existing user)
  - Error snackbar via `ScaffoldMessenger`

**Key packages:** `firebase_auth`, `google_sign_in`, `cloud_firestore`, `flutter_riverpod`, `freezed_annotation`, `lottie`

**Verification:**
- [ ] Sign in with a real Google account on Android emulator
- [ ] Confirm `users/{uid}` document appears in Firestore emulator with correct fields
- [ ] Sign out and confirm `authStateProvider` emits null
- [ ] `flutter analyze` passes with zero issues

---

### Step 1.2 — Baby Feature (Profile Setup)

**Files to create:**
- `lib/features/baby/models/baby.dart`
- `lib/features/baby/repositories/baby_repository.dart`
- `lib/features/baby/providers/baby_providers.dart`
- `lib/features/baby/notifiers/baby_notifier.dart`
- `lib/features/baby/screens/baby_setup_screen.dart`
- `lib/features/baby/screens/baby_profile_screen.dart`
- `lib/features/baby/widgets/baby_avatar.dart`

**What to implement:**

- [ ] `Baby` — Freezed model: `id`, `name`, `dob` (DateTime), `coverPhotoUrl` (nullable), `createdAt`, `familyId`
- [ ] `BabyRepository`:
  - `Future<Baby> createBaby({required String familyId, required String name, required DateTime dob, File? coverPhoto})` — writes to `families/{familyId}/babies/{babyId}`, uploads cover photo if provided
  - `Future<Baby?> getBaby(String familyId, String babyId)` — reads document
  - `Stream<Baby?> watchBaby(String familyId, String babyId)` — snapshot stream
  - `Future<void> updateBaby(Baby baby)` — partial update via `set(..., merge: true)`
  - `Future<String> uploadCoverPhoto(String familyId, String babyId, File photo)` — uploads to `babies/{babyId}/cover.jpg`, returns download URL
- [ ] `babyRepositoryProvider` — `Provider<BabyRepository>`
- [ ] `currentBabyProvider` — `StreamProvider<Baby?>` that watches the baby from `users/{uid}.babyId`
- [ ] `BabyNotifier extends AsyncNotifier<Baby?>`:
  - `build()` → returns `ref.watch(currentBabyProvider)`
  - `updateName(String name)`, `updateDob(DateTime dob)`, `updateCoverPhoto(File photo)`
- [ ] `BabySetupScreen`:
  - Step 1: Baby name text field (Nunito, validated non-empty)
  - Step 2: DOB picker using `showDatePicker`
  - Step 3: Cover photo picker (image_picker, cropped to square via image_cropper)
  - "Create memory book" button — calls `BabyRepository.createBaby`, then also creates `families/{familyId}` document, updates `users/{uid}.familyId` and `users/{uid}.babyId`, navigates to `/home`
- [ ] `BabyProfileScreen`: Editable version of setup, shows age in months/years, edit buttons per field
- [ ] `BabyAvatar` widget: `CircleAvatar` with `CachedNetworkImage` and fallback initials

**Key packages:** `image_picker`, `image_cropper`, `cached_network_image`, `firebase_storage`, `freezed_annotation`

**Verification:**
- [ ] Complete baby setup flow end-to-end on emulator
- [ ] Confirm `families/{familyId}` and `families/{familyId}/babies/{babyId}` documents created in Firestore
- [ ] Cover photo uploaded to Storage and URL stored in Firestore
- [ ] After setup, router redirects to `/home` not back to `/baby/setup`

---

### Step 1.3 — Memory Feature (Upload + EXIF)

**Files to create:**
- `lib/features/memory/models/memory.dart`
- `lib/features/memory/models/exif_data.dart`
- `lib/features/memory/repositories/memory_repository.dart`
- `lib/features/memory/providers/memory_providers.dart`
- `lib/features/memory/notifiers/upload_notifier.dart`
- `lib/features/memory/screens/memory_detail_screen.dart`
- `lib/features/memory/widgets/memory_card.dart` (or in `lib/shared/`)
- `lib/core/utils/exif_extractor.dart`

**What to implement:**

- [ ] `ExifData` — Freezed model: `latitude` (nullable double), `longitude` (nullable double), `takenAt` (nullable DateTime), `cameraMake`, `cameraModel`, `orientation`
- [ ] `Memory` — Freezed model: `id`, `familyId`, `photoUrl`, `thumbnailUrl`, `takenAt`, `uploadedBy` (uid), `tags` (List<String>), `location` (nullable String), `caption` (nullable), `exif` (ExifData?), `createdAt`
- [ ] `ExifExtractor` utility class:
  - `Future<ExifData> extract(File imageFile)` — uses `exif` package (or manual byte parsing) to extract GPS, date, camera info
- [ ] `MemoryRepository`:
  - `Future<Memory> uploadMemory({required String familyId, required File photo, required String uploadedBy, String? caption})`:
    1. Compress image via `flutter_image_compress` to max 1920px, 85% quality
    2. Generate thumbnail at 400px
    3. Upload both to `memories/{memoryId}/original.jpg` and `memories/{memoryId}/thumb.jpg`
    4. Extract EXIF
    5. Write Firestore doc to `families/{familyId}/memories/{memoryId}`
    6. Returns `Memory`
  - `Stream<List<Memory>> watchMemories(String familyId)` — ordered by `takenAt desc`, limit 200 initially
  - `Future<Memory?> getMemory(String familyId, String memoryId)`
  - `Future<void> updateCaption(String familyId, String memoryId, String caption)`
  - `Future<void> deleteMemory(String familyId, String memoryId)` — deletes Storage files + Firestore doc
  - `Future<void> addTags(String familyId, String memoryId, List<String> tags)` — `arrayUnion`
- [ ] `UploadState` — sealed class: `idle`, `uploading(double progress)`, `success(Memory memory)`, `error(String message)`
- [ ] `UploadNotifier extends StateNotifier<UploadState>`:
  - `uploadPhoto(File photo, String caption)` — streams progress updates
  - Handles offline queue: if no connectivity, stores locally in Hive and syncs when reconnected
- [ ] `memoriesProvider` — `StreamProvider<List<Memory>>` using `MemoryRepository.watchMemories`
- [ ] `MemoryDetailScreen`:
  - Full-screen hero photo with `CachedNetworkImage`
  - Caption field (editable, saves on focus lost)
  - Tag chips row
  - EXIF info card (camera, date, location)
  - Delete button (admin/editor only)
- [ ] `MemoryCard` widget (shared): `Card` with `CachedNetworkImage(thumbnailUrl)`, caption overlay, tag chips at bottom

**Key packages:** `flutter_image_compress`, `photo_manager`, `cached_network_image`, `hive_flutter`, `connectivity_plus`

**Verification:**
- [ ] Pick photo from gallery, upload completes with progress indicator
- [ ] Memory appears in Firestore with correct EXIF fields populated
- [ ] Thumbnail and original both appear in Storage
- [ ] Offline scenario: disable network, pick photo — verify it queues; re-enable network — verify it uploads

---

### Step 1.4 — Collage Screen (Home)

**Files to create:**
- `lib/features/collage/screens/collage_screen.dart`
- `lib/features/collage/widgets/month_section_header.dart`
- `lib/features/collage/widgets/fab_upload_button.dart`
- `lib/features/collage/providers/collage_providers.dart`

**What to implement:**

- [ ] `memoriesByMonthProvider` — `Provider<Map<String, List<Memory>>>` derived from `memoriesProvider`:
  - Groups `Memory` list by `"MMMM yyyy"` formatted key
  - Returns `LinkedHashMap` so month order is preserved (newest first)
- [ ] `CollageScreen`:
  - `Scaffold` with `AppBar` showing baby name + avatar (`BabyAvatar`) on the right
  - Body: `CustomScrollView` with `SliverList` of month groups
  - Each month group: `MonthSectionHeader` followed by `SliverMasonryGrid.count(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8)` using `flutter_staggered_grid_view`
  - Grid items: `MemoryCard` widgets, tap navigates to `/memory/:memoryId`
  - Empty state: centered Lottie animation + "Add your first memory" text
  - `Shimmer` loading state while `memoriesProvider` is loading
  - FAB: `FloatingActionButton.extended` with camera icon, navigates to upload flow
- [ ] `MonthSectionHeader`: Month label in Nunito SemiBold 18sp, photo count badge
- [ ] `FabUploadButton`: Custom FAB that opens a bottom sheet with "Take Photo" / "Choose from Gallery" options, then calls `UploadNotifier.uploadPhoto`
- [ ] Bottom navigation bar (persistent shell): Home, Timeline, Stories, Growth — using `NavigationBar` widget

**Key packages:** `flutter_staggered_grid_view`, `shimmer`, `lottie`, `go_router`

**Verification:**
- [ ] Grid renders correctly with 3+ uploaded photos
- [ ] Photos grouped by correct months
- [ ] Tapping a memory card navigates to detail screen and back
- [ ] Shimmer visible during initial load
- [ ] Empty state visible when no memories exist

---

### Step 1.5 — Family Feature (Invite System)

**Files to create:**
- `lib/features/family/models/family.dart`
- `lib/features/family/models/family_member.dart`
- `lib/features/family/repositories/family_repository.dart`
- `lib/features/family/providers/family_providers.dart`
- `lib/features/family/notifiers/invite_notifier.dart`
- `lib/features/family/screens/family_screen.dart`
- `lib/features/family/screens/invite_screen.dart`
- `lib/features/family/widgets/member_tile.dart`
- `functions/src/invite-handler.ts`

**What to implement:**

- [ ] `Family` — Freezed model: `id`, `name`, `createdAt`, `members` (List<String> uids), `adminUid`
- [ ] `FamilyMember` — Freezed model: `uid`, `displayName`, `photoUrl`, `email`, `role`
- [ ] `FamilyRepository`:
  - `Future<Family?> getFamily(String familyId)`
  - `Stream<Family> watchFamily(String familyId)`
  - `Future<List<FamilyMember>> getMembers(String familyId)` — reads `users` docs for each uid in `members[]`
  - `Future<String> generateInviteLink(String familyId, String role)` — calls Cloud Function `invite-handler` via `cloud_functions`, returns dynamic link
  - `Future<void> updateMemberRole(String familyId, String uid, String role)` — writes to `users/{uid}.role`
  - `Future<void> removeMember(String familyId, String uid)` — `arrayRemove` from `families/{familyId}.members`
- [ ] `familyProvider` — `StreamProvider<Family?>` watching current family
- [ ] `familyMembersProvider` — `FutureProvider<List<FamilyMember>>`
- [ ] `InviteNotifier`:
  - `generateQrCode(String familyId, String role)` — stores result in state
  - `processInviteLink(String token)` — calls Cloud Function to validate token and add user to family
- [ ] `FamilyScreen`:
  - Member list with `MemberTile` (avatar, name, role badge, remove button for admin)
  - "Invite Family Member" button at bottom
  - Role change dropdown (admin only)
- [ ] `InviteScreen`:
  - Role selector (Contributor / Viewer)
  - QR code display using `qr_flutter`
  - "Copy Link" button
  - "Scan QR" button opens `mobile_scanner`
- [ ] `MemberTile`: `ListTile` with `CircleAvatar`, name, role `Chip`, optional remove `IconButton`
- [ ] `invite-handler.ts` Cloud Function (HTTPS callable):
  - `generateInvite(familyId, role)` — creates a signed JWT token with 48h expiry, stores in Firestore `invites/{token}`, returns link
  - `acceptInvite(token, uid)` — validates token, adds uid to `families/{familyId}.members`, sets `users/{uid}.familyId` and `users/{uid}.role`

**Key packages:** `qr_flutter`, `mobile_scanner`, `cloud_functions`

**Verification:**
- [ ] Admin can generate invite QR code
- [ ] Scanning QR code with second device adds that user to the family
- [ ] New member sees shared collage
- [ ] Admin can change roles and remove members
- [ ] Invite link expires after 48 hours (test with a manually expired token)

---

### Step 1.6 — FCM Push Notifications (Setup)

**Files to create:**
- `lib/core/services/fcm_service.dart`
- `lib/core/services/notification_service.dart`

**What to implement:**

- [ ] `FcmService`:
  - `Future<void> initialize()` — requests permission, gets token, calls `AuthRepository.updateFcmToken`
  - `void setupForegroundHandler()` — `FirebaseMessaging.onMessage.listen(...)` → shows local notification via `flutter_local_notifications`
  - `void setupBackgroundHandler()` — `FirebaseMessaging.onBackgroundMessage` top-level handler
  - `void handleNotificationTap(RemoteMessage message)` — parses `data.type` and routes accordingly (e.g. `on_this_day` → opens memory)
- [ ] `NotificationService`:
  - `Future<void> initialize()` — initializes `FlutterLocalNotificationsPlugin` with Android channel `littlesteps_default` (importance: high)
  - `Future<void> showNotification({required String title, required String body, String? payload})` — shows local notification
  - `Future<void> showImageNotification({required String title, required String body, required String imageUrl})` — BigPicture style notification
- [ ] Call `FcmService.initialize()` in `bootstrap.dart` after Firebase init
- [ ] Add FCM token refresh listener that re-saves token to Firestore

**Key packages:** `firebase_messaging`, `flutter_local_notifications`

**Verification:**
- [ ] On first app launch, permission dialog appears
- [ ] FCM token saved to `users/{uid}.fcmToken` in Firestore
- [ ] Send test FCM message from Firebase Console → notification appears
- [ ] Tapping notification opens correct screen

---

## Phase 2 — AI & Intelligence (Weeks 7–12)

### Step 2.1 — ML Kit Image Tagging

**Files to create:**
- `lib/core/services/ml_kit_service.dart`
- `lib/features/memory/notifiers/tagging_notifier.dart`

**What to implement:**

- [ ] `MlKitService`:
  - `Future<List<String>> labelImage(File imageFile)` — uses `ImageLabeler` from `google_mlkit_image_labeling`:
    - `ImageLabelerOptions(confidenceThreshold: 0.75)`
    - Maps raw labels to normalized app tag vocabulary (e.g. "Person" → "family", "Food" → "meal", "Outdoor" → "outdoors")
    - Returns list of up to 5 normalized tag strings
  - `Future<List<Face>> detectFaces(File imageFile)` — uses `FaceDetector`, returns face count for "family_moment" tag
  - Private `_normalizeLabel(String rawLabel)` — maps ML Kit labels to app vocabulary
- [ ] `TaggingNotifier extends StateNotifier<AsyncValue<List<String>>>`:
  - `tagImage(File photo)` — calls `MlKitService.labelImage`, updates `memory.tags` via `MemoryRepository.addTags`
  - Triggered automatically after each upload in `UploadNotifier`
- [ ] Update `UploadNotifier.uploadPhoto` to call `TaggingNotifier.tagImage` after upload succeeds
- [ ] `TagFilterBar` widget in `lib/features/collage/widgets/tag_filter_bar.dart`:
  - Horizontal `ListView` of `FilterChip` widgets, one per unique tag in `memoriesProvider`
  - Selected chips filter `memoriesByMonthProvider`
- [ ] `activeTagFiltersProvider` — `StateProvider<Set<String>>` tracking selected filter tags
- [ ] Update `memoriesByMonthProvider` to respect `activeTagFiltersProvider`

**Key packages:** `google_mlkit_image_labeling`, `google_mlkit_face_detection`

**Verification:**
- [ ] Upload a photo with people → tags include "family" or "portrait"
- [ ] Upload an outdoor photo → tags include "outdoors"
- [ ] Tag filter bar appears; selecting "meal" shows only meal photos
- [ ] Tagging runs entirely on-device (no network call during tag process)

---

### Step 2.2 — Reverse Geocoding

**Files to create:**
- `lib/core/services/geocoding_service.dart`

**What to implement:**

- [ ] `GeocodingService`:
  - `Future<String?> getLocationName(double lat, double lng)` — calls `placemarkFromCoordinates` from `geocoding` package, returns formatted string like "Mumbai, Maharashtra"
  - `Future<ExifData> enrichWithLocation(ExifData exif)` — if exif has lat/lng, calls `getLocationName` and returns updated ExifData with `location` field
- [ ] Update `MemoryRepository.uploadMemory` to call `GeocodingService.enrichWithLocation` and store location string in Firestore

**Key packages:** `geocoding`, `geolocator`

**Verification:**
- [ ] Upload photo taken with location data → `memory.location` field populated in Firestore
- [ ] Location string shown in `MemoryDetailScreen`
- [ ] Photos without GPS data show no location (graceful null handling)

---

### Step 2.3 — Cloud Functions: Story Generator

**Files to create:**
- `functions/src/story-generator.ts`
- `functions/src/types.ts` (shared types)

**What to implement:**

- [ ] `types.ts` — TypeScript interfaces: `Memory`, `Baby`, `StoryRequest`, `StoryResponse`
- [ ] `story-generator.ts` — HTTPS Callable function `generateMonthlyStory(familyId, babyId, month, year)`:
  1. Validates caller is authenticated and is a member of `familyId`
  2. Reads `families/{familyId}/babies/{babyId}` to get baby name and DOB
  3. Reads all `memories` for the given month/year filtered by `takenAt`
  4. Aggregates tags (top 10 most frequent), location names, memory count
  5. Calculates baby's age in months at that point
  6. Calls Claude Haiku API (`claude-haiku-4-5`) via `@anthropic-ai/sdk`:
     ```
     System: "You are a warm, loving narrator writing baby memory book entries.
              Write in 2nd person ('Your little one...'). Keep under 300 words.
              Use a nurturing, heartfelt tone. Never mention AI."
     User: "Baby: {name}, Age: {months} months.
            This month had {count} memories.
            Activities/tags: {tags}.
            Places visited: {locations}.
            Write a warm narrative of this month."
     ```
  7. Writes result to `families/{familyId}/stories/{storyId}` with fields: `month`, `year`, `body`, `generatedAt`, `memoryIds[]`
  8. Returns `{ storyId, body }`
- [ ] Add `ANTHROPIC_API_KEY` from `functions.config().anthropic.key`
- [ ] Export function from `functions/src/index.ts`

**Key packages (functions):** `@anthropic-ai/sdk`, `firebase-admin`, `firebase-functions`

**Verification:**
- [ ] Call function from Flutter client using `FirebaseFunctions.instance.httpsCallable('generateMonthlyStory')`
- [ ] Story document appears in Firestore with `body` field containing warm narrative
- [ ] Function rejects calls from non-family members (security test)
- [ ] Function handles months with zero memories gracefully (returns default message)

---

### Step 2.4 — Stories Feature (UI)

**Files to create:**
- `lib/features/stories/models/story.dart`
- `lib/features/stories/repositories/story_repository.dart`
- `lib/features/stories/providers/story_providers.dart`
- `lib/features/stories/notifiers/story_notifier.dart`
- `lib/features/stories/screens/stories_screen.dart`
- `lib/features/stories/screens/story_viewer_screen.dart`
- `lib/features/stories/widgets/story_card.dart`
- `lib/features/stories/widgets/month_picker_bar.dart`

**What to implement:**

- [ ] `Story` — Freezed model: `id`, `familyId`, `month`, `year`, `body`, `generatedAt`, `memoryIds`
- [ ] `StoryRepository`:
  - `Stream<List<Story>> watchStories(String familyId)` — ordered by `year desc`, `month desc`
  - `Future<Story?> getStory(String familyId, String storyId)`
  - `Future<Story> generateStory(String familyId, String babyId, int month, int year)` — calls `generateMonthlyStory` Cloud Function, then returns local Story object
- [ ] `storiesProvider` — `StreamProvider<List<Story>>`
- [ ] `StoryNotifier`:
  - `generateForMonth(int month, int year)` — calls `StoryRepository.generateStory`, updates state
  - State: `AsyncValue<Story?>` for the generation in progress
- [ ] `StoriesScreen`:
  - `MonthPickerBar` — horizontal scroll of month labels; tapping selects that month
  - If story exists for selected month: shows `StoryCard`
  - If no story: shows "Generate Story" button with Lottie sparkle animation
  - Story generation shows `CircularProgressIndicator` and takes 5–15s
- [ ] `StoryViewerScreen`:
  - Full-screen white card with Lora Italic font for story body
  - Header with month/year and baby name
  - Horizontal photo strip of linked memories at bottom
  - Share button (copies text to clipboard)
- [ ] `StoryCard`: Card with month label, first 2 lines of body text preview, "Read full story" button

**Key packages:** `cloud_functions`, `flutter_riverpod`

**Verification:**
- [ ] Select a month with photos, tap "Generate Story", story appears within 15s
- [ ] Story text renders in Lora Italic font
- [ ] Linked memory photos shown at bottom of story viewer
- [ ] Already-generated stories load from Firestore without re-calling the function

---

### Step 2.5 — Timeline Feature

**Files to create:**
- `lib/features/timeline/models/event.dart`
- `lib/features/timeline/repositories/event_repository.dart`
- `lib/features/timeline/providers/timeline_providers.dart`
- `lib/features/timeline/screens/timeline_screen.dart`
- `lib/features/timeline/widgets/timeline_tile.dart`
- `lib/features/timeline/widgets/milestone_overlay.dart`

**What to implement:**

- [ ] `AppEvent` — Freezed model: `id`, `familyId`, `type` (enum: milestone/memory/growth/letter), `title`, `date`, `note` (nullable), `linkedMemoryId` (nullable), `isAiSuggested`
- [ ] `EventRepository`:
  - `Stream<List<AppEvent>> watchEvents(String familyId)` — ordered by `date desc`
  - `Future<void> addEvent(String familyId, AppEvent event)`
  - `Future<void> markMilestone(String familyId, String title, DateTime date, String? linkedMemoryId)` — creates event with `type: milestone`
  - `Future<List<AppEvent>> getAiSuggestedMilestones(String familyId, String babyId)` — calls `suggestMilestones` Cloud Function
- [ ] `timelineEventsProvider` — `StreamProvider<List<AppEvent>>`
- [ ] `TimelineScreen`:
  - `CustomScrollView` with pinned `SliverAppBar` ("Timeline")
  - `SliverList` of `TimelineTile` widgets, grouped by year
  - Year section headers with count badge
  - FAB to add custom event
- [ ] `TimelineTile`:
  - Left: colored dot (milestone = purple, memory = blue, growth = green)
  - Right: title, date, optional linked memory thumbnail
  - Tap: navigates to detail (memory detail or event detail sheet)
- [ ] Standard milestone checklist (hardcoded list in `AppConstants`):
  - First smile, first laugh, rolled over, sat up, first tooth, first word, first steps, first birthday, solid foods, pincer grasp

**Key packages:** `flutter_riverpod`, `go_router`

**Verification:**
- [ ] Timeline shows all memories and events in correct chronological order
- [ ] Adding a milestone via FAB saves to Firestore and appears immediately
- [ ] Milestone overlay correctly highlights completed vs incomplete milestones

---

### Step 2.6 — AI Milestone Suggestions (Cloud Function)

**Files to create:**
- `functions/src/milestone-suggester.ts`

**What to implement:**

- [ ] `milestone-suggester.ts` — HTTPS Callable `suggestMilestones(familyId, babyId)`:
  1. Reads baby's DOB, calculates current age in weeks
  2. Reads last 30 memories' tags
  3. Reads already-completed milestones from events
  4. Calls Claude Haiku:
     ```
     System: "You are a pediatric development expert. Suggest 3 milestones
              a baby might reach based on their age and recent activities.
              Return JSON array: [{title, description, likelihood}]"
     User: "Baby age: {weeks} weeks. Recent activities: {tags}.
            Already achieved: {completedMilestones}.
            Suggest 3 upcoming milestones."
     ```
  5. Parses JSON response, writes suggestions to `families/{familyId}/events` with `isAiSuggested: true`
  6. Returns suggestions array
- [ ] Update `EventRepository.getAiSuggestedMilestones` to call this function
- [ ] `MilestoneOverlay` widget in `timeline_screen.dart`: shows AI suggestions as dismissable cards with "Mark as Done" button

**Verification:**
- [ ] AI suggestions appear for a baby 3–6 months old
- [ ] "Mark as Done" converts suggestion to confirmed milestone
- [ ] Suggestions are age-appropriate (test with DOB set to 3 months ago)

---

### Step 2.7 — Image Editor

**Files to create:**
- `lib/features/memory/screens/image_editor_screen.dart`
- `lib/features/memory/notifiers/image_editor_notifier.dart`
- `lib/core/services/opencv_service.dart`

**What to implement:**

- [ ] `OpenCvService` (FFI bridge — placeholder in Phase 1, full impl here):
  - `Future<File> autoEnhance(File input)` — calls native OpenCV via `ffi` for auto brightness/contrast correction
  - `Future<File> applyFilter(File input, ImageFilter filter)` — applies warm/cool/bw/vintage filters
  - If OpenCV FFI is not yet bridged, use `flutter_image_compress` as a fallback enhancement
- [ ] `ImageEditorNotifier`:
  - State: `ImageEditorState {originalFile, editedFile, brightness, contrast, selectedFilter, annotations}`
  - `setBrightness(double value)`, `setContrast(double value)`, `applyFilter(ImageFilter)`, `addTextAnnotation(String text, Offset position)`, `addEmoji(String emoji, Offset position)`, `undo()`, `save()`
- [ ] `ImageEditorScreen`:
  - Preview pane (80% of height)
  - Bottom tab bar: Enhance / Filters / Annotate / Crop
  - Enhance tab: `Slider` for brightness, contrast
  - Filters tab: horizontal scroll of filter previews
  - Annotate tab: text input + emoji picker
  - Crop tab: delegates to `image_cropper`
  - "Save" button replaces memory's `photoUrl` in Storage and Firestore

**Key packages:** `image_cropper`, `flutter_colorpicker`, `flutter_image_compress`

**Verification:**
- [ ] Open editor from memory detail screen
- [ ] Apply warm filter and save — confirm photo URL updated in Firestore
- [ ] Add text annotation and save — annotation baked into final JPEG

---

### Step 2.8 — On This Day (Cloud Function + FCM)

**Files to create:**
- `functions/src/on-this-day.ts`

**What to implement:**

- [ ] `on-this-day.ts` — Pub/Sub scheduled function (runs daily at 08:00 IST = 02:30 UTC):
  1. For each family, reads all memories where `takenAt` month+day equals today's month+day (prior years only)
  2. For each memory found, reads the family's admin user's `fcmToken`
  3. Sends FCM notification via `firebase-admin` messaging:
     - Title: "On This Day 🌟"
     - Body: "A year ago: {caption or first tag}"
     - Data: `{ type: 'on_this_day', memoryId, familyId }`
     - Includes `imageUrl` of thumbnail for BigPicture notification
  4. Logs sends to `families/{familyId}/notifications/{notifId}`
- [ ] Update `FcmService.handleNotificationTap` to handle `type: 'on_this_day'` → navigates to `MemoryDetailScreen`
- [ ] Schedule function: `functions.pubsub.schedule('30 2 * * *').timeZone('UTC').onRun(...)`

**Verification:**
- [ ] Manually trigger function from Firebase Console with test data
- [ ] Notification received on device with correct photo thumbnail
- [ ] Tapping notification opens correct memory detail screen

---

## Phase 3 — Stories & Export (Weeks 13–18)

### Step 3.1 — Growth Journal Feature

**Files to create:**
- `lib/features/growth/models/growth_log.dart`
- `lib/features/growth/repositories/growth_repository.dart`
- `lib/features/growth/providers/growth_providers.dart`
- `lib/features/growth/notifiers/growth_notifier.dart`
- `lib/features/growth/screens/growth_screen.dart`
- `lib/features/growth/widgets/growth_chart.dart`
- `lib/features/growth/widgets/add_log_sheet.dart`
- `lib/features/growth/data/who_percentiles.dart`

**What to implement:**

- [ ] `GrowthLog` — Freezed model: `id`, `babyId`, `familyId`, `date`, `heightCm` (nullable), `weightKg` (nullable), `headCircumferenceCm` (nullable)
- [ ] `WhoPercentiles` — data class containing WHO growth standard percentile tables (3rd, 15th, 50th, 85th, 97th) for weight-for-age and height-for-age, stored as `Map<int, Map<String, double>>` keyed by age in months
- [ ] `GrowthRepository`:
  - `Stream<List<GrowthLog>> watchGrowthLogs(String familyId, String babyId)` — ordered by `date`
  - `Future<void> addLog(GrowthLog log)`
  - `Future<void> updateLog(GrowthLog log)`
  - `Future<void> deleteLog(String familyId, String logId)`
- [ ] `growthLogsProvider` — `StreamProvider<List<GrowthLog>>`
- [ ] `GrowthNotifier`:
  - `addLog(DateTime date, double? height, double? weight, double? headCirc)`
  - Calculates percentile for each measurement using `WhoPercentiles`
- [ ] `GrowthScreen`:
  - Top: Tab bar (Weight / Height / Head)
  - `GrowthChart` showing growth curve + WHO percentile bands
  - Below chart: List of log entries with edit/delete
  - FAB: "Add Measurement" → `AddLogSheet`
- [ ] `GrowthChart` widget:
  - Uses `fl_chart` `LineChart`
  - Baby's actual data points: solid purple line with dot markers
  - WHO 3rd, 50th, 97th percentile: dashed grey lines
  - X-axis: age in months, Y-axis: measurement value
  - Tooltips on tap showing date and exact value
- [ ] `AddLogSheet`: `BottomSheet` with date picker, height/weight/head text fields, save button

**Key packages:** `fl_chart`, `flutter_riverpod`

**Verification:**
- [ ] Add 3 weight measurements → chart shows a line with correct values
- [ ] WHO percentile bands visible as dashed lines
- [ ] Tap a data point → tooltip shows correct date and value
- [ ] Edit and delete logs work correctly

---

### Step 3.2 — Letters to the Future Feature

**Files to create:**
- `lib/features/letters/models/letter.dart`
- `lib/features/letters/repositories/letter_repository.dart`
- `lib/features/letters/providers/letter_providers.dart`
- `lib/features/letters/notifiers/letter_notifier.dart`
- `lib/features/letters/screens/letters_screen.dart`
- `lib/features/letters/screens/new_letter_screen.dart`
- `lib/features/letters/screens/letter_viewer_screen.dart`
- `lib/features/letters/widgets/letter_card.dart`
- `lib/core/services/encryption_service.dart`

**What to implement:**

- [ ] `EncryptionService`:
  - `String encrypt(String plaintext, String key)` — AES-256 CBC via `encrypt` package; key derived from `uid + familyId` via PBKDF2
  - `String decrypt(String ciphertext, String key)` — reverse operation
  - `String deriveKey(String uid, String familyId)` — deterministic key derivation
- [ ] `Letter` — Freezed model: `id`, `familyId`, `title`, `encryptedBody`, `unlockDate`, `authorUid`, `createdAt`, `isUnlocked` (computed: `DateTime.now().isAfter(unlockDate)`)
- [ ] `LetterRepository`:
  - `Stream<List<Letter>> watchLetters(String familyId)` — ordered by `unlockDate`
  - `Future<void> createLetter({required String familyId, required String title, required String body, required DateTime unlockDate, required String authorUid})` — encrypts body before storing
  - `Future<String> decryptBody(Letter letter, String uid)` — decrypts using `EncryptionService`
  - Firestore security rules enforce `unlockDate <= request.time` for read access to body
- [ ] `lettersProvider` — `StreamProvider<List<Letter>>`
- [ ] `LetterNotifier`:
  - `createLetter(String title, String body, DateTime unlockDate)`
  - `openLetter(Letter letter)` — decrypts and returns body
- [ ] `LettersScreen`:
  - Two sections: "Sealed" (future unlock dates) and "Unlocked"
  - Sealed letters shown as locked card with countdown "Opens in X days"
  - Unlocked letters shown as readable cards
- [ ] `NewLetterScreen`:
  - Title field
  - Rich text body field (Lora font, multiline)
  - Unlock date picker (date only, minimum tomorrow)
  - Preview of how the letter will appear
  - "Seal Letter" button with wax seal Lottie animation
- [ ] `LetterViewerScreen`:
  - Full-screen Lora Italic rendering of decrypted body
  - Envelope open Lottie animation on first open
  - Share as image option (renders letter as PNG)
- [ ] `LetterCard`: Card showing title, to/from info, unlock date countdown; locked icon for sealed letters

**Key packages:** `encrypt`, `pointycastle`, `lottie`

**Verification:**
- [ ] Create a letter with tomorrow's unlock date — appears as sealed
- [ ] Manually set `unlockDate` to yesterday in Firestore — letter becomes readable
- [ ] Decrypt body matches original plaintext
- [ ] Non-family member cannot read letter body (security rule test)

---

### Step 3.3 — PDF Export Feature

**Files to create:**
- `lib/features/export/repositories/export_repository.dart`
- `lib/features/export/notifiers/pdf_export_notifier.dart`
- `lib/features/export/screens/export_screen.dart`
- `lib/features/export/widgets/export_preview.dart`
- `lib/core/utils/pdf_builder.dart`
- `functions/src/monthly-digest.ts`

**What to implement:**

- [ ] `PdfBuilder` utility class:
  - `Future<File> buildMemoryCollage({required List<Memory> memories, required Baby baby, required String month})` — builds PDF using `pdf` package:
    - Page 1: Cover with baby name, month, cover photo
    - Subsequent pages: 4 memories per page in 2x2 grid with captions and tags
    - Footer: app branding + page number
    - Embed Lora font for captions
  - `Future<File> buildGrowthReport(List<GrowthLog> logs, Baby baby)` — growth chart page as vector graphics via `pdf` package's `PdfGraphics`
  - `Future<File> buildStoryBook(List<Story> stories, Baby baby)` — one story per page with Lora text
- [ ] `ExportRepository`:
  - `Future<File> exportMonthlyPdf(String familyId, int month, int year)`
  - `Future<File> exportFullAlbum(String familyId)` — all months combined
  - `Future<void> shareFile(File file)` — uses `share_plus`
  - `Future<void> saveToDownloads(File file)` — uses `path_provider` + file copy
- [ ] `PdfExportNotifier`:
  - State: `ExportState { idle | generating(double progress) | done(File file) | error(String) }`
  - `exportMonth(int month, int year)`
  - `exportFullAlbum()`
- [ ] `ExportScreen`:
  - Options: Monthly PDF / Full Album PDF / Growth Report / Story Book
  - Each option: icon, label, estimated size, generate button
  - Progress indicator during generation
  - After generation: preview card + "Share" and "Save to Downloads" buttons
- [ ] `ExportPreview`: `SizedBox` showing first page of generated PDF via `printing` package's `PdfPreview` widget
- [ ] `monthly-digest.ts` Cloud Function — Pub/Sub scheduled (1st of each month at 09:00 IST):
  - Calls `generateMonthlyStory` for each family
  - Sends FCM notification: "Your {month} story is ready"
  - Does NOT generate PDF server-side (PDF is client-generated)

**Key packages:** `pdf`, `printing`, `share_plus`, `path_provider`

**Verification:**
- [ ] Generate monthly PDF — file opens in system viewer with correct photos
- [ ] Photo captions correctly attributed
- [ ] PDF file size is under 20MB for 20 photos
- [ ] Share button opens Android share sheet

---

### Step 3.4 — Video Reel Feature (FFmpegKit)

**Files to create:**
- `lib/features/export/notifiers/video_reel_notifier.dart`
- `lib/core/utils/ffmpeg_builder.dart`

**What to implement:**

- [ ] `FfmpegBuilder` utility class:
  - `Future<File> buildVideoReel({required List<File> photos, required String babyName, required String month, String? bgMusicPath, VideoReelQuality quality = VideoReelQuality.hd})`:
    1. Download all thumbnails to temp directory (or use already-cached files)
    2. Build FFmpeg command:
       - Scale each image to 1280x720 (HD) or 1920x1080 (Full HD)
       - Each photo displayed for 3 seconds with Ken Burns effect (zoom + pan via `zoompan` filter)
       - `xfade` transitions between photos (fade, wipeleft, random)
       - If `bgMusicPath` provided: mix audio at 30% volume, fade out last 2s
       - Overlay: baby name + month text in bottom-left (drawtext filter)
       - Output: H.264 MP4, AAC audio, 30fps
    3. Runs via `FFmpegKit.executeAsync` with progress callback
    4. Returns output `File`
  - `Future<void> cancelRender()` — calls `FFmpegKit.cancel()`
- [ ] `VideoReelNotifier`:
  - State: `VideoReelState { idle | rendering(double progress, int currentFrame, int totalFrames) | done(File file) | error(String) }`
  - `renderReel(List<Memory> memories, {String? bgMusicPath})`
  - `cancelRender()`
- [ ] Add to `ExportScreen`: "Video Reel" option showing estimated render time
- [ ] Render progress: custom circular progress with frame counter
- [ ] After render: preview plays inline via `video_player`, share/save buttons

**Key packages:** `ffmpeg_kit_flutter_full_gpl`, `video_player`

**Verification:**
- [ ] Render a 5-photo reel — MP4 produced in temp directory
- [ ] Ken Burns effect visible on each photo
- [ ] Cross-fade transitions visible between photos
- [ ] Text overlay shows baby name and month
- [ ] Video plays correctly in Android gallery after saving

---

### Step 3.5 — Voice Notes Feature

**Files to create:**
- `lib/features/memory/models/voice_note.dart`
- `lib/features/memory/repositories/voice_note_repository.dart`
- `lib/features/memory/notifiers/voice_note_notifier.dart`
- `lib/features/memory/widgets/voice_note_player.dart`

**What to implement:**

- [ ] `VoiceNote` — Freezed model: `id`, `familyId`, `memoryId` (nullable — can be standalone), `audioUrl`, `durationSeconds`, `authorUid`, `createdAt`, `transcription` (nullable)
- [ ] `VoiceNoteRepository`:
  - `Future<VoiceNote> recordAndUpload(String familyId, {String? memoryId})` — records via `record` package, uploads to Storage `voice_notes/{noteId}.m4a`
  - `Future<void> deleteVoiceNote(String familyId, String noteId)`
  - `Stream<List<VoiceNote>> watchMemoryVoiceNotes(String familyId, String memoryId)`
- [ ] `VoiceNoteNotifier`:
  - `startRecording()`, `stopRecording()`, `playNote(String audioUrl)`, `deleteNote(VoiceNote note)`
  - State: `VoiceNoteState { idle | recording(Duration elapsed) | playing(String noteId, Duration position) | uploading | error }`
- [ ] `VoiceNotePlayer` widget:
  - Waveform visualization (simplified: bars with animation)
  - Play/pause button
  - Duration label
  - Record new note button
  - Attach to memory option

**Key packages:** `record`, `just_audio` or `audioplayers`

**Verification:**
- [ ] Record a 10-second voice note — uploads to Storage
- [ ] Play voice note back from `MemoryDetailScreen`
- [ ] Voice note persists after app restart

---

### Step 3.6 — Local Cache (Hive/Isar)

**Files to create:**
- `lib/core/cache/hive_cache_service.dart`
- `lib/core/cache/isar_cache_service.dart`
- `lib/core/cache/cache_schema.dart`

**What to implement:**

- [ ] `CacheSchema` — defines all Hive box names: `memories`, `babies`, `families`, `stories`, `events`; defines all Isar collection classes for `CachedMemory`, `CachedBaby`, `CachedEvent`
- [ ] `HiveCacheService`:
  - `Future<void> init()` — opens all Hive boxes in `bootstrap.dart`
  - `Future<void> cacheMemories(List<Memory> memories)` — stores serialized JSON
  - `List<Memory>? getCachedMemories(String familyId)` — returns from box or null
  - `Future<void> clearCache()` — removes all boxes
- [ ] `IsarCacheService`:
  - Full CRUD for `CachedMemory` collection
  - `Stream<List<CachedMemory>> watchCachedMemories(String familyId)` — Isar reactive query
- [ ] Update `MemoryRepository` to:
  1. On `watchMemories`: immediately emit cached data, then overlay Firestore stream
  2. On `uploadMemory`: write to Isar cache immediately for instant UI update
  3. On connectivity lost: serve from cache exclusively
- [ ] `connectivityProvider` — `StreamProvider<ConnectivityResult>` using `connectivity_plus`
- [ ] Update providers to show offline banner when connectivity is none

**Verification:**
- [ ] Disable device network → collage screen still shows previously loaded photos
- [ ] Upload photo offline → photo appears in UI immediately (from local cache), uploads when online
- [ ] Re-enable network → Firestore sync completes silently

---

## Phase 4 — Polish & Scale (Weeks 19–24)

### Step 4.1 — Onboarding Flow

**Files to create:**
- `lib/features/auth/screens/onboarding_screen.dart`
- `lib/features/auth/widgets/onboarding_page.dart`
- `lib/core/services/onboarding_service.dart`

**What to implement:**

- [ ] `OnboardingService`:
  - `bool hasCompletedOnboarding()` — reads from Hive `settings` box
  - `Future<void> markCompleted()` — writes to Hive
- [ ] `OnboardingScreen`:
  - `PageView` with 4 pages: Capture / Remember / Share / AI Stories
  - Each page: full-bleed Lottie animation, 2-line headline, 1-line subtext
  - Dot indicators at bottom
  - "Skip" text button top-right
  - "Next" / "Get Started" button
  - Page 4 "Get Started" → `AuthScreen`
- [ ] Update router: if `!OnboardingService.hasCompletedOnboarding()`, redirect `/` to `/onboarding`

**Verification:**
- [ ] Fresh install shows onboarding on first launch
- [ ] Second launch skips onboarding directly to auth/home
- [ ] Skip button works on any page

---

### Step 4.2 — Multi-Baby Support

**Files to create:**
- `lib/features/baby/screens/baby_switcher_screen.dart`
- `lib/features/baby/widgets/baby_switcher_bottom_sheet.dart`
- `lib/features/baby/providers/active_baby_provider.dart`

**What to implement:**

- [ ] `activeBabyIdProvider` — `StateProvider<String?>` storing currently selected baby's ID (persisted in Hive)
- [ ] Update `currentBabyProvider` to use `activeBabyIdProvider` instead of `users/{uid}.babyId`
- [ ] `familyBabiesProvider` — `StreamProvider<List<Baby>>` watching all `families/{familyId}/babies/`
- [ ] `BabySwitcherBottomSheet`:
  - List of all babies with avatars
  - "Add New Baby" option at bottom
  - Tap selects and updates `activeBabyIdProvider`
- [ ] Update `CollageScreen`'s `AppBar` baby avatar to tap and open `BabySwitcherBottomSheet`
- [ ] All providers that use family data: scope by `activeBabyId` where appropriate (memories, events, growth logs)

**Verification:**
- [ ] Add two babies to the same family
- [ ] Switch between babies — collage shows correct memories per baby
- [ ] Growth chart shows correct data per active baby

---

### Step 4.3 — Android Home Screen Widget

**Files to create:**
- `android/app/src/main/kotlin/com/littlesteps/little_steps/MemoryWidgetProvider.kt`
- `android/app/src/main/res/layout/memory_widget.xml`
- `android/app/src/main/res/xml/memory_widget_info.xml`
- `lib/core/services/widget_service.dart`

**What to implement:**

- [ ] Android `AppWidgetProvider` subclass `MemoryWidgetProvider`:
  - 4x2 widget showing latest memory photo
  - Update via `AlarmManager` every 24 hours
  - Tap opens app to `MemoryDetailScreen` for that memory
  - Uses `RemoteViews` with `ImageView` loaded via Glide
- [ ] `WidgetService` in Flutter:
  - `Future<void> updateWidgetData()` — writes latest memory URL + caption to SharedPreferences for native side to read
  - Called after each upload and on app foreground
- [ ] Register widget in `android/app/src/main/AndroidManifest.xml`
- [ ] Add `home_widget` Flutter package to `pubspec.yaml` for Flutter↔native bridge

**Key packages:** `home_widget`

**Verification:**
- [ ] Add widget to home screen from widget picker
- [ ] Widget shows most recent photo
- [ ] Widget updates within 24 hours after new upload
- [ ] Tapping widget opens correct memory in app

---

### Step 4.4 — Performance Audit

**Files to check/optimize:**
- `lib/features/collage/screens/collage_screen.dart`
- `lib/features/memory/repositories/memory_repository.dart`

**What to implement:**

- [ ] Run Flutter DevTools → Performance tab; target 60fps on collage scroll
- [ ] Implement `AutomaticKeepAliveClientMixin` on memory card widgets to prevent unnecessary rebuilds
- [ ] Replace `StreamProvider<List<Memory>>` with paginated `watchMemories(limit: 50, startAfter: lastDoc)` — implement infinite scroll
- [ ] Add `const` constructors everywhere possible
- [ ] Profile Firestore reads: add composite index on `takenAt` + `familyId`
- [ ] Image loading: verify `CachedNetworkImage`'s `memCacheWidth`/`memCacheHeight` matches grid tile size
- [ ] Run `flutter build apk --analyze-size` — target under 30MB
- [ ] Enable Crashlytics custom events for critical user journeys: `upload_success`, `story_generated`, `export_pdf_complete`

**Verification:**
- [ ] Scroll through 100+ photos at 60fps on mid-range emulator (Pixel 4 equivalent)
- [ ] App startup time under 3 seconds on first launch (after splash)
- [ ] APK size under 30MB (excluding deferred components)

---

### Step 4.5 — Accessibility

**Files to review:**
- All screens in `lib/features/*/screens/`
- `lib/shared/` widgets

**What to implement:**

- [ ] Add `Semantics` wrapper to all interactive elements with `label` and `hint`
- [ ] Add `excludeSemantics: true` to decorative images
- [ ] Verify minimum touch target size: 48x48dp for all tappable elements
- [ ] Verify color contrast ratio: text on background must be ≥ 4.5:1 (WCAG AA)
- [ ] Run accessibility scanner in Android Studio: fix all "low contrast" and "missing label" findings
- [ ] Add `textScaleFactor` bounds: clamp at 1.0–1.3 for grid layout
- [ ] Verify TalkBack navigation order makes sense on all screens
- [ ] Test with system font size set to "Largest"

**Verification:**
- [ ] TalkBack can navigate entire collage → memory detail → back flow
- [ ] No "missing content description" warnings in Android Accessibility Scanner
- [ ] App is usable with font size at 1.3x

---

### Step 4.6 — Firebase Security Rules (Final)

**File:** `firestore.rules`

- [ ] Deploy final Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isSignedIn() {
      return request.auth != null;
    }

    function isFamilyMember(familyId) {
      return isSignedIn() &&
        request.auth.uid in get(/databases/$(database)/documents/families/$(familyId)).data.members;
    }

    function hasRole(familyId, role) {
      return isSignedIn() &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == role;
    }

    function canWrite(familyId) {
      return isFamilyMember(familyId) &&
        (hasRole(familyId, 'admin') || hasRole(familyId, 'editor') || hasRole(familyId, 'contributor'));
    }

    match /users/{userId} {
      allow read: if isSignedIn() && request.auth.uid == userId;
      allow write: if isSignedIn() && request.auth.uid == userId;
    }

    match /families/{familyId} {
      allow read: if isFamilyMember(familyId);
      allow create: if isSignedIn();
      allow update: if hasRole(familyId, 'admin');

      match /babies/{babyId} {
        allow read: if isFamilyMember(familyId);
        allow write: if canWrite(familyId);
      }

      match /memories/{memoryId} {
        allow read: if isFamilyMember(familyId);
        allow create: if canWrite(familyId);
        allow update: if canWrite(familyId);
        allow delete: if hasRole(familyId, 'admin') || hasRole(familyId, 'editor');
      }

      match /events/{eventId} {
        allow read: if isFamilyMember(familyId);
        allow write: if canWrite(familyId);
      }

      match /growthLogs/{logId} {
        allow read: if isFamilyMember(familyId);
        allow write: if canWrite(familyId);
      }

      match /letters/{letterId} {
        allow read: if isFamilyMember(familyId) &&
          resource.data.unlockDate <= request.time;
        allow create: if canWrite(familyId);
        allow delete: if request.auth.uid == resource.data.authorUid;
      }

      match /stories/{storyId} {
        allow read: if isFamilyMember(familyId);
        allow write: if false; // Cloud Functions only
      }
    }
  }
}
```

- [ ] Deploy rules: `firebase deploy --only firestore:rules`
- [ ] Run Firestore emulator rules tests before deploying to production

---

### Step 4.7 — Analytics & Crashlytics Integration

**Files to update:**
- `lib/bootstrap.dart`
- `lib/features/*/screens/*.dart` (key screens only)

**What to implement:**

- [ ] `AnalyticsService` in `lib/core/services/analytics_service.dart`:
  - Wraps `FirebaseAnalytics.instance`
  - `logUpload(int photoCount)` → `logEvent('photo_uploaded', {'count': photoCount})`
  - `logStoryGenerated(int month, int year)` → `logEvent('story_generated', ...)`
  - `logExport(String type)` → `logEvent('export_completed', {'type': type})`
  - `logMilestoneMarked(String milestoneName)` → `logEvent('milestone_marked', ...)`
  - `setUserProperties(AppUser user)` → sets `familyId`, `role`, `has_baby`
- [ ] `CrashlyticsService` in `lib/core/services/crashlytics_service.dart`:
  - `Future<void> init()` — `FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError`
  - `recordError(dynamic e, StackTrace? st)` — `FirebaseCrashlytics.instance.recordError`
  - Set `userId` on sign-in
- [ ] Wrap entire app in `PlatformDispatcher.instance.onError` for uncaught async errors
- [ ] Add `GoRouterObserver` that logs screen views to Analytics

**Verification:**
- [ ] Upload photo → `photo_uploaded` event appears in Firebase Analytics DebugView
- [ ] Force a crash via `FirebaseCrashlytics.instance.crash()` → crash report visible in Crashlytics console within 5 minutes

---

### Step 4.8 — Play Store Submission Checklist

- [ ] Generate signed AAB: `flutter build appbundle --flavor prod -t lib/main_prod.dart`
- [ ] Create signing keystore: `keytool -genkey -v -keystore key.jks -alias key -keyalg RSA -keysize 2048 -validity 10000`
- [ ] Configure signing in `android/app/build.gradle` release config
- [ ] Create `key.properties` file (gitignored) with keystore credentials
- [ ] Prepare store listing assets:
  - [ ] App icon 512x512 PNG (no alpha)
  - [ ] Feature graphic 1024x500 JPG
  - [ ] 8 screenshots (phone portrait): Home, Memory detail, Timeline, Stories, Growth, Letters, Export, Family
  - [ ] Short description (80 chars): "Capture, share & cherish every baby milestone with AI-powered stories"
  - [ ] Full description (4000 chars max): see `docs/store_listing.md`
  - [ ] Privacy policy URL (required for camera/storage permissions)
  - [ ] Content rating questionnaire
- [ ] Complete Data Safety form in Play Console
- [ ] Test on Android 7.0+ (API 24) and Android 14 (API 34) physical devices
- [ ] Submit for review to internal testing track first

---

## Firebase Security Rules Reference

See full rules in Step 4.6 above. Summary:
- Users can only read/write their own `users/{uid}` document
- All family data scoped to members of that family
- Letters only readable after `unlockDate`
- Stories writable only by Cloud Functions (not client)
- Viewers can read but not write memories/events

---

## Cloud Functions Reference

| Function | File | Trigger | What it does |
|---|---|---|---|
| `generateMonthlyStory` | `story-generator.ts` | HTTPS Callable | Reads memories, calls Claude Haiku, writes story doc |
| `suggestMilestones` | `milestone-suggester.ts` | HTTPS Callable | Reads age + tags, calls Claude Haiku, writes suggested events |
| `onThisDay` | `on-this-day.ts` | Pub/Sub (daily 02:30 UTC) | Finds same-day memories, sends FCM notifications |
| `monthlyDigest` | `monthly-digest.ts` | Pub/Sub (1st of month, 03:30 UTC) | Triggers story generation, sends "story ready" FCM |
| `resizeImage` | `resize-image.ts` | Storage trigger (finalize) | On upload to `memories/*/original.jpg`, creates thumbnail at 400px |
| `generateInvite` | `invite-handler.ts` | HTTPS Callable | Creates signed invite token, stores in Firestore |
| `acceptInvite` | `invite-handler.ts` | HTTPS Callable | Validates token, adds user to family |

All functions: Node.js 20, region `asia-south1` (Mumbai) for lowest latency to India.

---

## pubspec.yaml Reference

See complete file in Step 0.2. Key version pins:

| Package | Version |
|---|---|
| `flutter_riverpod` | ^2.5.1 |
| `go_router` | ^14.2.7 |
| `firebase_core` | ^3.6.0 |
| `cloud_firestore` | ^5.4.3 |
| `firebase_storage` | ^12.3.2 |
| `firebase_messaging` | ^15.1.3 |
| `ffmpeg_kit_flutter_full_gpl` | ^6.0.3 |
| `google_mlkit_image_labeling` | ^0.13.0 |
| `fl_chart` | ^0.68.0 |
| `pdf` | ^3.10.8 |
| `encrypt` | ^5.0.3 |
| `flutter_staggered_grid_view` | ^0.7.0 |

---

## Session Resume Instructions

When starting a new Claude Code session:
1. Read `docs/build_plan.md` (this file)
2. Find the **first unchecked `[ ]` checkbox**
3. Read only the feature folder relevant to that step (see CLAUDE.md navigation table)
4. Implement that step, tick all sub-task checkboxes as each completes
5. Before ending session: update `docs/evolution.md` with what was done and why
6. Push via the CLAUDE.md GitHub process
