**SUPERSEDED FOR PHOTO FITTING:** The newer `SHARP_PHOTO_FIX_REPORT.md` describes the latest no-blur correction. This document records the preceding checkpoint and its generated assets, which have since been removed.

# DHS Applicant — responsive photography repair checkpoint

**Base ZIP:** `DHS_Batch1_Registration_CNIC_Fix.zip` from the immediately preceding registration checkpoint. This ZIP is a visual-only update to that same Applicant project; it is **not** a completed Batch 2 or a complete final multi-batch redesign.

## What changed

- **Splash:** the original approved green trees/open black gates/driveway photograph remains the source. Its 2304×1296 desktop rendition combines the complete gate with a softly feathered continuation from the *same* photo instead of the former hard 2-column image split. The translucent white DHS logo box is now **centered** at desktop and mobile widths. The existing mobile photo is unchanged.
- **Dashboard:** the exact selected white modern house, driveway and gates remains the source. A new 2400×770 desktop rendition retains the house and driveway in a sharp region at the right and fades into a color-matched continuation under the readable left-side text. The previous separately overlaid `FractionallySizedBox` has been removed. The existing mobile original is unchanged. Note: the selected original `dashboard_approved.jpeg` is **735×1105**; processing it into a larger canvas improves desktop composition and Flutter filtering but cannot create genuinely new photographic detail. A higher-resolution copy of *this exact photo* would be needed for native HD detail.
- **Explore Plots:** replaced the sunny street header with a distinctly different uploaded **aerial master-planned community** photograph. Matched widescreen desktop and the existing square mobile source; the asset is not used on another main-screen hero.
- **Static Plot Map:** changed the header source to the different uploaded illuminated entrance/fountain photo, with distinct desktop and compact viewport compositions. The actual interactive/static plot map, plot records and filters remain intact.
- **Verified Dealers:** replaced the severe desktop facade crop with a ratio-matched seamless composition of the existing uploaded modern sales-office photo. Added a ratio-matched version of the existing mobile gate photo. The verified dealer queries, filters, buttons and business data remain unchanged.
- **Register as Dealer:** constructed a natural desktop banner from the previously selected sunset entrance photograph; also created a compact banner from its own previously selected mobile home photograph. Its 5-step dealer registration form, photo upload and service logic remain unchanged.
- **Profile:** preserved the exact lavender-house photograph while replacing the desktop hard-cut duplicate image with one continuous, color-matched image background. The existing compact profile portrait remains. All profile actions, personal fields and notification settings are untouched.
- **Explore Plots card pictures:** replaced destructive `BoxFit.cover` foreground crops with a reusable `FullPhoto` widget: photo is displayed entirely with `BoxFit.contain`; any wide leftover area is a soft, color-matched extension of the **same** photo. Firestore `imageUrl` retains precedence, with existing bundled photo on network error. The card photo region can be taller where space permits. The same full-photo treatment is used on the Static Plot Map's plot-details images. Neither availability badges nor card actions are removed.
- The Login photo, Registration photo and original files remain unchanged. No purple tint was applied to any photographic hero outside the already-existing Registration screen.

## Changed source files

1. `lib/utils/app_assets.dart`
2. `lib/screens/splash_screen.dart`
3. `lib/screens/applicant_dashboard_screen.dart`
4. `lib/screens/plots_screen.dart`
5. `lib/screens/plot_map_screen.dart`
6. `lib/screens/dealers_screen.dart`
7. `lib/screens/dealer_registration_screen.dart`
8. `lib/screens/profile_screen.dart`

New shared Flutter widget: `lib/widgets/full_photo.dart`. Ten new `.jpg` assets in `assets/backgrounds/` use the originally uploaded photographs; the source images themselves were not overwritten. `pubspec.yaml` already lists `assets/backgrounds/` so it needs no change.

## Verification performed here

- The latest **CNIC-fix** archive was the direct starting point. Eight existing Dart files changed, one Dart widget and ten JPEGs were added; no original file was omitted from the checkpoint. The signup/Auth/Firestore service code, register screen, Firebase config, Firestore rules, `pubspec.yaml` and lockfile compare byte-for-byte with the original base ZIP.
- Token-level Dart delimiter checks passed for changed files (the pre-existing, unmodified nested string interpolation in the Dashboard's featured-card area is outside the changed region). These are **static checks only, not Dart compilation**.
- Validated all ten new JPEG files decode and all `AppAssets` literals refer to existing files. Rendered `BoxFit.cover` previews for seven desktop and seven mobile viewport samples, and `BoxFit.contain` previews of six plot-card source photos. These are image-geometry previews, **not actual Flutter/Chrome or Android screenshots**.
- Confirmed the package ZIP has zero CRC errors and all source files appear inside (verify ZIP output record for final byte count).

**Not tested here:** Flutter SDK/Dart analyzer, widget tests, a running Chrome session, Android simulator/physical phone, real Firebase network data or network-photo CORS. SDK/emulator and live Firebase testing are not available in this environment. Do not treat static verification as proof that every mobile device renders perfectly.

## Run on your Windows machine

Open the ZIP's `applicant` directory (the directory containing `pubspec.yaml`) in Android Studio or VS Code. In that directory, run:

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

Check Chrome widths around 1280 and 1600, then Android/mobile widths around 360 and 390. To test a connected Android phone:

```powershell
flutter devices
flutter run -d YOUR_ANDROID_DEVICE_ID
```

The app reads real Firestore content; network plot pictures that are already very low resolution cannot become true HD by adjusting Flutter fitting. To identify any remaining clipping, provide a fresh screenshot **and the current viewport width**; no backend or rule deployment is necessary for these visual changes.
