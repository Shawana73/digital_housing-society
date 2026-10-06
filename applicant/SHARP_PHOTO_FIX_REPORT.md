# DHS Applicant — Sharp, No-Blur Photo Fix

**Base:** `DHS_Batch1_Visual_Responsive_Fix.zip`, the last visual checkpoint incorporating the earlier registration/CNIC fix. This is an **image-fitting-only checkpoint**, not Batch 2 or the final multi-batch redesign.

## What changed in actual Flutter source

- **Splash:** removed the generated blurred panorama entirely. The exact supplied green trees/open black gates/driveway photo is kept sharp and **fully visible in the middle of a desktop screen**, against solid, foliage-colored side margins. The DHS white card stays centered. Small-screen use of the original photograph is preserved.
- **Dashboard:** removed the baked-blurred background. The *exact selected* white house, driveway and black gate photo now appears intact and sharp on the right of a clean dark text surface on desktop. The existing mobile photo and all application/progress/navigation logic remain. The original supplied photo is **735 × 1105**, so it is portrait and cannot honestly fill a desktop panorama while also remaining wholly visible. Its source does not contain native HD detail for a full-width desktop crop.
- **Explore Plots:** the original aerial housing-society photo appears without any generated blurred side panels. A sharp, uncropped, photo-aware desktop layout replaces the previous blended image. The mobile image is the original source.
- **Explore plot cards and map plot-details cards:** removed the `ImageFiltered.blur` photographic background and duplicate cover image from the shared `FullPhoto` widget. Each Firestore image or bundled fallback is shown **once** with `BoxFit.contain`, against a clean, subtle neutral background wherever portrait imagery leaves unused space. Firestore `imageUrl`, fallback on network error, badges, and all actions remain intact. A full portrait photo in a landscape card necessarily has neutral side space: filling the card edge-to-edge would crop it.
- **Static Plot Map:** used a separate original *landscape* entrance/arch photograph from the uploaded project, with no blur on desktop or mobile. Only the banner imagery was replaced; the map, legend, filters, plot data and controls were not altered.
- **Verified Dealers:** restored the original high-resolution sales-office photograph and original mobile asset. Removed the generated, blurred copies. Desktop uses an expanded, photo-aware banner and dark, readable text surface; no dealer queries, filters or registration actions were changed.
- **Register as Dealer:** shows the existing original sunset entrance as a crisp, uncropped desktop photograph. The same landscape entrance is now used on narrow screens rather than severely cropping the former portrait home image into a short, wide mobile banner. Its five-step form, inputs and upload logic are untouched.
- **Profile:** original lavender-house photo fully visible and unblurred at the right on desktop; dark-plum identity panel preserves text legibility. Existing mobile photo, profile actions, avatar, notifications and data are untouched.
- For narrow **content areas** on responsive desktop/tablet layouts, the shared background adapts to use a single original full-bleed photograph instead of an unusably narrow image inset.

## Source-level scope

Updated 9 Dart files: `lib/screens/splash_screen.dart`, `lib/screens/applicant_dashboard_screen.dart`, `lib/screens/plots_screen.dart`, `lib/screens/plot_map_screen.dart`, `lib/screens/dealers_screen.dart`, `lib/screens/dealer_registration_screen.dart`, `lib/screens/profile_screen.dart`, `lib/widgets/full_photo.dart` and `lib/utils/app_assets.dart`. Added one reusable Dart widget: `lib/widgets/sharp_photo_backdrop.dart`.

Removed only the **ten unused generated** `*_seamless.jpg` files that contained artificially blurred photo margins. Original source photographs and the approved login image remain untouched. No extra image-generation assets or duplicated pictures were introduced.

## Checks completed in this environment

- Compared against the **last visual-fix ZIP**, not an earlier version. Registration screen, auth service, Firestore service, Firestore rules, Firebase config, login screen, `pubspec.yaml` and `pubspec.lock` are byte-for-byte unchanged.
- Static Dart lexical nesting checks on all edited/added Dart source files passed. This is not a Dart compile/test pass.
- All referenced images exist; original source photos were opened/decoded; references to deleted blur JPGs were eliminated.
- The two shared photo widgets have **no photographic blur effect**. A desktop-layout geometry preview was generated for seven screens, but it is *not* a Flutter-rendered Chrome or Android screenshot.
- The final ZIP received an archive CRC test and all contained files were checked after creation.

**Not tested here:** `flutter pub get`, `flutter analyze`, `flutter test`, a running Chrome session, an Android emulator/phone and Firebase network operations. Flutter/Dart SDK and an Android emulator are unavailable in this environment. The user should verify these on their Windows machine; the code changes have not been claimed to be device-verified. Since the app pulls some plot images from Firestore, the resolution/aspect ratio of user-uploaded URLs cannot be controlled by this code.

## Windows: verify the checkpoint

Extract the ZIP and open its `applicant` folder (contains `pubspec.yaml`). In that folder run:

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

Check Chrome at widths around **1280px** and **1600px**, and mobile/device widths around **360px** and **390px**. For a connected Android phone:

```powershell
flutter devices
flutter run -d YOUR_DEVICE_ID
```

**If the goal is both a full-width photographic desktop banner AND a completely visible photo with no letterboxing, supply a distinct landscape original.** A 735×1105 portrait source cannot satisfy all three conditions simultaneously without inventing image content or cropping essential details. The checkpoint deliberately prioritizes original photography, crispness and full visibility over artificial blur and destructive crops.
