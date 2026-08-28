import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const Map<String, dynamic> defaultPaymentConfig = {
    'bankName': 'HBL',
    'accountTitle': 'Digital Housing Society',
    'accountNumber': '0000-000000-000',
    'iban': 'PK00 HABB 0000 0000 0000 0000',
  };

  static Map<String, dynamic> defaultBallotConfig() {
    return {
      'status': 'upcoming',
      'drawDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
    };
  }


  Future<void> saveApplicant(Map<String, dynamic> data) async {
    final uid = data['uid']?.toString();
    if (uid == null || uid.isEmpty) throw Exception('Applicant uid is required.');
    await _db.collection('applicants').doc(uid).set(data, SetOptions(merge: true));
    try {
      await _db.collection('notifications').add({
        'recipientId': uid,
        'title': 'Welcome to Digital Housing Society',
        'message': 'Your applicant profile has been created successfully.',
        'type': 'application',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Notification creation should not block registration.
    }
  }

  Future<DocumentSnapshot> getApplicant(String uid) {
    return _db.collection('applicants').doc(uid).get();
  }

  Future<void> updateApplicant(String uid, Map<String, dynamic> data) {
    return _db.collection('applicants').doc(uid).set(data, SetOptions(merge: true));
  }

  Future<DocumentReference> saveApplication(Map<String, dynamic> data) {
    return _db.collection('applications').add(data);
  }

  Future<DocumentSnapshot?> getApplication(String applicantId) async {
    final snap = await _db.collection('applications').where('applicantId', isEqualTo: applicantId).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first;
  }

  Future<void> saveUpload(Map<String, dynamic> data) async {
    final applicantId = data['applicantId']?.toString();
    if (applicantId == null || applicantId.isEmpty) throw Exception('Applicant id is required.');
    await _db.collection('uploads').doc(applicantId).set(data, SetOptions(merge: true));
  }

  Future<DocumentSnapshot?> getUpload(String applicantId) async {
    final doc = await _db.collection('uploads').doc(applicantId).get();
    return doc.exists ? doc : null;
  }

  Future<DocumentReference> savePayment(Map<String, dynamic> data) {
    return _db.collection('payments').add(data);
  }

  Future<DocumentSnapshot?> getPayment(String applicantId) async {
    final snap = await _db.collection('payments').where('applicantId', isEqualTo: applicantId).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first;
  }

  Future<DocumentSnapshot?> getResult(String cnic) async {
    final snap = await _db.collection('ballot_results').where('cnic', isEqualTo: cnic).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first;
  }

  Stream<QuerySnapshot> getNotifications(String uid) {
    return _db.collection('notifications').where('recipientId', isEqualTo: uid).snapshots();
  }

  Future<void> markNotificationRead(String notifId) {
    return _db.collection('notifications').doc(notifId).update({'isRead': true});
  }

  Future<void> markAllNotificationsRead(String uid) async {
    final snap = await _db.collection('notifications').where('recipientId', isEqualTo: uid).where('isRead', isEqualTo: false).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notifId) {
    return _db.collection('notifications').doc(notifId).delete();
  }

  Stream<QuerySnapshot> getPlots() {
    return _db.collection('plots').snapshots();
  }

  Stream<QuerySnapshot> getBallotUpdates() {
    return _db.collection('ballot_updates').snapshots();
  }

  Future<DocumentSnapshot> getBallotConfig() {
    return _db.collection('ballot_config').doc('main').get();
  }

  Future<DocumentSnapshot> getPaymentConfig() {
    return _db.collection('payment_config').doc('hbl').get();
  }

  Future<void> registerForBalloting(String uid) {
    return _db.collection('applicants').doc(uid).set({
      'ballotingRegistered': true,
      'ballotingRegisteredAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
