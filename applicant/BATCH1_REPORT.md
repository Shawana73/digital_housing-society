# DHS Applicant — Batch 1 checkpoint
Date: 25 September 2026
Base: user-uploaded `DHS_Applicant_Updated new pics.zip` (Applicant app only)
Next checkpoint MUST start from `DHS_Batch1.zip`, not an earlier upload.

## Actual code changes

1. Registration (`lib/screens/register_screen.dart`, `lib/services/firestore_service.dart`):
   - Removed the unsafe generic-error handler that deleted `FirebaseAuth.instance.currentUser` merely because an exception occurred and the user was unverified. Existing Auth accounts are never deleted by registration error handling now.
   - A successful Auth creation is remembered while the form remains open, so retrying after a Firestore or email failure resumes the SAME UID instead of attempting a second Auth signup. A lost in-memory auth session can be reauthenticated using the email/password entered by that user.
   - CNIC registry and applicant transactions now READ both documents first and CREATE only missing documents. An existing owned registry/applicant is treated as an idempotent retry; another UID's CNIC is rejected without reassignment. Original validations, three steps and database fields remain in place.
   - Welcome notification is still attempted after new applicant creation, but a notification failure is logged separately and no longer makes a successfully saved profile appear to have failed. Email verification is still sent, then registration signs out and directs the user to Login.
   - Added stage-specific Flutter debug diagnostics and readable Firebase/Auth/Firestore messages rather than exposing a generic converted-Future error or silently deleting an account.
   - Removed the empty desktop white AppBar strip and added a Back action within the desktop registration panel. Mobile AppBar, form fields and 3-step flow were preserved.

2. Splash (`lib/screens/splash_screen.dart`): kept the exact Sep 22 green-trees/open-gates asset already present in the latest Applicant ZIP. On desktop, its whole portrait photo is displayed sharply on the right, over a darkened full-bleed background; the logo card sits left so the gates and road remain visible. Mobile image treatment is unchanged.

3. Dashboard (`lib/screens/applicant_dashboard_screen.dart`): kept the already-selected `dashboard_approved.jpeg` showing the white modern home, grey driveway and black gates (NOT Purple Haven). Expanded Chrome hero height slightly and made its full-height foreground photo on the right more visible, retaining readable text and the existing journey/status logic. Original mobile hero layout is unchanged.

4. Other banners: (`lib/screens/plots_screen.dart`, `lib/screens/dealers_screen.dart`, `lib/screens/profile_screen.dart`, `lib/screens/plot_map_screen.dart`, `lib/utils/app_assets.dart`):
   - Explore Plots: desktop uses an existing wide, daylight housing-community street image from the uploaded Applicant ZIP, with the visual focus on the houses and boulevard. Mobile keeps its prior aerial image.
   - Verified Dealers: desktop banner is taller with upper-facade focal alignment; mobile source and layout remain unchanged.
   - Profile: wide desktop headers include the whole existing portrait cover photo in a right-hand area, with left-hand text contrast preserved; existing mobile cover remains unchanged.
   - Static Plot Map: distinct grand society-entrance photo from the uploaded Applicant ZIP, different from Login, Explore and Dealers' *active* screen heroes. Its framing is adjusted toward the entrance, and map gallery fallbacks avoid repeating Explore's hero.

## Findings about the reported Chrome registration exception

Confirmed bugs found in the original **source**: an unverified Auth user could be deleted on an unrelated failure after Auth creation; CNIC registration was not retry-safe because the transaction merge-wrote to an *existing* registry document even though BOTH supplied rules files disallow registry updates. A welcome-notification error could also cause a saved registration to be treated as failed. These paths have been changed.

**The exact live cause of the particular screenshot cannot be proven in this offline session.** The screenshot shows a generic Flutter-web converted-Future message, not its underlying Firebase error code or stack. The supplied local rules were inspected but the *deployed* Firestore rules and the live Auth/Firestore network responses were not accessible. If the error recurs, run Chrome with `flutter run -d chrome`, submit once, then capture the `DHS registration [stage] ... error: <code>` diagnostic and relevant browser DevTools console stack **without sharing passwords or CNIC values**. Do not change/deploy shared Firebase rules on speculation.

An earlier failed build might already have created an orphaned CNIC registry pointing to a deleted Auth UID. This checkpoint does not auto-delete or reassign such records. An authorized Firebase administrator must investigate any such specific case before any cleanup.

## Verification performed in this environment

PASS — static Dart delimiter scan of 9 modified Dart files. This is not the Dart analyzer or a compilation check. The scanner accounted for a pre-existing nested-interpolation lexer quirk in the dashboard source.

PASS — all 31 referenced local images exist and can be decoded; YAML pubspec parses and core dependencies are present; the Splash asset is byte-identical to the user's chosen Sep 22 picture; 17 active main-screen photo slots have no exact duplicates by resized-image comparison.

PASS — original ZIP versus checkpoint comparison: precisely the 9 expected Dart source files changed; no pre-existing file was deleted. Login photograph, `pubspec.yaml`, lockfile, `firebase_options.dart`, `google-services.json`, web index and both Firestore rules files are byte-for-byte unchanged.

NOT RUN — `flutter pub get`, `flutter analyze`, `flutter test`, live Firebase registration, real Chrome rendering, real Android rendering. This environment lacks the Flutter/Dart SDK and a configured mobile device, and there was no authorized connection to the live backend. Accordingly **Batch 1 is a code/static-validation checkpoint, not a verified live registration fix**.

## Files changed

- `lib/services/firestore_service.dart`
- `lib/screens/register_screen.dart`
- `lib/screens/splash_screen.dart`
- `lib/screens/applicant_dashboard_screen.dart`
- `lib/screens/plots_screen.dart`
- `lib/screens/dealers_screen.dart`
- `lib/screens/profile_screen.dart`
- `lib/screens/plot_map_screen.dart`
- `lib/utils/app_assets.dart`
- `BATCH1_REPORT.md` (this new report)

No new image file was necessary: the precise Splash and Dashboard selections and suitable distinct alternatives already existed in the latest uploaded project. The original image assets are preserved.

## Windows laptop testing (before Batch 2)

Open Command Prompt or PowerShell inside the extracted `applicant` folder (the one containing `pubspec.yaml`):

```powershell
flutter doctor
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

On a connected Android phone with USB debugging, in a **separate** terminal in the same folder:

```powershell
flutter devices
flutter run -d <device-id-from-flutter-devices>
```

For backend verification use an authorized non-production test environment or a permitted test registration, and confirm the Auth UID matches `applicants/{uid}` and the immutable CNIC registry. Verify email delivery, a successful verified login, failed-network retry safety, Chrome's missing white strip, and desktop/mobile image framing before considering the registration error fully resolved.

## Deferred work

Only Batch 1 has been implemented. Dashboard card/Quick Actions compacting, Dealer cards/filter revisions, Profile settings redesign and the Plot Size `15` normalization are **Batch 2**. Payment, Application, Documents and Result redesigns are **Batch 3**. Full integration/regression checks and the final all-batches ZIP are **Batch 4**.
