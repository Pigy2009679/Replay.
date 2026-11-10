# Build notes and known limitations

The GitHub Actions workflow generates Flutter's Android platform scaffolding, overlays the
native Android implementation, and uses the Android namespace/application ID
`com.replay.app`.

## Current Android implementation scope

Implemented:
- User-approved MediaProjection screen capture.
- MediaProjection foreground service with a persistent notification and system indicator.
- MP4 file creation in app-private Movies storage.
- Pause, resume, stop, and local recording discovery.
- In-app MP4 playback.

Validate on physical devices:
- MediaProjection foreground-service behavior on supported Android versions.
- Android 14+ one-session MediaProjection token behavior.
- Runtime notification permission behavior.
- Display rotation, tablet/foldable dimensions, and secure surfaces.
- Finalization after process termination or system interruption.
- Recorder behavior and codec availability on target devices.

Not implemented yet:
- Automatic deletion/cleanup thresholds and storage-limit monitoring. The settings currently
  save the selected preference only.
- Thumbnail generation, export/share, configurable quality, and recording segmentation.
- Recovery of unfinished recordings after an abrupt process or device termination.

## iOS

The iOS capture engine is not implemented. Add a separate ReplayKit broadcast flow and verify
current App Store rules and supported device behavior before presenting iOS recording as available.
