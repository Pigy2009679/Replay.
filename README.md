# REPLAY

A Flutter starter project for a transparent, user-controlled screen recorder and local video library.

## Current implementation

- Flutter interface: Home, Library, History, Settings, video details.
- Android native screen capture using the MediaProjection consent flow.
- Android foreground recording service with a persistent system notification and Stop action.
- MP4 recording stored in the app's private Movies directory.
- Pause, resume, stop, and basic local recording discovery.
- Storage policy settings UI and local preferences.
- GitHub Actions workflow that generates the Flutter platform scaffolding and builds an Android APK.

## Important platform notes

- Android recording requires the user to approve the system screen-capture prompt for each capture session. The foreground notification remains visible.
- Android may block protected content. REPLAY does not bypass protected-content restrictions.
- This starter does not silently restart recording after a reboot, permission loss, or process death.
- The iOS screen-recording engine is not implemented in this starter. iOS recording must be added using ReplayKit's supported user-initiated flow and broadcast extension. The iOS UI reports that recording is not yet available rather than pretending to record.
- The Android native implementation is a baseline and should be tested on real devices across Android versions before release.

## Build with GitHub Actions

1. Create a new GitHub repository.
2. Upload the contents of this ZIP to the repository root.
3. Open **Actions** and run **Build REPLAY Android APK** (or push to the `main` branch).
4. Download the `replay-android-apk` artifact from the completed workflow.

The workflow runs `flutter create` to generate the standard Android/iOS project scaffolding, then builds the Android APK.

## Local build

Install Flutter, then run:

```bash
flutter create --platforms=android,ios .
flutter pub get
flutter run
```

For Android release APK:

```bash
flutter build apk --release
```

## Project layout

```text
lib/                    Flutter UI and platform-channel client
android/                Android manifest and Kotlin source overlay
.github/workflows/      APK build workflow
```

The GitHub workflow creates the rest of the standard Flutter platform files.
