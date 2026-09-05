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

    await _db.runTransaction((tx) async {
      final registryRef = _db.collection('cnic_registry').doc(cnicDigits);
      final existing = await tx.get(registryRef);

      if (existing.exists) {
        final owner =
        existing.data()?['uid']?.toString();
        if (owner != uid) {
          throw Exception('An account with this CNIC already exists.');
        }
      }

      tx.set(
        registryRef,
        {
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      tx.set(
        _db.collection('applicants').doc(uid),
        {
          ...data,
          'uid': uid,
          'cnicDigits': cnicDigits,
        },
        SetOptions(merge: true),
      );
    });

    await createNotification(
      recipientId: uid,
      title: 'Welcome to Digital Housing Society',
      message: 'Your applicant profile has been created successfully.',
      type: 'application',
    );
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
    return _db
        .collection('dealers')
        .where('verificationStatus', isEqualTo: 'verified')
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
