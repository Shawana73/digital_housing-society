import 'package:flutter/services.dart';

class Validators {
  Validators._();

  static String? required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final reg = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!reg.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? cnic(String? value) {
    final digits = onlyDigits(value ?? '');
    if (digits.length != 13) return 'CNIC must be exactly 13 digits';
    return null;
  }

  static String? phone(String? value) {
    final digits = onlyDigits(value ?? '');
    if (!RegExp(r'^03\d{9}$').hasMatch(digits)) return 'Enter Pakistani phone number 03XX-XXXXXXX';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Password must include 1 uppercase letter';
    if (!RegExp(r'\d').hasMatch(v)) return 'Password must include 1 number';
    return null;
  }

  static String onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');
}

class CnicInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = Validators.onlyDigits(newValue.text);
    final clipped = digits.length > 13 ? digits.substring(0, 13) : digits;
    String formatted = clipped;
    if (clipped.length > 5 && clipped.length <= 12) {
      formatted = '${clipped.substring(0, 5)}-${clipped.substring(5)}';
    } else if (clipped.length > 12) {
      formatted = '${clipped.substring(0, 5)}-${clipped.substring(5, 12)}-${clipped.substring(12)}';
    }
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

class PakistaniPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = Validators.onlyDigits(newValue.text);
    final clipped = digits.length > 11 ? digits.substring(0, 11) : digits;
    String formatted = clipped;
    if (clipped.length > 4) formatted = '${clipped.substring(0, 4)}-${clipped.substring(4)}';
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}
