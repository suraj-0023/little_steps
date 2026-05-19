# LittleSteps — Claude Code Instructions

## GitHub Push Process

**Every time the user says "push to GitHub" or "push the updates", delegate ALL steps below to a Haiku 4.5 subagent using the Agent tool with `model: "haiku"`.**

Spawn the agent with a self-contained prompt that includes:
- A summary of all changes made in this session (files changed, what and why)
- Today's date
- The repo details and credential instructions below
- The full task list (Steps 0–3)

The Haiku agent handles everything: updating docs, committing, pushing, and managing GitHub issues.

---

### Step 0 — Update Documentation

Before committing, update these two files:

1. **`docs/evolution.md`** — Prepend a new entry at the top (reverse-chronological) with today's date covering:
   - **What**: Technical and UI/UX changes made
   - **Why**: The problem solved or user request
   - **Impact**: Functional or aesthetic outcome
   - **Technical Detail**: Key files, widgets, providers, or functions changed

2. **`docs/project_summary.md`** — Update any sections now outdated due to the changes (feature list, architecture, phase status, "Last Updated" date).

Include both files in the same commit as the code changes.

### Step 1 — Commit & Push

```bash
git pull --rebase origin main    # always sync before committing
git add <changed files>          # stage specific files, never git add -A blindly
git commit -m "type: message"    # follow Conventional Commits (feat/fix/docs/refactor)
git push origin main
```

### Step 2 — Create GitHub Issue(s)

`gh` CLI is NOT installed. Use `curl` + the stored OAuth token from git credentials.

**Get the token:**
```bash
git credential fill <<'EOF'
protocol=https
host=github.com
EOF
# Copy the `password=` value — that is the token
```

**Create an issue:**
```bash
GITHUB_TOKEN="<token>"
REPO="suraj-0023/little-footprints"

curl -s -X POST "https://api.github.com/repos/${REPO}/issues" \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "<issue title matching the commit>",
    "body": "<markdown body — include summary, what changed, and the commit SHA>"
  }' | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('number'), d.get('html_url'))"
```

**Issue body template:**
```markdown
## Summary
- Bullet points of what changed and why

## Changes
| Area | Detail |
|---|---|
| File/feature | What was done |

## Commit
<SHA>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

### Step 3 — Close the Issue

```bash
curl -s -X PATCH "https://api.github.com/repos/${REPO}/issues/<NUMBER>" \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"state": "closed"}' \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('state'), d.get('html_url'))"
```

---

## Repo Details

| Key | Value |
|---|---|
| Remote | `https://github.com/suraj-0023/little-footprints.git` |
| Default branch | `main` |
| GitHub CLI | Not installed — use `curl` + `git credential fill` |
| Credential store | macOS Keychain via `git credential fill` (protocol=https, host=github.com) |

---

## Commit Message Convention

```
feat:     new feature or screen
fix:      bug fix
docs:     documentation only
refactor: code change, no behaviour change
chore:    tooling, config, deps, Firebase rules
style:    UI/theme changes only
```

---

## Project Overview

Flutter 3.x + Firebase Android baby memory app.  
State management: Riverpod 2.x. Navigation: GoRouter. Local cache: Hive/Isar.  
AI: Google ML Kit (on-device) + Claude API Haiku (via Cloud Functions — never called directly from client).  
Architecture: feature-first folder structure under `lib/features/`.

**4 build phases:** Foundation (wks 1–6) → AI & Intelligence (wks 7–12) → Stories & Export (wks 13–18) → Polish & Scale (wks 19–24).

---

## Flutter Commands

```bash
# Run on emulator (dev flavor)
flutter run --flavor dev -t lib/main_dev.dart

# Static analysis — must pass with zero issues before every push
flutter analyze

# Format code
dart format lib/

# Build release APK (prod flavor)
flutter build apk --flavor prod -t lib/main_prod.dart

# Run Cloud Functions locally
cd functions && npm run serve

# Deploy Firebase rules + functions
firebase deploy --only firestore:rules,storage,functions
```

---

## Code Navigation — Feature-First Structure

The project is split into feature folders. Before reading or editing any file, identify the feature it belongs to:

| Feature | Path | What lives here |
|---|---|---|
| Auth | `lib/features/auth/` | Google sign-in, session handling |
| Baby profile | `lib/features/baby/` | Baby name, DOB, cover photo, multi-baby switching |
| Collage (Home) | `lib/features/collage/` | Masonry grid, month grouping, photo picker |
| Memory detail | `lib/features/memory/` | Single memory view, EXIF data, tags |
| Timeline | `lib/features/timeline/` | Chronological event list, milestone overlay |
| Stories | `lib/features/stories/` | Monthly AI narrative screen, story viewer |
| Growth journal | `lib/features/growth/` | Height/weight logs, fl_chart growth curves |
| Letters | `lib/features/letters/` | Letters to the Future, unlock date, encryption |
| Export | `lib/features/export/` | PDF collage, video reel, share sheet |
| Family circle | `lib/features/family/` | Invite flow, QR code, role management |
| Settings | `lib/features/settings/` | App preferences, notifications, account |
| Shared widgets | `lib/shared/` | MemoryCard, TagChip, LoadingOverlay, etc. |
| Core | `lib/core/` | Theme tokens, constants, extensions, utilities |
| Cloud Functions | `functions/src/` | story-generator, on-this-day, monthly-digest, resize-image, invite-handler |

**Read only the feature folder relevant to the task. Never read the entire `lib/` tree unless the task explicitly spans multiple features.**

### Providers & Notifiers
- Riverpod providers live in `lib/features/<feature>/providers/`
- Notifiers live in `lib/features/<feature>/notifiers/`
- Repositories (all Firebase access) live in `lib/features/<feature>/repositories/`

### Architecture Rules
- All Firestore/Storage access goes through a repository class — never call Firebase directly from a widget or notifier
- Claude API is only called from Cloud Functions — never from the Flutter client
- No hardcoded strings — use `AppStrings` constants or `app_localizations`
- Target `minSdkVersion 24` (Android API 24+)
- Graceful error handling with user-visible feedback on every Firebase call
- Offline-first: new uploads queued locally when offline, synced on reconnect

---

## Firebase Security Rules (Summary)

- Read `families/{familyId}` only if `request.auth.uid` is in the `members[]` array
- Write to `memories/` only for users with `editor` or `admin` role
- Write to `users/{userId}` only if `request.auth.uid == userId`
- Read `letters/{letterId}` only after `unlockDate <= request.time`
- Deny all else by default
- **Never deploy rules changes without running the emulator suite first**

---

## AI Integration Notes

| Feature | Service | Called from | Auth |
|---|---|---|---|
| Image tagging | ML Kit | On-device (Flutter) | N/A |
| Monthly story (text) | Gemini 2.0 Flash | Cloud Function `story-generator.ts` | Vertex AI — service account ADC (automatic on Firebase) |
| Story illustration | Imagen 3 | Cloud Function `story-generator.ts` | Vertex AI — service account ADC (automatic on Firebase) |
| Milestone suggestions | Gemini 2.0 Flash | Cloud Function | Vertex AI — service account ADC |

**No API keys are stored in env config.** Cloud Functions running on Firebase automatically authenticate to Vertex AI via the project's service account (Application Default Credentials). You only need to **enable the Vertex AI API** in Google Cloud Console — no key generation required.
