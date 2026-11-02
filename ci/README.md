# Mobile builds

The **Mobile APK and IPA** GitHub Actions workflow runs on pushes to `main` or manually from the Actions tab. Pull requests run analysis and tests only. Android and iOS builds run in parallel after validation. Documentation-only pushes skip builds. Artifacts expire after 14 days.

Download both artifacts from a successful workflow run:

- `mavens-android-apk-*`: extract and install `mavens-attendance-android.apk`.
- `mavens-ios-ipa-unsigned-*`: extract the ZIP, open iLoader, and select `mavens-attendance-ios-unsigned.ipa`. Do not select the outer GitHub artifact ZIP. iLoader signs and installs the app using your Apple account/device setup. This is a release-mode arm64 physical-device app, not a simulator/debug build or an App Store export.

Each artifact includes a SHA256SUMS.txt checksum. Builds use the hosted HTTPS API in `config/testing.json`, pinned Flutter 3.44.0 and increasing build numbers. No backend or database deployment is triggered.

## Signing

iOS does not require Apple signing secrets in GitHub because signing happens in iLoader. This workflow builds with `flutter build ios --release --no-codesign`, then packages `Payload/Runner.app` as an IPA. `flutter build ipa --no-codesign` alone does not produce the final IPA.

Android uses four GitHub Actions secrets:

- ANDROID_KEYSTORE_BASE64
- ANDROID_KEYSTORE_PASSWORD
- ANDROID_KEY_ALIAS
- ANDROID_KEY_PASSWORD

They contain the existing Android testing key so APK updates retain the previous testing signature. The APK is release-mode code signed for direct testing, not configured for Play Store publication. Key files and passwords are never committed. Keep the same secrets for future builds.

The IPA is unsigned until iLoader signs it. Refresh/signing duration and device requirements depend on your Apple account and iLoader setup. See the official [iLoader project](https://github.com/nab138/iloader).

GitHub-hosted macOS jobs consume the account's Actions quota for private repositories. No larger runners, paid add-ons or billing settings are enabled by this workflow.
