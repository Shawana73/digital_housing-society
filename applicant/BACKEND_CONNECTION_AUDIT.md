# DHS Applicant Backend Connection Audit

Primary backend: Firebase Authentication + Cloud Firestore.

## Data-driven screens
- Dashboard: applicant, application, payment, uploads, balloting result, notifications, plots.
- Application: applicant/application Firestore records.
- Documents: upload metadata Firestore records.
- Payments: payment records / test-mode payment configuration.
- Balloting: `ballot_config`, applicant eligibility and applicant-specific result.
- Balloting Result: applicant-specific `ballot_results`.
- Explore Plots: `plots`, applicant favourites persistence.
- Static Plot Map: `plots`.
- Verified Dealers: verified records from the sanitized `dealers` collection; no runtime dummy fallback.
- Dealer Registration: `dealer_registrations`, applicant prefill and submission status.
- Profile: applicant record, application/payment/upload summaries, notification preference.
- Notifications: applicant notifications.
- My Reports: applicant-owned report/application data.
- Settings: applicant preference update.
- Contact DHS: `contacts`.
- Favourites: uses the backend-connected Explore Plots screen in favourites-only mode.

## Static informational screens
FAQ, Privacy and Terms contain informational content and do not require a database write.
They remain within the authenticated DHS navigation and can later be admin-managed without changing the applicant data model.

## Admin integration behavior
`plots` and `dealers` are Firestore-backed with no runtime dummy fallback. Dealer registration
documents stay private in `dealer_registrations`; the public directory reads sanitized verified
records from `dealers`.
