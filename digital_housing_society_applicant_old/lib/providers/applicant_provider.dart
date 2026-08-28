import 'package:flutter/foundation.dart';
import '../models/applicant_model.dart';
import '../models/application_model.dart';
import '../models/payment_model.dart';
import '../services/firestore_service.dart';

class ApplicantProvider extends ChangeNotifier {
  ApplicantProvider({FirestoreService? firestoreService}) : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  ApplicantModel? currentApplicant;
  ApplicationModel? currentApplication;
  PaymentModel? currentPayment;
  bool isLoading = false;
  String? error;

  Future<void> loadApplicantData(String uid) async {
    setLoading(true);
    try {
      final doc = await _firestoreService.getApplicant(uid);
      if (doc.exists) currentApplicant = ApplicantModel.fromFirestore(doc);
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadApplicationData(String uid) async {
    setLoading(true);
    try {
      final doc = await _firestoreService.getApplication(uid);
      currentApplication = doc == null ? null : ApplicationModel.fromFirestore(doc);
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadPaymentData(String uid) async {
    setLoading(true);
    try {
      final doc = await _firestoreService.getPayment(uid);
      currentPayment = doc == null ? null : PaymentModel.fromFirestore(doc);
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadAll(String uid) async {
    setLoading(true);
    try {
      final applicantDoc = await _firestoreService.getApplicant(uid);
      final applicationDoc = await _firestoreService.getApplication(uid);
      final paymentDoc = await _firestoreService.getPayment(uid);
      currentApplicant = applicantDoc.exists ? ApplicantModel.fromFirestore(applicantDoc) : null;
      currentApplication = applicationDoc == null ? null : ApplicationModel.fromFirestore(applicationDoc);
      currentPayment = paymentDoc == null ? null : PaymentModel.fromFirestore(paymentDoc);
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      setLoading(false);
    }
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
