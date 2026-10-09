import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/admin_models.dart';
import '../../viewmodels/admin_view_models.dart'; // for BaseAdminViewModel
class ApplicantDetailsViewModel extends BaseAdminViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Real-time listeners
  final List<StreamSubscription> _subs = [];       // applicant doc
  final List<StreamSubscription> _childSubs = [];  // application, payment, activity, uploads
  final Set<String> _pending = {};
  String? _childKey;

  Applicant? applicant;
  Map<String, dynamic>? applicantData;
  Map<String, dynamic>? applicationData;
  Map<String, dynamic>? paymentData;
  List<ApplicantDocument> documents = [];
  List<Map<String, dynamic>> notes = [];
  List<Map<String, dynamic>> activityLogs = [];

  bool get hasApplication => applicationData != null;

  String get fullName => (applicantData?['fullName'] ?? applicant?.name ?? 'Not available').toString();
  String get cnic => (applicantData?['cnic'] ?? applicant?.cnic ?? 'Not available').toString();
  String get phone => (applicantData?['phone'] ?? applicationData?['contactNumber'] ?? applicant?.phone ?? 'Not available').toString();
  String get email => (applicantData?['email'] ?? applicant?.email ?? 'Not available').toString();
  String get address => (applicantData?['address'] ?? applicationData?['address'] ?? applicant?.address ?? 'Not available').toString();
  String get city =>
      (applicantData?['city'] ??
          applicantData?['City'] ??
          'Not available')
          .toString();
  String get dateOfBirth =>
      _formatDateValue(applicantData?['DateOfBirth'] ?? applicantData?['dateOfBirth']);
  String get profileCreatedOn => _formatDateValue(applicantData?['createdAt']);

  String get applicationId => (applicationData?['ApplicationId'] ?? applicant?.id ?? 'Not available').toString();
  String get applicationType => (applicationData?['plotType'] ?? 'Not available').toString();
  String get serialNumber => (applicationData?['serialNumber'] ?? 'Not available').toString();
  String get fee => (applicationData?['fee'] ?? 'Not available').toString();
  String get applicationStatus => (applicationData?['status'] ?? 'Pending').toString();
  String get appliedOn => _formatDateValue(applicationData?['submittedAt']);

  @override
  Future<void> load() async {
    // Applicant Details screen uses loadApplicant()
  }
  Future<void> _addActivityLog({
    required String applicantId,
    required String action,
    required String description,
    required String type,
  }) async {
    await _firestore.collection('activity_logs').add({
      'applicantId': applicantId,
      'action': action,
      'description': description,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'adminEmail': FirebaseAuth.instance.currentUser?.email ?? 'unknown',
    });
  }

  // ------------------------------------------------------------
  // REAL-TIME LISTENERS
  // ------------------------------------------------------------

  Future<void> _cancelAll() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    _cancelChildren();
  }

  void _cancelChildren() {
    for (final s in _childSubs) {
      s.cancel();
    }
    _childSubs.clear();
  }

  // Sab collections ka pehla data aane par hi loading band hoti ha
  void _markReady(String key, Completer<void> first) {
    _pending.remove(key);
    if (_pending.isEmpty) isLoading = false;
    notifyListeners();
    if (_pending.isEmpty && !first.isCompleted) first.complete();
  }

  Future<void> loadApplicant(Applicant selectedApplicant) async {
    await _cancelAll();

    isLoading = true;
    notifyListeners();

    applicant = selectedApplicant;
    applicantData = null;
    applicationData = null;
    paymentData = null;
    documents = [];
    notes = [];
    activityLogs = [];
    _childKey = null;
    _pending
      ..clear()
      ..add('applicant');

    final first = Completer<void>();

    Query<Map<String, dynamic>> applicantQuery;

    if (selectedApplicant.cnic.trim().isNotEmpty) {
      applicantQuery = _firestore
          .collection('applicants')
          .where('cnic', isEqualTo: selectedApplicant.cnic.trim())
          .limit(1);
    } else {
      applicantQuery = _firestore
          .collection('applicants')
          .where('uid', isEqualTo: selectedApplicant.id)
          .limit(1);
    }

    _subs.add(
      applicantQuery.snapshots().listen(
            (snapshot) {
          try {
            _onApplicantSnapshot(snapshot, selectedApplicant, first);
          } catch (e, stackTrace) {
            debugPrint('Error loading applicant details: $e');
            debugPrintStack(stackTrace: stackTrace);
            _markReady('applicant', first);
          }
        },
        onError: (e, stackTrace) {
          debugPrint('Error loading applicant details: $e');
          debugPrintStack(stackTrace: stackTrace);
          _markReady('applicant', first);
        },
      ),
    );

    // Pehla data aane tak loading chalti rahe
    await first.future;
  }

  void _onApplicantSnapshot(
      QuerySnapshot<Map<String, dynamic>> applicantSnapshot,
      Applicant selectedApplicant,
      Completer<void> first,
      ) {
    if (applicantSnapshot.docs.isNotEmpty) {
      final applicantDoc = applicantSnapshot.docs.first;
      applicantData = applicantDoc.data();
      final rawNotes = applicantData?['verificationNotes'];

      notes = [];
      if (rawNotes is List) {
        notes = rawNotes
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        notes.sort((a, b) {
          final aTime = a['createdAt'];
          final bTime = b['createdAt'];

          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime);
          }

          return 0;
        });
      }
    } else {
      applicantData = null;
      notes = [];
    }

    final uid = applicantData?['uid']?.toString().trim();
    final applicantId =
        applicantData?['uid']?.toString() ?? selectedApplicant.id;

    // Baqi listeners sirf tab dobara lagti hain jab uid badle
    final key = '${uid ?? ''}|$applicantId';
    if (key != _childKey) {
      _childKey = key;
      _cancelChildren();
      applicationData = null;
      paymentData = null;
      activityLogs = [];
      documents = [];

      if (uid != null && uid.isNotEmpty) {
        _listenApplication(uid, first);
        _listenPayment(uid, first);
        _listenActivity(uid, first);
      }
      _listenUploads(applicantId, selectedApplicant, first);
    }

    _markReady('applicant', first);
  }

  void _listenApplication(String uid, Completer<void> first) {
    _pending.add('application');
    _childSubs.add(
      _firestore
          .collection('applications')
          .where('applicantId', isEqualTo: uid)
          .limit(1)
          .snapshots()
          .listen(
            (snap) {
          applicationData =
          snap.docs.isNotEmpty ? snap.docs.first.data() : null;
          _markReady('application', first);
        },
        onError: (e) {
          debugPrint('Error loading application: $e');
          _markReady('application', first);
        },
      ),
    );
  }

  void _listenPayment(String uid, Completer<void> first) {
    _pending.add('payment');
    _childSubs.add(
      _firestore.collection('payments').doc(uid).snapshots().listen(
            (snap) {
          paymentData = snap.exists ? snap.data() : null;
          _markReady('payment', first);
        },
        onError: (e) {
          debugPrint('Error loading payment: $e');
          _markReady('payment', first);
        },
      ),
    );
  }

  void _listenActivity(String uid, Completer<void> first) {
    _pending.add('activity');
    _childSubs.add(
      _firestore
          .collection('activity_logs')
          .where('applicantId', isEqualTo: uid)
          .snapshots()
          .listen(
            (snap) {
          activityLogs = snap.docs.map((doc) => doc.data()).toList();

          activityLogs.sort((a, b) {
            final aTime = a['timestamp'];
            final bTime = b['timestamp'];

            if (aTime is Timestamp && bTime is Timestamp) {
              return bTime.compareTo(aTime);
            }

            return 0;
          });
          _markReady('activity', first);
        },
        onError: (e) {
          debugPrint('Error loading activity logs: $e');
          _markReady('activity', first);
        },
      ),
    );
  }

  void _listenUploads(
      String applicantId,
      Applicant selectedApplicant,
      Completer<void> first,
      ) {
    debugPrint('SELECTED APPLICANT ID: ${selectedApplicant.id}');
    debugPrint('SELECTED APPLICANT CNIC: ${selectedApplicant.cnic}');
    debugPrint('APPLICANT FIRESTORE UID: ${applicantData?['uid']}');
    debugPrint('UPLOAD DOC ID USED: $applicantId');

    _pending.add('uploads');
    _childSubs.add(
      _firestore.collection('uploads').doc(applicantId).snapshots().listen(
            (uploadDoc) {
          try {
            documents = [];
            debugPrint('ADMIN UPLOAD UID: $applicantId');
            debugPrint('ADMIN UPLOAD EXISTS: ${uploadDoc.exists}');
            debugPrint('ADMIN UPLOAD DATA: ${uploadDoc.data()}');
            if (uploadDoc.exists) {
              final uploadData = uploadDoc.data() as Map<String, dynamic>;
              final rawDocuments = uploadData['documents'];

              if (rawDocuments is List) {
                documents = rawDocuments.map<ApplicantDocument>((item) {
                  if (item is Map<String, dynamic>) {
                    final fileName = item['fileName']?.toString() ?? 'Unknown Document';
                    final fileType = item['fileType']?.toString().toLowerCase() ?? '';
                    final fileSize = item['fileSize']?.toString() ?? '';
                    final serialNumber = item['serialNumber']?.toString() ?? '';
                    final status = item['status']?.toString() ?? 'pending';

                    return ApplicantDocument(
                      title: fileName,
                      number: serialNumber,
                      fileSize: fileSize,
                      fileType: fileType,
                      fileUrl: item['fileUrl']?.toString() ?? '',
                      status: status,
                      icon: _getDocumentIcon(fileType),
                      verified: status.toLowerCase() == 'verified',
                    );
                  }
                  return const ApplicantDocument(
                    title: 'Unknown Document',
                    number: '',
                    fileSize: '',
                    fileType: '',
                    fileUrl: '',
                    status: 'pending',
                    icon: Icons.insert_drive_file_rounded,
                    verified: false,
                  );
                }).toList();
              }
            }
          } catch (e, stackTrace) {
            debugPrint('Error loading applicant details: $e');
            debugPrintStack(stackTrace: stackTrace);
          }
          _markReady('uploads', first);
        },
        onError: (e) {
          debugPrint('Error loading uploads: $e');
          _markReady('uploads', first);
        },
      ),
    );
  }

  IconData _getDocumentIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
  Future<void> updateDocumentStatus(
      int index,
      String newStatus,
      ) async {
    if (index < 0 || index >= documents.length) return;

    try {
      final applicantId =
          applicantData?['uid']?.toString() ?? applicant?.id;

      if (applicantId == null || applicantId.isEmpty) {
        throw Exception('Applicant UID not found.');
      }

      final uploadRef =
      _firestore.collection('uploads').doc(applicantId);

      final uploadSnapshot = await uploadRef.get();

      if (!uploadSnapshot.exists) {
        throw Exception('Upload record not found.');
      }

      final uploadData = uploadSnapshot.data();

      if (uploadData == null || uploadData['documents'] is! List) {
        throw Exception('No documents found.');
      }

      final updatedDocuments =
      List<Map<String, dynamic>>.from(
        (uploadData['documents'] as List).map(
              (item) => Map<String, dynamic>.from(item as Map),
        ),
      );

      if (index >= updatedDocuments.length) return;

      updatedDocuments[index]['status'] = newStatus;

      String overallStatus = 'pending';

      final statuses = updatedDocuments
          .map((doc) => doc['status']?.toString().toLowerCase())
          .toList();

      if (statuses.any((status) => status == 'rejected')) {
        overallStatus = 'rejected';
      } else if (statuses.isNotEmpty &&
          statuses.every((status) => status == 'verified')) {
        overallStatus = 'verified';
      }

      await uploadRef.update({
        'documents': updatedDocuments,
        'verificationStatus': overallStatus,
      });
      final documentName = documents[index].title;

      final action = newStatus.toLowerCase() == 'verified'
          ? 'Document verified'
          : 'Document rejected';

      final description = newStatus.toLowerCase() == 'verified'
          ? '$documentName was verified by admin.'
          : '$documentName was rejected by admin.';

      await _addActivityLog(
        applicantId: applicantId,
        action: action,
        description: description,
        type: 'document',
      );

      final oldDocument = documents[index];

      documents[index] = ApplicantDocument(
        title: oldDocument.title,
        number: oldDocument.number,
        fileSize: oldDocument.fileSize,
        fileType: oldDocument.fileType,
        fileUrl: oldDocument.fileUrl,
        status: newStatus,
        icon: oldDocument.icon,
        verified: newStatus.toLowerCase() == 'verified',
      );

      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Error updating document status: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
  Future<void> saveNote(String noteText) async {
    final applicantId =
        applicantData?['uid']?.toString() ?? applicant?.id;

    if (applicantId == null || applicantId.isEmpty) {
      throw Exception('Applicant UID not found.');
    }

    final text = noteText.trim();

    if (text.isEmpty) {
      throw Exception('Note cannot be empty.');
    }

    final currentAdminName = FirebaseAuth.instance.currentUser?.displayName
        ?? FirebaseAuth.instance.currentUser?.email?.split('@').first
        ?? 'Admin';

    final note = {
      'text': text,
      'adminName': currentAdminName,
      'createdAt': Timestamp.now(),
    };

    try {
      await _firestore
          .collection('applicants')
          .doc(applicantId)
          .update({
        'verificationNotes': FieldValue.arrayUnion([note]),
      });

      await _addActivityLog(
        applicantId: applicantId,
        action: 'Verification note added',
        description: 'Admin added a verification note.',
        type: 'verification',
      );

      // notes.insert(0, note) hata diya: ab real-time listener khud nayi
      // note list mein daal deta ha. Rehne se note do baar nazar aata.

      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Error saving verification note: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
  Future<void> editNote(int index, String newText) async {
    final applicantId = applicantData?['uid']?.toString() ?? applicant?.id;
    if (applicantId == null || applicantId.isEmpty) {
      throw Exception('Applicant UID not found.');
    }
    final text = newText.trim();
    if (text.isEmpty) {
      throw Exception('Note cannot be empty.');
    }
    if (index < 0 || index >= notes.length) return;

    final updatedNotes = List<Map<String, dynamic>>.from(notes);
    updatedNotes[index] = {
      ...updatedNotes[index],
      'text': text,
      'editedAt': Timestamp.now(),
    };

    try {
      await _firestore.collection('applicants').doc(applicantId).update({
        'verificationNotes': updatedNotes,
      });

      await _addActivityLog(
        applicantId: applicantId,
        action: 'Verification note edited',
        description: 'Admin edited a verification note.',
        type: 'verification',
      );

      notes = updatedNotes;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Error editing verification note: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> deleteNote(int index) async {
    final applicantId = applicantData?['uid']?.toString() ?? applicant?.id;
    if (applicantId == null || applicantId.isEmpty) {
      throw Exception('Applicant UID not found.');
    }
    if (index < 0 || index >= notes.length) return;

    final updatedNotes = List<Map<String, dynamic>>.from(notes)..removeAt(index);

    try {
      await _firestore.collection('applicants').doc(applicantId).update({
        'verificationNotes': updatedNotes,
      });

      await _addActivityLog(
        applicantId: applicantId,
        action: 'Verification note deleted',
        description: 'Admin deleted a verification note.',
        type: 'verification',
      );

      notes = updatedNotes;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Error deleting verification note: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> updateStatus(VerificationStatus status) async {
    if (applicant == null) return;

    try {
      String firestoreStatus;
      switch (status) {
        case VerificationStatus.verified:
          firestoreStatus = 'Verified';
          break;
        case VerificationStatus.rejected:
          firestoreStatus = 'Rejected';
          break;
        case VerificationStatus.pending:
          firestoreStatus = 'Pending';
          break;
      }

      final applicantQuery = await _firestore
          .collection('applicants')
          .where('cnic', isEqualTo: applicant!.cnic)
          .limit(1)
          .get();

      if (applicantQuery.docs.isEmpty) {
        throw Exception('Applicant not found for ${applicant!.name}');
      }

      final applicantDoc = applicantQuery.docs.first;
      final applicantFirestoreData = applicantDoc.data();
      final uid = applicantFirestoreData['uid']?.toString().trim();

      if (uid == null || uid.isEmpty) {
        throw Exception('Applicant UID not found for ${applicant!.name}');
      }

      final applicationQuery = await _firestore
          .collection('applications')
          .where('applicantId', isEqualTo: uid)
          .limit(1)
          .get();

      final batch = _firestore.batch();
      batch.update(applicantDoc.reference, {'profileStatus': firestoreStatus});

      if (applicationQuery.docs.isNotEmpty) {
        batch.update(applicationQuery.docs.first.reference, {'status': firestoreStatus});
      }

      await batch.commit();

      applicant!.status = status;
      applicationData = {...?applicationData, 'status': firestoreStatus};

      final action = status == VerificationStatus.verified
          ? 'Applicant verified'
          : status == VerificationStatus.rejected
          ? 'Applicant rejected'
          : 'Applicant status changed';

      final description = status == VerificationStatus.verified
          ? 'Admin verified the applicant profile.'
          : status == VerificationStatus.rejected
          ? 'Admin rejected the applicant profile.'
          : 'Applicant verification status was changed.';

      await _addActivityLog(
        applicantId: uid,
        action: action,
        description: description,
        type: 'verification',
      );

      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Error updating applicant status: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  String _formatDateValue(dynamic value) {
    if (value == null) return 'Not available';

    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year}';
    }

    if (value is DateTime) {
      return '${value.day.toString().padLeft(2, '0')} ${_monthName(value.month)} ${value.year}';
    }

    final stringValue = value.toString().trim();
    return stringValue.isEmpty ? 'Not available' : stringValue;
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _cancelChildren();
    super.dispose();
  }
}