DIGITAL HOUSING SOCIETY (DHS) — FINAL APPLICANT MODULE
=====================================================

FINAL ARCHITECTURE
- Flutter app for Android + Chrome/Web
- Firebase Authentication
- Firebase Cloud Firestore
- DHS professional blue → purple design system
- Shared navigation: desktop fixed sidebar + mobile slide-out version of the
  same sidebar destinations
- Firebase email-verification link required before dashboard access
- Documents are metadata-only in Firestore; Firebase Storage is intentionally
  not used
- Stripe workflow is FYP test-mode/simulation only
- Balloting official configuration/results remain admin-owned

FINAL APPROVED PROFESSIONAL SCREENS
- Dashboard: premium DHS hero, application journey, live statuses, quick
  actions, featured plot, recent activity
- Static Plot Map: "Your Plot. Your Future." responsive interactive master
  plan, Phase/Block filters, plot selection, zoom/full-screen, live details
- Applicant Profile: premium applicant card, Edit/Share/ID actions,
  membership progress, linked services, favourites, security/support
- Explore Plots: responsive search/filter cards, favourites, details and map
- Verified Dealers: verified-only backend directory + visible registration CTA
- Dealer Registration: responsive multi-step form + real Firestore submission

NAVIGATION
Desktop/Chrome:
- fixed left sidebar

Mobile:
- hamburger opens the same destinations as a slide-out drawer

Destinations:
Dashboard
Explore Plots
Static Plot Map
Applications
Dealers
Register as Dealer
Payments
Documents
Messages
Favourites
Profile
Settings
Logout

ADMIN DATA BEFORE ADMIN MODULE INTEGRATION
The app is still backend-connected. For administrator-owned `plots` and
`dealers`, the UI uses local professional preview records ONLY when Firestore
has no official records yet.

Live Firestore data always takes priority.

See:
FIRESTORE_SAMPLE_DATA_SETUP.txt
lib/utils/demo_data.dart
firebase/sample_firestore_data.json

SECURITY
1. Publish the final firestore.rules.
2. Ensure the authorized admin account has:
   admins/{ADMIN_UID}
   active: true
3. Applicant accounts cannot write official plot/dealer/ballot/result
   administration fields.
4. Applicant CNIC/CNIC registry values are protected after registration.
5. Ballot results are readable only by the owner applicant or admin.

DEALER REGISTRATION
- Saves to dealer_registrations/{uid}
- verificationStatus starts as pending
- Fixed the previous false "complete all required fields" submit blocker
- Four required document metadata records:
  CNIC Front, CNIC Back, Business Card, Office Photo
- PDF/JPG/JPEG/PNG, max 5 MB metadata validation
- Admin approval is still required before public directory publication

PLOTS
- Backend: Firestore `plots`
- Natural search supports examples such as:
  block B, phase 2, plot 245, plot #245, 10 marla, residential, available
- Responsive cards avoid the old mobile right-overflow layout
- Favourites persist in the applicant Firestore record
- Different bundled society images rotate when imageUrl is empty

BALLOTING
Applicant eligibility requires:
- applications.status = approved
- uploads.verificationStatus = verified
- payments.status = verified

Winner / Not Selected is derived from the signed-in applicant's own
ballot_results record.

LOCAL FINAL CHECK
Run from the project root:

flutter pub get
flutter analyze
flutter test
flutter run -d chrome

Then also run on the Android device/emulator used for the final demo.

GITHUB DESKTOP
Do NOT create a new repository.
After the local final runtime pass:
1. Open the existing shared repository.
2. Review changed files.
3. Confirm generated/cache folders are not staged.
4. Commit with a meaningful message, for example:
   Finalize applicant UI, navigation and Firebase workflows
5. Push origin.

IMPORTANT
This package has received static source/configuration checks in the generation
environment, but that environment does not include the Flutter SDK. Therefore
the final `flutter analyze`, `flutter test` and device/browser runtime pass must
be run once on the user's Flutter workstation before the final Git commit.
