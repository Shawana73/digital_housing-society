# Registration CNIC fix — code-only checkpoint (26 Sep 2026)

**Base:** `DHS_Batch1_Registration_Hotfix.zip` (itself based on Batch 1). This checkpoint changes the registration method in `lib/services/firestore_service.dart` only. All previous Batch 1 image/UI changes and account-recovery handling remain intact.

## Reproduced rule/code mismatch from the user-provided deployed rules

The deployed rule is:

```
match /cnic_registry/{cnicId} {
  allow read: if isAdmin() ||
    (isSignedIn() && resource.data.uid == request.auth.uid);
  allow create: if isSignedIn() &&
    request.resource.data.uid == request.auth.uid;
  allow update: if isAdmin() ||
    (isSignedIn() && resource.data.uid == request.auth.uid);
  allow delete: if isAdmin();
}
```

The previous hotfix tried `registryRef.get(Source.server)` *before* creating a CNIC. For a new CNIC, the requested document is missing and `resource.data.uid` is inaccessible, so a signed-in non-admin can receive `permission-denied`. For a CNIC belonging to somebody else, the same `get` is correctly denied; the screenshot alone cannot distinguish those cases. This matches the new error stage but live account/CNIC state was not accessible here.

## Code-only fix: no deployed rules change required for ordinary new signup

- Read `applicants/{ownUid}` first; deployed rules allow that get even when the applicant document is missing.
- If the applicant does not exist, atomically write `cnic_registry/{13Digits}` and `applicants/{ownUid}` in ONE Firestore batch, without trying to read the missing CNIC record. With the supplied deployed rules: new CNIC -> `create` allowed, same-UID legacy CNIC -> owner `update` allowed, different-UID existing CNIC -> `update` denied and whole batch rolled back.
- If the applicant *already exists*, confirm its CNIC matches the form, then read the *existing owner's* CNIC registry record; an inconsistent/missing/other-owned registry needs an administrator's review and is not silently repaired.
- Show a specific error if the atomic claim is permission-denied. The app does not delete users, remove CNIC registry entries, modify Admin code, change or deploy Firebase rules, or overwrite an existing applicant profile.
- Email verification, welcome notification, account recovery, forms, navigation and images remain as in the prior checkpoint.

## Important: existing live data may need administrator review

If the *same CNIC* was registered previously under a DIFFERENT UID, even if an obsolete app deleted that Auth account, the atomic batch must not steal/reassign that CNIC. A trusted Firebase admin needs to verify identity, inspect `cnic_registry/{CNIC digits}` -> `uid`, check `applicants/{uid}` and Firebase Authentication user existence, and decide an approved repair procedure. Do not share CNIC or password in ChatGPT screenshots. Do not delete any document or Auth user blindly.

## Caution about rules files

`applicant/firebase/firestore.rules` in the project archive is NOT the same as the newly supplied **deployed Firebase Console rules**. It is intentionally left untouched here. Do NOT deploy it over the live rules; the live project is shared with the separate Admin app. The supplied deployed registry rule permits a record owner to update their own registry record (including ownership fields). A future separately reviewed hardening could restrict owner updates, but would change legacy-partial-signup recovery and is NOT part of this hotfix.

## Verification boundaries and steps

- Static checks and ZIP CRC verification were performed offline; see the external test report. Flutter/Dart SDK, a browser/emulator and live Firebase credentials are unavailable here, so **actual signup is NOT confirmed**.
- On Windows: extract the new ZIP into a new folder; open `applicant` (with `pubspec.yaml`); run `flutter clean`, `flutter pub get`, `flutter analyze`, and `flutter run -d chrome`.
- Retry ONCE with the same original email/password and CNIC (if you own that account). A new Auth account is not needed if the last failure left you signed in as an unverified user.
- If blocked again, inspect the Chrome Console output `DHS registration [...]`; a fresh `permission-denied` on the atomic batch suggests a CNIC collision or a *different* deployed rule constraint, not the previous pre-read bug. Involve the authorized Firebase admin before altering a CNIC or publishing any rules.
