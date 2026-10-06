# DHS Applicant — Registration hotfix after Batch 1

Base: the already-updated `DHS_Batch1.zip`. No other screen, backend configuration, Admin app, rules, pictures, or payment code changed.

## What the new screenshot establishes
The error is thrown **during saving your applicant profile**, after the Firebase Auth registration stage. The prior generic web exception concealed the underlying condition. The screenshot does not reveal the deployed Firestore rules, server response, or whether an old CNIC registry record points to another UID; an exact live root cause cannot be proven without sanitized Chrome console diagnostics / Firebase Console inspection.

## Code changes

1. `lib/services/firestore_service.dart`: removed `runTransaction` from registration only. Dart exceptions inside FlutterFire web transaction callbacks can surface as generic converted-Future errors instead of the original duplicate-CNIC / Firestore error. The new implementation performs two server reads **outside** the callback (CNIC registry, applicant record), explicitly checks ownership and saved CNIC, and commits ONLY missing documents using a **single atomic Firestore write batch**. It never rewrites an existing registry or applicant, and never deletes an Auth user. Concurrent CNIC safety requires the deployed rules to deny registry updates, as BOTH supplied DHS Firestore rules files do. It logs which stage was reached without logging personal data.
2. `lib/screens/register_screen.dart`: if a prior attempt already created a signed-in unverified Auth user with the entered email, registration resumes that UID. If an earlier browser run created the Auth user but lost the session, an email-already-in-use result attempts to sign in with the provided password and resumes the **same unverified account**. It does not override verified accounts. A registry attached to another UID produces a readable support instruction, never an automatic reassignment. Other Auth / Firestore errors show stage-specific messages. Existing 3-step fields/validation, verification email, existing user account protection, welcome notification and navigation remain.

## IMPORTANT: Possible legacy orphan record
If an EARLIER version already deleted an unverified Auth user after partially creating a `cnic_registry/{digits}` document, a new Auth UID cannot claim that document. This patch WILL NOT silently delete or reassign it. An authorized administrator should first confirm that the registry UID has **no** existing Firebase Authentication user, that `applicants/{oldUID}` is absent, and that the identity/CNIC claim is legitimate. Only after evidence-backed ownership checks should an admin decide whether and how to repair the old record, coordinating with the shared Admin backend. A different valid UID must never be displaced.

## Checks performed / unavailable
- Compared every file against the exact Batch 1 ZIP. Only the two Dart registration-related source files differ, plus this new report.
- Parsed the modified Dart files with a basic string/comment-aware bracket check (not a Dart analyzer).
- Verified new project ZIP file integrity via CRC.
- **NOT RUN:** `flutter pub get`, `flutter analyze`, `flutter test`, live Firebase registration, Chrome rendering, or Android testing, because this environment has no Flutter/Dart SDK or access to the user's deployed Firebase project. A successful live registration is NOT claimed.

## Windows smoke test
Unzip into a NEW folder (do not mix old source), open Terminal inside the `applicant` folder containing `pubspec.yaml`, then run:

```powershell
flutter clean
flutter pub get
flutter analyze
flutter run -d chrome
```

Test with the same email/password as the earlier failed attempt, provided that account belongs to you. Avoid creating repeated new accounts. If it still fails, press F12 in Chrome, choose **Console**, submit once, and capture only the `DHS registration [...]` and `Firebase error: <code>` lines plus relevant stack; redact email, passwords, CNIC and access tokens. If the message says CNIC belongs to another account, STOP retrying and check the registry/UID with an authorized Firebase administrator. Do NOT blindly delete registry documents, Auth users, or deploy rules.
