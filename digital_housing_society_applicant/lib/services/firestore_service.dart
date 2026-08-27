import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const Map<String, dynamic> defaultPaymentConfig = {
    'bankName': 'Stripe Test Mode',
    'accountTitle': 'Digital Housing Society',
    'accountNumber': 'Test card: 4242 4242 4242 4242',
    'iban': 'Use any future expiry date and any CVC for test simulation',
  };

  static Map<String, dynamic> defaultBallotConfig() {
    return {
      'status': 'upcoming',
      'drawDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
      'totalApplicants': 0,
      'totalWinners': 0,
      'displayNumbers': <String>[],
      'message': 'Balloting schedule will be announced by the society office.',
    };
  }

  Future<void> ensureCoreCollections(String uid) async {
    final batch = _db.batch();
    batch.set(_db.collection('app_metadata').doc('collections'), {
      'applicants': true,
      'applications': true,
      'uploads': true,
      'payments': true,
      'notifications': true,
      'contacts': true,
      'ballot_results': true,
      'ballot_updates': true,
      'ballot_live_results': true,
      'plots': true,
      'lastCheckedBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(_db.collection('payment_config').doc('stripe_test'), {
      ...defaultPaymentConfig,
      'mode': 'test',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    // ballot_config/main is intentionally not overwritten here. The society admin controls its status.
    await batch.commit();
  }

  Future<void> saveApplicant(Map<String, dynamic> data) async {
    final uid = data['uid']?.toString();
    if (uid == null || uid.isEmpty) throw Exception('Applicant uid is required.');
    await _db.collection('applicants').doc(uid).set(data, SetOptions(merge: true));
    await ensureCoreCollections(uid);
    await createNotification(
      recipientId: uid,
      title: 'Welcome to Digital Housing Society',
      message: 'Your applicant profile has been created successfully.',
      type: 'application',
    );
  }

  Future<DocumentSnapshot> getApplicant(String uid) => _db.collection('applicants').doc(uid).get();

  Future<void> updateApplicant(String uid, Map<String, dynamic> data) {
    return _db.collection('applicants').doc(uid).set({...data, 'uid': uid}, SetOptions(merge: true));
  }

  Future<DocumentReference> saveApplication(Map<String, dynamic> data) async {
    final applicantId = data['applicantId']?.toString();
    if (applicantId == null || applicantId.isEmpty) throw Exception('Applicant id is required.');
    final ref = _db.collection('applications').doc();
    await ref.set({...data, 'applicationId': ref.id}, SetOptions(merge: true));
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
    // Single-field query only. Sorting is done client-side to avoid Firestore composite index errors.
    final snap = await _db.collection('applications').where('applicantId', isEqualTo: applicantId).limit(20).get();
    if (snap.docs.isEmpty) return null;
    final docs = [...snap.docs];
    docs.sort((a, b) {
      final av = (a.data())['submittedAt'];
      final bv = (b.data())['submittedAt'];
      final at = av is Timestamp ? av.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
      final bt = bv is Timestamp ? bv.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
    return docs.first;
  }

  Stream<QuerySnapshot> getMyApplications(String applicantId) {
    return _db.collection('applications').where('applicantId', isEqualTo: applicantId).snapshots();
  }

  Future<void> updateApplication(String id, Map<String, dynamic> data) {
    return _db.collection('applications').doc(id).set(data, SetOptions(merge: true));
  }

  Future<void> deleteApplication(String id) => _db.collection('applications').doc(id).delete();

  Future<void> saveUpload(Map<String, dynamic> data) async {
    final applicantId = data['applicantId']?.toString();
    if (applicantId == null || applicantId.isEmpty) throw Exception('Applicant id is required.');
    await _db.collection('uploads').doc(applicantId).set(data, SetOptions(merge: true));
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

  Future<DocumentReference> savePayment(Map<String, dynamic> data) async {
    final applicantId = data['applicantId']?.toString();
    if (applicantId == null || applicantId.isEmpty) throw Exception('Applicant id is required.');
    final ref = _db.collection('payments').doc(applicantId);
    await ref.set(data, SetOptions(merge: true));
    await createNotification(
      recipientId: applicantId,
      title: 'Payment Submitted',
      message: 'Your payment reference has been saved and is pending verification.',
      type: 'payment',
      actionRoute: '/payment',
    );
    return ref;
  }

  Future<DocumentSnapshot?> getPayment(String applicantId) async {
    final doc = await _db.collection('payments').doc(applicantId).get();
    return doc.exists ? doc : null;
  }

  Future<DocumentSnapshot?> getResult(String cnic) async {
    final snap = await _db.collection('ballot_results').where('cnic', isEqualTo: cnic).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first;
  }

  Future<DocumentSnapshot?> getResultForApplicant(String applicantId) async {
    final direct = await _db.collection('ballot_results').doc(applicantId).get();
    if (direct.exists) return direct;
    final snap = await _db.collection('ballot_results').where('applicantId', isEqualTo: applicantId).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first;
  }

  Stream<QuerySnapshot> getNotifications(String uid) {
    return _db.collection('notifications').where('recipientId', isEqualTo: uid).snapshots();
  }

  Future<void> createNotification({required String recipientId, required String title, required String message, required String type, String? actionRoute}) {
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
    return _db.collection('notifications').doc(notifId).update({'isRead': true});
  }

  Future<void> markAllNotificationsRead(String uid) async {
    final snap = await _db.collection('notifications').where('recipientId', isEqualTo: uid).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['isRead'] != true) batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notifId) => _db.collection('notifications').doc(notifId).delete();

  Future<void> clearNotifications(String uid) async {
    final snap = await _db.collection('notifications').where('recipientId', isEqualTo: uid).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Stream<QuerySnapshot> getPlots() => _db.collection('plots').snapshots();

  Stream<QuerySnapshot> getBallotUpdates() => _db.collection('ballot_updates').snapshots();

  Stream<QuerySnapshot> getBallotLiveResults() => _db.collection('ballot_live_results').snapshots();

  Future<DocumentSnapshot> getBallotConfig() => _db.collection('ballot_config').doc('main').get();

  Future<DocumentSnapshot> getPaymentConfig() => _db.collection('payment_config').doc('stripe_test').get();

  Future<void> registerForBalloting(String uid) async {
    await _db.collection('applicants').doc(uid).set({
      'uid': uid,
      'ballotingRegistered': true,
      'ballotingRegisteredAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await createNotification(
      recipientId: uid,
      title: 'Balloting Registered',
      message: 'You are registered for the upcoming digital balloting.',
      type: 'ballot',
      actionRoute: '/balloting',
    );
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

  Future<void> saveSignupOtp({required String email, required String otp}) {
    return _db.collection('signup_otps').doc(email.trim().toLowerCase()).set({
      'email': email.trim().toLowerCase(),
      'otp': otp,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 10))),
      'verified': false,
    }, SetOptions(merge: true));
  }

  Future<bool> verifySignupOtp({required String email, required String otp}) async {
    final ref = _db.collection('signup_otps').doc(email.trim().toLowerCase());
    final doc = await ref.get();
    final data = doc.data();
    if (data == null) return false;
    final expiry = data['expiresAt'];
    final expired = expiry is Timestamp && expiry.toDate().isBefore(DateTime.now());
    final ok = data['otp']?.toString() == otp.trim() && !expired;
    if (ok) await ref.set({'verified': true, 'verifiedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    return ok;
  }
}
