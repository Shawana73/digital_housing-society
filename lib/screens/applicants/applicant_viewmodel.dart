import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../viewmodels/admin_view_models.dart'; // for BaseAdminViewModel

class ApplicantVerificationViewModel extends BaseAdminViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Applicant> applicants = [];
  String selectedFilter = 'All';

  List<String> get filters => ['All', 'Pending', 'Verified', 'Rejected'];

  List<Applicant> get filteredApplicants {
    return applicants.where((applicant) {
      final searchText = query.trim().toLowerCase();

      final matchesQuery = searchText.isEmpty ||
          applicant.name.toLowerCase().contains(searchText) ||
          applicant.cnic.toLowerCase().contains(searchText) ||
          applicant.phone.toLowerCase().contains(searchText) ||
          applicant.email.toLowerCase().contains(searchText);

      final matchesFilter = selectedFilter == 'All' || applicant.status.label == selectedFilter;

      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      final applicantsSnapshot = await _firestore.collection('applicants').get();
      final applicationsSnapshot = await _firestore.collection('applications').get();

      final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>> applicationByApplicantId = {};

      for (final doc in applicationsSnapshot.docs) {
        final data = doc.data();
        final applicantId = data['applicantId']?.toString().trim();
        if (applicantId != null && applicantId.isNotEmpty) {
          applicationByApplicantId[applicantId] = doc;
        }
      }

      final loadedApplicants = <Applicant>[];

      for (final applicantDoc in applicantsSnapshot.docs) {
        final data = applicantDoc.data();
        final uid = data['uid']?.toString().trim();
        if (uid == null || uid.isEmpty) continue;

        final applicationDoc = applicationByApplicantId[uid];
        final applicationData = applicationDoc?.data();

        final name = data['fullName']?.toString().trim() ?? 'Unknown Applicant';
        final cnic = data['cnic']?.toString().trim() ?? '';
        final phone = data['phone']?.toString().trim() ?? applicationData?['contactNumber']?.toString().trim() ?? '';
        final email = data['email']?.toString().trim() ?? '';
        final address = data['address']?.toString().trim() ?? applicationData?['address']?.toString().trim() ?? '';
        final status = _parseVerificationStatus(applicationData?['status']);

        loadedApplicants.add(
          Applicant(
            id: applicationData?['ApplicationId']?.toString().trim() ?? uid,
            name: name,
            cnic: cnic,
            phone: phone,
            email: email,
            address: address,
            occupation: '',
            avatarLetters: _getAvatarLetters(name),
            documents: const [],
            status: status,
          ),
        );
      }

      applicants = loadedApplicants;
      debugPrint('Applicant Verification: ${applicants.length} applicants loaded.');
    } catch (e, stackTrace) {
      debugPrint('Error loading applicants: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    isLoading = false;
    notifyListeners();
  }

  VerificationStatus _parseVerificationStatus(dynamic value) {
    final status = value?.toString().trim().toLowerCase();
    switch (status) {
      case 'verified':
      case 'approved':
        return VerificationStatus.verified;
      case 'rejected':
      case 'reject':
        return VerificationStatus.rejected;
      case 'pending':
      case 'submitted':
      case 'under review':
      case 'under_review':
      case '':
      case null:
        return VerificationStatus.pending;
      default:
        return VerificationStatus.pending;
    }
  }

  void setFilter(String value) {
    selectedFilter = value;
    notifyListeners();
  }

  Future<void> approve(Applicant applicant) async {
    await _updateApplicationStatus(applicant, VerificationStatus.verified);
  }

  Future<void> reject(Applicant applicant) async {
    await _updateApplicationStatus(applicant, VerificationStatus.rejected);
  }

  Future<void> _updateApplicationStatus(Applicant applicant, VerificationStatus newStatus) async {
    try {
      final newStatusLabel = newStatus.label;

      final applicantQuery = await _firestore
          .collection('applicants')
          .where('cnic', isEqualTo: applicant.cnic)
          .limit(1)
          .get();

      if (applicantQuery.docs.isEmpty) {
        throw Exception('Applicant not found for ${applicant.name}');
      }

      final applicantDoc = applicantQuery.docs.first;
      final applicantData = applicantDoc.data();
      final uid = applicantData['uid']?.toString().trim();

      if (uid == null || uid.isEmpty) {
        throw Exception('Applicant UID not found for ${applicant.name}');
      }

      final applicationQuery = await _firestore
          .collection('applications')
          .where('applicantId', isEqualTo: uid)
          .limit(1)
          .get();

      if (applicationQuery.docs.isEmpty) {
        throw Exception('Application not found for ${applicant.name}');
      }

      final applicationDoc = applicationQuery.docs.first;
      final batch = _firestore.batch();

      batch.update(applicationDoc.reference, {'status': newStatusLabel});
      batch.update(applicantDoc.reference, {'profileStatus': newStatusLabel});

      await batch.commit();

      applicant.status = newStatus;
      notifyListeners();

      debugPrint('${applicant.name} status updated successfully to $newStatusLabel');
    } catch (e, stackTrace) {
      debugPrint('FIRESTORE UPDATE ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  String _getAvatarLetters(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}