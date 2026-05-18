# Dev Environment Setup — LittleSteps

Complete this checklist **before** starting Step 0.1 of the build plan.  
All tools are free. Estimated time: ~45–60 minutes (most of it is download time).

---

## Status

- [ ] Java (JDK 17)
- [ ] Android Studio
- [ ] Android SDK + Emulator
- [ ] Flutter SDK
- [ ] Flutter PATH configured
- [ ] `flutter doctor` passes with zero critical errors
- [ ] Firebase CLI
- [ ] FlutterFire CLI
- [ ] Node.js already installed ✅ (v25.9.0 detected)
- [ ] npm already installed ✅ (v11.12.1 detected)

---

## Step 1 — Install Java (JDK 17)

Flutter and Android Studio require Java. Install via Homebrew (easiest on Mac):

```bash
# Install Homebrew if not present
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install OpenJDK 17
brew install openjdk@17

# Add to PATH (add this line to ~/.zshrc)
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"

# Reload shell
source ~/.zshrc

# Verify
java -version   # should show: openjdk version "17.x.x"
```

---

## Step 2 — Install Android Studio

1. Download from: https://developer.android.com/studio
2. Open the `.dmg`, drag Android Studio to Applications
3. Launch Android Studio → complete the Setup Wizard (installs Android SDK automatically)
4. In the Setup Wizard, choose:
   - **Standard** installation
   - Accept all SDK license agreements
   - Let it download Android SDK, build tools, and a system image

---

## Step 3 — Install Flutter SDK

**Option A — Direct download (recommended):**

1. Go to: https://docs.flutter.dev/get-started/install/macos/android
2. Download Flutter SDK (stable channel)
3. Extract to `~/development/flutter`
4. Add to PATH in `~/.zshrc`:

```bash
export PATH="$HOME/development/flutter/bin:$PATH"
```

5. Reload shell:
```bash
source ~/.zshrc
```

**Option B — Homebrew:**
```bash
brew install --cask flutter
```

---

## Step 4 — Configure Android Emulator

1. Open Android Studio → **Device Manager** (top-right icon or Tools menu)
2. Click **Create Virtual Device**
3. Choose **Pixel 8** (or similar)
4. Select system image: **API 35 (Android 15)** — download if needed
5. Click Finish → the emulator should appear in Device Manager
6. Press the Play ▶ button to launch it once and confirm it boots

---

## Step 5 — Run Flutter Doctor

```bash
flutter doctor
```

Expected output (all green ✅):
```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Android toolchain - develop for Android devices
[✓] Android Studio (version x.x)
[✓] Connected device (1 available)
[!] Chrome - Not required for Android-only project
```

If `flutter doctor` shows issues, fix each one before continuing.  
Common fix: `flutter doctor --android-licenses` to accept all SDK licenses.

---

## Step 6 — Install Firebase CLI

```bash
npm install -g firebase-tools

# Login
firebase login

# Verify
firebase --version
```

---

## Step 7 — Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli

# Add dart pub global to PATH if not already (add to ~/.zshrc):
export PATH="$PATH:$HOME/.pub-cache/bin"

source ~/.zshrc

# Verify
flutterfire --version
```

---

## Final Verification Checklist

Run all of these and confirm they return version numbers:

```bash
java -version
flutter --version
flutter doctor          # zero critical errors
firebase --version
flutterfire --version
node --version          # already ✅
npm --version           # already ✅
```

Once all pass → open the build plan (`docs/build_plan.md`) and start **Step 0.1**.

---

## Notes

- Flutter SDK location: `~/development/flutter` (or wherever you extracted it)
- Android SDK location: `~/Library/Android/sdk` (set automatically by Android Studio)
- Firebase project will be created during Step 0.3 of the build plan
- `ANTHROPIC_API_KEY` will be added to Firebase Functions config during Phase 2 setup
