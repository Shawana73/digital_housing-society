import 'package:flutter/material.dart';
class BaseAdminViewModel extends ChangeNotifier {
  bool isLoading = true;
  String query = '';

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 450));
    isLoading = false;
    notifyListeners();
  }

  void search(String value) {
    query = value.trim().toLowerCase();
    notifyListeners();
  }

  void clearSearch() {
    query = '';
    notifyListeners();
  }

}
