# REPLAY

A Flutter starter project for a transparent, user-controlled Android screen recorder and local video library.

## Current implementation

- Flutter interface: Home, Library, History, Settings, and recording details.
- Android screen capture through the system MediaProjection consent prompt.
- Foreground recording service with a persistent system notification and Stop action.
- MP4 recordings saved in app-private Movies storage (with an internal-storage fallback).
- Pause, resume, stop, and local recording discovery.
- In-app video playback for saved MP4 recordings.
- Local storage-preference selection.

## Important platform notes

- Android recording requires approval in the Android system screen-capture prompt for each session.
- The foreground-service notification and Android's system recording indicator remain visible.
- Android may block protected content. REPLAY does not bypass protected-content restrictions.
- Recordings are not silently restarted after reboot, permission loss, or process death.
- Automatic storage cleanup and storage-limit monitoring are preference-only placeholders in this build; they do not yet delete files or stop recordings automatically.
- The iOS screen-recording engine is not implemented. The Android capture service is the only supported capture implementation in this starter.
- Test recording and playback on real devices across supported Android versions before wider distribution.

## Build with GitHub Actions

1. Extract the contents of this ZIP directly into the repository root (so `pubspec.yaml` and `.github/` are at the root).
2. Open **Actions** and run **Build REPLAY Android APK** (or push to `main`).
3. Download the `replay-android-apk` artifact from the completed workflow.

The workflow generates the standard Android project files, overlays the REPLAY native capture implementation, runs Flutter analysis, and builds a release APK.

## Local build

Install Flutter, then run:

```bash
flutter create --platforms=android --org com.replay --project-name app .
flutter pub get
flutter analyze
flutter build apk --release
```

## Project layout

```text
lib/                    Flutter UI and platform-channel client
android/                Android manifest and Kotlin source overlay
.github/workflows/      APK build workflow
```
