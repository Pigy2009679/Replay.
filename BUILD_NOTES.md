# Build notes and known limitations

The GitHub Actions workflow generates Flutter's platform scaffolding, overlays the
native Android implementation, and sets the Android namespace/application ID to
`com.replay.app`.

## Current Android implementation scope

This is an initial capture-engine baseline, not a store-ready release. Validate:
- MediaProjection foreground-service behavior on Android versions supported by the app.
- Android 14+ one-session MediaProjection token behavior.
- Runtime notification permission behavior.
- Display rotation, tablet/foldable dimensions, and secure surfaces.
- Finalization after process termination or system interruption.
- Recorder behavior and codec availability on target devices.

The UI currently provides the local file list and delete action. In-app video playback,
thumbnail generation, export/share, configurable quality, segment rotation, and
fully implemented cleanup thresholds are follow-on tasks. The storage policy choice is
persisted locally, but automatic cleanup execution is not yet implemented.

## iOS

The iOS capture engine is intentionally not represented as functional. Implement the
ReplayKit broadcast flow as a separate native milestone and verify current App Store
rules and supported device behaviors.
