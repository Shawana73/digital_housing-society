import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/admin_models.dart';
import '../../viewmodels/admin_view_models.dart'; // for BaseAdminViewModel

class ApplicantDetailsViewModel extends BaseAdminViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Applicant? applicant;
  Map<String, dynamic>? applicantData;
  Map<String, dynamic>? applicationData;
  List<ApplicantDocument> documents = [];
  List<Map<String, dynamic>> notes = [];

  bool get hasApplication => applicationData != null;

  String get fullName => (applicantData?['fullName'] ?? applicant?.name ?? 'Not available').toString();
  String get cnic => (applicantData?['cnic'] ?? applicant?.cnic ?? 'Not available').toString();
  String get phone => (applicantData?['phone'] ?? applicationData?['contactNumber'] ?? applicant?.phone ?? 'Not available').toString();
  String get email => (applicantData?['email'] ?? applicant?.email ?? 'Not available').toString();
  String get address => (applicantData?['address'] ?? applicationData?['address'] ?? applicant?.address ?? 'Not available').toString();
  String get city => (applicantData?['city'] ?? 'Not available').toString();
  String get dateOfBirth => _formatDateValue(applicantData?['dateOfBirth']);
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

  Future<void> loadApplicant(Applicant selectedApplicant) async {
    isLoading = true;
    notifyListeners();

    applicant = selectedApplicant;
    applicantData = null;
    applicationData = null;
    documents = [];
    notes = [];

    try {
      QuerySnapshot<Map<String, dynamic>> applicantSnapshot;

      if (selectedApplicant.cnic.trim().isNotEmpty) {
        applicantSnapshot = await _firestore
            .collection('applicants')
            .where('cnic', isEqualTo: selectedApplicant.cnic.trim())
            .limit(1)
            .get();
      } else {
        applicantSnapshot = await _firestore
            .collection('applicants')
            .where('uid', isEqualTo: selectedApplicant.id)
            .limit(1)
            .get();
      }

      if (applicantSnapshot.docs.isNotEmpty) {
        final applicantDoc = applicantSnapshot.docs.first;
        applicantData = applicantDoc.data();
        final uid = applicantData?['uid']?.toString().trim();

        if (uid != null && uid.isNotEmpty) {
          final applicationSnapshot = await _firestore
              .collection('applications')
              .where('applicantId', isEqualTo: uid)
              .limit(1)
              .get();

          if (applicationSnapshot.docs.isNotEmpty) {
            applicationData = applicationSnapshot.docs.first.data();
          }
        }
      }

      documents = [];

      final uploadSnapshot = await _firestore
          .collection('uploads')
          .where('applicantId', isEqualTo: applicantData?['uid'] ?? selectedApplicant.id)
          .limit(1)
          .get();

      if (uploadSnapshot.docs.isNotEmpty) {
        final uploadData = uploadSnapshot.docs.first.data();
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
              status: 'pending',
              icon: Icons.insert_drive_file_rounded,
              verified: false,
            );
          }).toList();
        }
      }

      notes = [];
    } catch (e, stackTrace) {
      debugPrint('Error loading applicant details: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    isLoading = false;
    notifyListeners();
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

      if (applicationQuery.docs.isEmpty) {
        throw Exception('Application not found for ${applicant!.name}');
      }

      final applicationDoc = applicationQuery.docs.first;
      final batch = _firestore.batch();

      batch.update(applicationDoc.reference, {'status': firestoreStatus});
      batch.update(applicantDoc.reference, {'profileStatus': firestoreStatus});

      await batch.commit();

      applicant!.status = status;
      applicationData = {...?applicationData, 'status': firestoreStatus};

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
}