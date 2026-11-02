# Mavens Attendance mobile

Flutter attendance app for Mavens Consulting. English-only UI, recruiters and supervisors, attendance-only personnel, with Moataz as administrator. The Java backend is hosted separately; this repository contains the mobile app only.

See [CI/CD and APK/IPA downloads](ci/README.md). Push to `main` or run **Mobile APK and IPA** manually in GitHub Actions.

`lib/features/` contains auth, attendance, leave, team, and messaging. Each has data sources/repository implementation, domain contracts/use cases, and presentation state/screens. Shared infrastructure is under `lib/core/`; environment/theme configuration is under `lib/config/`.

Run `flutter analyze` and `flutter test`. The app defaults to the hosted HTTPS testing API. Use `flutter run --dart-define-from-file config/testing.json` for that environment, or the workspace `run-mobile.ps1` for a local Android emulator backend. Android/iOS app identifier: `com.mavens.attendance`.

Native connectivity test: `flutter test integration_test/network_smoke_test.dart -d DEVICE_ID --dart-define-from-file config/testing.json`. It uses an intentionally nonexistent account, never a real employee's login. After integration testing, rebuild the normal app with `npm run build:mobile` from the workspace root.
