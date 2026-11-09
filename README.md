# REPLAY

REPLAY is a user-controlled screen recording prototype. The Android build is generated from the starter project archive stored in this repository.

## Build the Android APK

1. Open the **Actions** tab.
2. Select **Build REPLAY Android APK**.
3. Select **Run workflow** on the `main` branch.
4. When the run completes, open it and download the `replay-android-apk` artifact.

The workflow checks and extracts `REPLAY_GitHub_Starter.zip`, generates the standard Flutter Android project files, restores the Android native source files, runs Flutter dependency and analysis checks, and builds a release APK.

## Current limitations

- This is an early development prototype, not a finished or store-ready app.
- Android screen capture requires the Android system's screen-capture consent and a visible foreground-service notification.
- Android protected content may be blocked. The app does not bypass those restrictions or hide recording indicators.
- iOS screen recording is not implemented in this starter.
- In-app video playback, thumbnails, export/share, quality controls, automatic storage cleanup, and recording segmentation still need implementation and device testing.

See [BUILD_NOTES.md](BUILD_NOTES.md) for the current development checklist.
