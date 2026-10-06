import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  FirestoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Future<void> saveApplicant(Map<String, dynamic> data) async {
    final uid = data['uid']?.toString();
    if (uid == null || uid.isEmpty) {
      throw Exception('Applicant uid is required.');
    }

    final cnicDigits = (data['cnicDigits'] ?? data['cnic'] ?? '')
        .toString()
        .replaceAll(RegExp(r'\D'), '');

    if (cnicDigits.length != 13) {
      throw Exception('A valid CNIC is required.');
    }

    final registryRef = _db.collection('cnic_registry').doc(cnicDigits);
    final applicantRef = _db.collection('applicants').doc(uid);

    // The deployed DHS rules allow a CNIC document to be read only by its
    // owner (or an admin).  A *new* CNIC document has no resource.data.uid,
    // so checking registryRef.get() BEFORE creating it is permission-denied.
    // First read only the applicant's own UID document (an allowed read).
    // For a new applicant, claim the CNIC and create the profile together in
    // one atomic batch. A CNIC already owned by a different UID will make the
    // registry write fail, rolling back the profile write as well.
    //
    // For a saved applicant, we can safely check their OWN registry record.
    // Never read other people's CNIC documents, reassign a CNIC, or delete an
    // Auth user. This uses the user's already-published rules unchanged.
    if (_auth.currentUser?.uid != uid) {
      throw StateError('Your login session changed. Please sign in again.');
    }

    developer.log('Reading own applicant profile', name: 'DHS.registration');
    final applicant = await applicantRef.get(
      const GetOptions(source: Source.server),
    );

    if (applicant.exists) {
      final saved = applicant.data() ?? <String, dynamic>{};
      final savedDigits = (saved['cnicDigits'] ?? saved['cnic'] ?? '')
          .toString()
          .replaceAll(RegExp(r'\D'), '');
      if (savedDigits != cnicDigits) {
        throw StateError(
          'Your account already has a different CNIC. Contact DHS support.',
        );
      }

      // Only an existing owner's CNIC is readable under the deployed rules.
      // A missing or other-owned record needs administrator investigation.
      developer.log('Confirming own CNIC registry entry', name: 'DHS.registration');
      try {
        final registry = await registryRef.get(
          const GetOptions(source: Source.server),
        );
        if (!registry.exists || registry.data()?['uid']?.toString() != uid) {
          throw StateError(
            'The CNIC registry does not match your saved account. '
            'DHS support must review it before registration can continue.',
          );
        }
      } on FirebaseException catch (error, stack) {
        if (error.code != 'permission-denied') rethrow;
        developer.log(
          'Existing profile could not read its own CNIC registry entry',
          name: 'DHS.registration',
          error: error,
          stackTrace: stack,
        );
        throw StateError(
          'Your profile exists, but DHS cannot verify its CNIC registry '
          'entry. An administrator must check that this CNIC belongs '
          'to your account. Your account has not been deleted.',
        );
      }
      developer.log('Existing registration documents confirmed',
          name: 'DHS.registration');
      return;
    }

    // Important: there is deliberately NO pre-read of a missing CNIC here.
    // Under the deployed rules, that pre-read was the permission-denied bug.
    // The registry write is create (new CNIC), owner-update (same-UID legacy
    // partial signup), or denied (another UID). Both writes commit together.
    developer.log('Atomically creating CNIC registry and applicant profile',
        name: 'DHS.registration');
    final batch = _db.batch();
    batch.set(registryRef, {
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(applicantRef, {
      ...data,
      'uid': uid,
      'cnicDigits': cnicDigits,
    });
    try {
      await batch.commit();
    } on FirebaseException catch (error, stack) {
      if (error.code != 'permission-denied') rethrow;
      developer.log(
        'Atomic registration write was denied; check CNIC ownership and rules',
        name: 'DHS.registration',
        error: error,
        stackTrace: stack,
      );
      throw StateError(
        'This CNIC may already be linked to another account, or Firestore '
        'blocked the registration write. DHS support should check CNIC '
        'registry ownership against your Firebase account. No existing '
        'account or document has been deleted.',
      );
    }
    developer.log('Registration documents confirmed', name: 'DHS.registration');

    // A welcome-notification failure must never undo a saved registration.
    try {
      await createNotification(
        recipientId: uid,
        title: 'Welcome to Digital Housing Society',
        message: 'Your applicant profile has been created successfully.',
        type: 'application',
      );
    } catch (error, stack) {
      developer.log(
        'Welcome notification could not be written; profile is saved.',
        name: 'DHS.registration',
        error: error,
        stackTrace: stack,
      );
    }
  }

  Future<DocumentSnapshot> getApplicant(String uid) {
    return _db.collection('applicants').doc(uid).get();
  }

  /// Applicant updates are intentionally limited.
  ///
  /// Email/profile activation is allowed only after Firebase Auth itself
  /// reports a verified email and the ID token is refreshed. Admin-owned
  /// fields are never accepted through a normal applicant update.
  Future<void> updateApplicant(
      String uid,
      Map<String, dynamic> data,
      ) async {
    final wantsVerificationSync =
        data['emailVerified'] == true || data['profileStatus'] == 'active';

    if (wantsVerificationSync) {
      await _syncVerifiedEmailStatus(uid);
    }

    final clean = Map<String, dynamic>.from(data)
      ..remove('uid')
      ..remove('cnic')
      ..remove('cnicDigits')
      ..remove('role')
      ..remove('verificationStatus')
      ..remove('profileStatus')
      ..remove('ballotingEligible')
      ..remove('ballotingRegistered')
      ..remove('emailVerified')
      ..remove('createdAt');

    if (clean.isEmpty) return;

    await _db.collection('applicants').doc(uid).update(clean);
  }

  Future<void> _syncVerifiedEmailStatus(String uid) async {
    var user = _auth.currentUser;
    if (user == null || user.uid != uid) {
      throw Exception('Please login again before syncing verification.');
    }

    await user.reload();
    user = _auth.currentUser;

    if (user == null || user.uid != uid || !user.emailVerified) {
      throw Exception('Your email is not verified yet.');
    }

    await user.getIdToken(true);

    await _db.collection('applicants').doc(uid).update({
      'emailVerified': true,
      'profileStatus': 'active',
    });
  }

  Future<DocumentReference> saveApplication(
      Map<String, dynamic> data,
      ) async {
    final applicantId = data['applicantId']?.toString();
    if (applicantId == null || applicantId.isEmpty) {
      throw Exception('Applicant id is required.');
    }

    final existing = await getApplication(applicantId);
    if (existing != null) {
      throw Exception('An application has already been submitted.');
    }

    final ref = _db.collection('applications').doc();
    await ref.set({
      ...data,
      'applicationId': ref.id,
      'status': 'pending',
    });

    await createNotification(
      recipientId: applicantId,
      title: 'Application Submitted',
      message: 'Your application has been saved and is pending review.',
      type: 'application',
      actionRoute: '/my-reports',
    );

    return ref;
  }

  Future<DocumentSnapshot?> getApplication(String applicantId) async {
    final snap = await _db
        .collection('applications')
        .where('applicantId', isEqualTo: applicantId)
        .limit(20)
        .get();

    if (snap.docs.isEmpty) return null;

    final docs = [...snap.docs];
    docs.sort((a, b) {
      final av = (a.data())['submittedAt'];
      final bv = (b.data())['submittedAt'];
      final at = av is Timestamp
          ? av.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0);
      final bt = bv is Timestamp
          ? bv.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });

    return docs.first;
  }

  Stream<QuerySnapshot> getMyApplications(String applicantId) {
    return _db
        .collection('applications')
        .where('applicantId', isEqualTo: applicantId)
        .snapshots();
  }

  Future<void> saveUpload(Map<String, dynamic> data) async {
    final applicantId = data['applicantId']?.toString();
    if (applicantId == null || applicantId.isEmpty) {
      throw Exception('Applicant id is required.');
    }

    final existing = await getUpload(applicantId);
    if (existing != null) {
      throw Exception('Documents have already been submitted.');
    }

    await _db.collection('uploads').doc(applicantId).set({
      ...data,
      'verificationStatus': 'pending',
    });

    await createNotification(
      recipientId: applicantId,
      title: 'Documents Submitted',
      message: 'Your document records have been submitted for verification.',
      type: 'verification',
      actionRoute: '/upload',
    );
  }

  Future<DocumentSnapshot?> getUpload(String applicantId) async {
    final doc = await _db.collection('uploads').doc(applicantId).get();
    return doc.exists ? doc : null;
  }

  Future<DocumentReference> savePayment(
      Map<String, dynamic> data,
      ) async {
    final applicantId = data['applicantId']?.toString();
    if (applicantId == null || applicantId.isEmpty) {
      throw Exception('Applicant id is required.');
    }

    final existing = await getPayment(applicantId);
    if (existing != null) {
      throw Exception('A payment record already exists.');
    }

    final ref = _db.collection('payments').doc(applicantId);
    await ref.set({
      ...data,
      'status': 'submitted',
    });

    await createNotification(
      recipientId: applicantId,
      title: 'Payment Submitted',
      message:
      'Your Stripe test payment record has been saved and is pending verification.',
      type: 'payment',
      actionRoute: '/payment',
    );

    return ref;
  }

  Future<DocumentSnapshot?> getPayment(String applicantId) async {
    final doc = await _db.collection('payments').doc(applicantId).get();
    return doc.exists ? doc : null;
  }

  Future<DocumentSnapshot?> getResultForApplicant(
      String applicantId,
      ) async {
    final direct =
    await _db.collection('ballot_results').doc(applicantId).get();
    if (direct.exists) return direct;

    final snap = await _db
        .collection('ballot_results')
        .where('applicantId', isEqualTo: applicantId)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first;
  }

  Stream<QuerySnapshot> getNotifications(String uid) {
    return _db
        .collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .snapshots();
  }

  Future<void> createNotification({
    required String recipientId,
    required String title,
    required String message,
    required String type,
    String? actionRoute,
  }) {
    return _db.collection('notifications').add({
      'recipientId': recipientId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': false,
      'actionRoute': actionRoute ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markNotificationRead(String notifId) {
    return _db
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});
  }

  Future<void> markAllNotificationsRead(String uid) async {
    final snap = await _db
        .collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['isRead'] != true) {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notifId) {
    return _db.collection('notifications').doc(notifId).delete();
  }

  Future<void> clearNotifications(String uid) async {
    final snap = await _db
        .collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Stream<QuerySnapshot> getPlots() {
    return _db.collection('plots').snapshots();
  }

  Stream<QuerySnapshot> getVerifiedDealers() {
    // The public dealer directory reads from the sanitized `dealers`
    // collection. Dealer registration documents contain private verification
    // data (CNIC/documents), so they must stay owner/admin-only.
    return _db
        .collection('dealer_registrations')
        .where('verificationStatus', isEqualTo: 'Approved')
        .snapshots();
  }

  Future<DocumentSnapshot?> getDealerRegistration(String uid) async {
    final doc =
    await _db.collection('dealer_registrations').doc(uid).get();
    return doc.exists ? doc : null;
  }

  Future<void> saveDealerRegistration(
      String uid,
      Map<String, dynamic> data,
      ) async {
    final current = await getDealerRegistration(uid);
    if (current != null) {
      throw Exception('Dealer registration has already been submitted.');
    }

    await _db.collection('dealer_registrations').doc(uid).set({
      ...data,
      'applicantId': uid,
      'verificationStatus': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
    });

    await createNotification(
      recipientId: uid,
      title: 'Dealer Registration Submitted',
      message: 'Your dealer registration is pending DHS verification.',
      type: 'verification',
      actionRoute: '/dealers',
    );
  }

  Stream<QuerySnapshot> getBallotUpdates() {
    return _db.collection('ballot_updates').snapshots();
  }

  Stream<QuerySnapshot> getBallotLiveResults() {
    return _db.collection('ballot_live_results').snapshots();
  }

  Future<DocumentSnapshot> getBallotConfig() {
    return _db.collection('ballot_config').doc('main').get();
  }

  Future<DocumentSnapshot> getPaymentConfig() {
    return _db.collection('payment_config').doc('stripe_test').get();
  }

  Future<Map<String, dynamic>> getBallotingEligibility(String uid) async {
    // Fetch the three official records in parallel so the Balloting screen
    // does not wait on three sequential Firestore reads.
    final records = await Future.wait<DocumentSnapshot?>([
      getApplication(uid),
      getUpload(uid),
      getPayment(uid),
    ]);

    final app = records[0];
    final upload = records[1];
    final payment = records[2];

    final appData = app?.data() as Map<String, dynamic>?;
    final uploadData = upload?.data() as Map<String, dynamic>?;
    final paymentData = payment?.data() as Map<String, dynamic>?;

    final appStatus = _normalizeWorkflowStatus(appData?['status']);
    final uploadStatus =
    _normalizeWorkflowStatus(uploadData?['verificationStatus']);
    final paymentStatus = _normalizeWorkflowStatus(paymentData?['status']);

    // IMPORTANT:
    // Eligibility stays backend-controlled. The applicant app never marks
    // itself eligible. Admin/official records must contain these values.
    final eligible = appStatus == 'approved' &&
        uploadStatus == 'verified' &&
        paymentStatus == 'verified';

    return {
      'eligible': eligible,
      'applicationStatus':
      appStatus.isEmpty ? 'not submitted' : appStatus,
      'documentsStatus':
      uploadStatus.isEmpty ? 'not submitted' : uploadStatus,
      'paymentStatus':
      paymentStatus.isEmpty ? 'not submitted' : paymentStatus,
    };
  }

  String _normalizeWorkflowStatus(dynamic value) {
    return value?.toString().trim().toLowerCase() ?? '';
  }

  Future<void> saveContactMessage(Map<String, dynamic> data) async {
    final uid = data['applicantId']?.toString() ?? '';

    await _db.collection('contacts').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'open',
      'source': 'applicant_app',
    });

    if (uid.isNotEmpty) {
      await createNotification(
        recipientId: uid,
        title: 'Contact Request Sent',
        message: 'Your message has been received by society support.',
        type: 'general',
        actionRoute: '/contact',
      );
    }
  }

  Future<Set<String>> getFavoritePlotIds(String uid) async {
    final doc = await getApplicant(uid);
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final raw = data['favoritePlotIds'];
    if (raw is! List) return <String>{};
    return raw.map((value) => value.toString()).toSet();
  }

  Future<void> setPlotFavourite({
    required String uid,
    required String plotId,
    required bool favourite,
  }) async {
    await _db.collection('applicants').doc(uid).update({
      'favoritePlotIds': favourite
          ? FieldValue.arrayUnion([plotId])
          : FieldValue.arrayRemove([plotId]),
    });
  }
}
