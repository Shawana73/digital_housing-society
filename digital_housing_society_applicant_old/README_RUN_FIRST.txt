Digital Housing Society Applicant Module - Fixed Build

What is included:
- New DHS logo added in assets/logos/dhs_logo.png
- Android launcher icons generated from the DHS logo
- Real housing society background images added in assets/backgrounds/
- Splash, login, forgot password, dashboard welcome card, and profile header updated with professional backgrounds/logo
- Dashboard greeting changed from Assalam-o-Alaikum to Hello
- Application Full Name and CNIC fields are now editable
- File picker package updated for new Flutter Android embedding
- Gradle/AGP/Kotlin config updated for newer Flutter/Android Studio
- Upload timeout handling added so upload does not keep loading forever
- Profile UI redesigned to look more professional
- Plot map has demo fallback data if Firestore plots collection is empty
- Payment and balloting screens have safe default config if Firebase config docs are not yet created

Run steps:
1. Open the inner folder only:
   digital_housing_society_applicant

2. Make sure JDK 17 is installed. If your system Java is newer, android/gradle.properties already points Gradle to:
   C:/Program Files/Eclipse Adoptium/jdk-17.0.19.10-hotspot
   If your JDK 17 folder has a different name, update that line.

3. In Android Studio terminal run:
   flutter clean
   flutter pub get
   flutter run

Firebase collections used by the app:
- applicants
- applications
- uploads
- payments
- notifications
- plots
- ballot_config/main
- ballot_updates
- ballot_results
- payment_config/hbl

Important Firebase note:
Firestore collections are created automatically when the first document is written. User-based collections are created when the user registers, submits application, uploads documents, or submits payment. For plots/payment/ballot config, the app now has safe demo/default fallback so the UI will still work even if those docs are empty.

Recommended Firebase rules are in:
- firebase/firestore.rules
- firebase/storage.rules

If document upload fails with a Firebase Storage permission error, deploy storage rules from the firebase folder and confirm that Firebase Storage is enabled for your Firebase project.
