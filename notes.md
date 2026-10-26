# Nourish Release Audit Notes

Use this file for policy references, build findings, runtime risks, and decisions.

## Initial Findings

- No asset catalog or App Store icon exists.
- A USDA key was present in tracked `Config/AppConfig.xcconfig` and the example
  secrets file. It was moved to ignored `Config/LocalSecrets.xcconfig`.
- Nutritionix credentials must not be bundled in an App Store client.
- Release currently targets iOS 26.0 and supports iPhone and iPad.
- CloudKit correction storage was removed because App Review Guideline 5.1.3(i)
  prohibits storing personal health information in iCloud.
- `PrivacyInfo.xcprivacy` and an in-app privacy policy were added.
- Release provider access is limited to the on-device matcher and user-controlled
  Open Food Facts lookup. Credentialed provider tooling is Debug-only.
