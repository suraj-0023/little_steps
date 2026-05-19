# LittleSteps — Manual Steps

These steps require manual action. All coding is done — these are configuration, deployment, and store setup tasks.

---

## 1. flutter pub get — Run First

```bash
cd /Users/surajkunuku/Desktop/Little\ Footprints/little_steps
export PATH="$HOME/development/flutter/bin:$PATH"
flutter pub get
```

---

## 2. Enable Vertex AI API in Google Cloud Console

**Why**: Both Gemini 2.0 Flash (story text) and Imagen 3 (story illustration) are served through Google's Vertex AI. Cloud Functions authenticate automatically via the Firebase service account — no API key needed — but the API must be enabled once.

**Steps:**
1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Select your Firebase project from the top dropdown
3. Search for **"Vertex AI API"** → Click **Enable**
4. Search for **"Cloud Storage API"** → Click **Enable** (needed to store Imagen 3 illustrations)

That's it. No keys, no credentials — Firebase service account handles auth automatically.

**To verify after deploy:**
```bash
firebase functions:log --only generateMonthlyStory
```

---

## 3. Deploy Cloud Functions

**Why**: The story generator (Gemini text + Imagen 3 illustration) runs as a Cloud Function. Must be deployed before stories work.

```bash
# Install Firebase CLI (one time)
npm install -g firebase-tools

# Login
firebase login

# Install function dependencies
cd /Users/surajkunuku/Desktop/Little\ Footprints/little_steps/functions
npm install

# Deploy
cd /Users/surajkunuku/Desktop/Little\ Footprints
firebase deploy --only functions
```

---

## 4. Firebase Security Rules — Deploy Final Rules

**Why**: Proper member-based access control is in `firestore.rules`. Must be deployed to take effect.

```bash
# From project root
firebase deploy --only firestore:rules,storage
```

**If `firebase.json` doesn't exist**, create it at the project root:
```json
{
  "firestore": {
    "rules": "firestore.rules"
  },
  "storage": {
    "rules": "storage.rules"
  },
  "functions": {
    "source": "little_steps/functions"
  }
}
```

---

## 5. App Icons — Generate All Sizes

**Why**: The app currently uses the default Flutter icon.

1. Design a 1024×1024 PNG (baby footprint + purple gradient `#6C3FC5`) → save as `assets/images/app_icon.png`
2. Add to `pubspec.yaml` dev_dependencies:
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.0
```
3. Add config to `pubspec.yaml`:
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/app_icon.png"
  adaptive_icon_background: "#6C3FC5"
  adaptive_icon_foreground: "assets/images/app_icon_foreground.png"
```
4. Run:
```bash
dart run flutter_launcher_icons
```

---

## 6. Splash Screen

```bash
# Add to pubspec.yaml dev_dependencies: flutter_native_splash: ^2.4.0
# Add config:
# flutter_native_splash:
#   color: "#6C3FC5"
#   image: assets/images/app_icon.png
#   android_12:
#     image: assets/images/app_icon.png
#     color: "#6C3FC5"

dart run flutter_native_splash:create
```

---

## 7. Play Store — Account & App Listing

**Steps:**
1. **Create account**: [play.google.com/apps/publish](https://play.google.com/apps/publish) → Pay $25 one-time fee
2. **Generate keystore** (one time — back this file up permanently):
```bash
keytool -genkey -v -keystore ~/littlesteps-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias littlesteps
```
3. **Configure signing** in `android/app/build.gradle.kts`:
```kotlin
android {
    signingConfigs {
        create("release") {
            keyAlias = "littlesteps"
            keyPassword = "YOUR_KEY_PASSWORD"
            storeFile = file("${System.getProperty("user.home")}/littlesteps-release.jks")
            storePassword = "YOUR_STORE_PASSWORD"
        }
    }
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```
4. **Build App Bundle**:
```bash
cd /Users/surajkunuku/Desktop/Little\ Footprints/little_steps
export PATH="$HOME/development/flutter/bin:$PATH"
flutter build appbundle --flavor prod -t lib/main_prod.dart
# Output: build/app/outputs/bundle/prodRelease/app-prod-release.aab
```
5. Upload `.aab` in Play Console → Create app → Production → Upload
6. Fill store listing: title, short description, full description, ≥2 screenshots, 1024×500 feature graphic, privacy policy URL

---

## 8. Android Home Widget — Native Setup (Optional)

**Why**: Android home screen widgets require native XML and Kotlin files — cannot be auto-generated.

**Files to create** in `little_steps/android/app/src/main/`:

### `res/xml/little_steps_widget_info.xml`
```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="180dp"
    android:minHeight="110dp"
    android:updatePeriodMillis="1800000"
    android:initialLayout="@layout/little_steps_widget"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen" />
```

### `res/layout/little_steps_widget.xml`
```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@drawable/widget_background"
    android:orientation="vertical"
    android:padding="12dp">
    <TextView
        android:id="@+id/baby_name"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:textSize="14sp"
        android:textStyle="bold" />
    <TextView
        android:id="@+id/latest_date"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:textSize="12sp" />
</LinearLayout>
```

### Add to `AndroidManifest.xml` inside `<application>`:
```xml
<receiver
    android:name="com.littlesteps.little_steps.LittleStepsWidget"
    android:label="LittleSteps"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/little_steps_widget_info" />
</receiver>
```

### `kotlin/com/littlesteps/little_steps/LittleStepsWidget.kt`
```kotlin
package com.littlesteps.little_steps

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import es.antonborri.home_widget.HomeWidgetPlugin

class LittleStepsWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            HomeWidgetPlugin.getData(context)
        }
    }
}
```

---

## Priority Order

| # | Step | Blocking? |
|---|---|---|
| 1 | `flutter pub get` | Yes — app won't compile |
| 2 | Enable Vertex AI API in GCP Console | Yes — story generation fails |
| 3 | Deploy Cloud Functions | Yes — stories won't generate |
| 4 | Deploy Firestore/Storage rules | Yes — security not enforced |
| 5 | App icon | Before Play Store |
| 6 | Splash screen | Before Play Store |
| 7 | Play Store + keystore + app bundle | To publish publicly |
| 8 | Android home widget native code | Optional — can add post-launch |
