import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../viewmodels/admin_view_models.dart'; // for BaseAdminViewModel

class ApplicantVerificationViewModel extends BaseAdminViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Applicant> applicants = [];
  String selectedFilter = 'All';
  String sortOption = 'Name (A-Z)';

  List<String> get sortOptions => ['Name (A-Z)', 'Name (Z-A)', 'Status'];

  List<String> get filters => ['All', 'Pending', 'Verified', 'Rejected'];

  List<Applicant> get filteredApplicants {
    final result = applicants.where((applicant) {
      final searchText = query.trim().toLowerCase();

      final matchesQuery = searchText.isEmpty ||
          applicant.name.toLowerCase().contains(searchText) ||
          applicant.cnic.toLowerCase().contains(searchText) ||
          applicant.phone.toLowerCase().contains(searchText) ||
          applicant.email.toLowerCase().contains(searchText);

      final matchesFilter = selectedFilter == 'All' || applicant.status.label == selectedFilter;

      return matchesQuery && matchesFilter;
    }).toList();

    switch (sortOption) {
      case 'Name (Z-A)':
        result.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 'Status':
        result.sort((a, b) => a.status.label.compareTo(b.status.label));
        break;
      case 'Name (A-Z)':
      default:
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    return result;
  }

  void setSortOption(String value) {
    sortOption = value;
    notifyListeners();
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
        final status = _parseVerificationStatus(applicationData?['status'] ?? data['profileStatus']);

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


  String _getAvatarLetters(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}