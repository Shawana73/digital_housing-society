Digital Housing Society Applicant Module - Advanced Fixed Build

Open this folder in Android Studio:
  digital_housing_society_applicant

Run:
  flutter clean
  flutter pub get
  flutter run

Important fixes in this version:
- Firestore composite-index errors removed from applicant/payment/profile/balloting loading by avoiding orderBy + where compound queries.
- Long Firestore error messages are replaced with shorter app-friendly messages where possible.
- Profile loads applicant details from Firestore and falls back to application details if needed.
- Profile picture upload/remove saves to the applicant profile record and displays as a centered circular crop.
- Contact Us screen redesigned with location, phone, email and support form.
- Contact messages save in Firestore collection: contacts.
- Documents screen now has separate slots for CNIC front, CNIC back, application form, recent photograph and payment reference.
- Each selected document gets a unique serial number and verification status in Firestore.
- Balloting screen supports status states from Firestore ballot_config/main: upcoming, live, winner, notSelected, completed.
- Balloting screen uses official Firestore config/results/updates only for status, numbers, winners and summary.
- Static Plot Map screen no longer shows placeholder plot records; it waits for Firestore plots collection data.
- Payment uses Stripe Test Mode/reference workflow and saves the submitted payment record to Firestore.

Firestore collections used:
  applicants
  applications
  uploads
  payments
  notifications
  contacts
  plots
  ballot_results
  ballot_updates
  ballot_config
  payment_config
  app_metadata

Apply Firestore rules from:
  firebase/firestore.rules

If Android install fails with 'not enough space', free storage on the phone and run again.
