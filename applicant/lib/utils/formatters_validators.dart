import 'package:flutter/services.dart';

class Validators {
  Validators._();

  static String? required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Full name is required';
    if (v.length < 2 || v.length > 60) {
      return 'Full name must be between 2 and 60 characters';
    }
    if (!RegExp(r"^[A-Za-z][A-Za-z .'-]*$").hasMatch(v)) {
      return 'Full name can contain letters, spaces, apostrophe, dot or hyphen only';
    }
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
    if (!RegExp(r'^03\d{9}$').hasMatch(digits)) {
      return 'Enter Pakistani phone number 03XX-XXXXXXX';
    }
    return null;
  }

  static String? companyName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Company name is required';
    if (v.length < 2 || v.length > 100) {
      return 'Company name must be between 2 and 100 characters';
    }
    if (!RegExp(r"[A-Za-z]").hasMatch(v)) {
      return 'Company name must contain letters';
    }
    if (!RegExp(r"^[A-Za-z0-9 .,&'()/-]+$").hasMatch(v)) {
      return 'Company name contains invalid characters';
    }
    return null;
  }

  static String? ntn(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'NTN number is required';
    final compact = v.replaceAll(' ', '');
    if (!RegExp(r'^\d{7}(-\d)?$').hasMatch(compact)) {
      return 'Enter a valid NTN, e.g. 1234567-8';
    }
    return null;
  }

  static String? address(String? value, {String label = 'Address'}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$label is required';
    if (v.length < 5) return '$label is too short';
    if (v.length > 180) return '$label is too long';
    if (!RegExp(r'[A-Za-z]').hasMatch(v)) {
      return '$label must contain letters';
    }
    return null;
  }

  static String? area(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Area is required';
    if (v.length < 2 || v.length > 80) {
      return 'Area must be between 2 and 80 characters';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(v)) {
      return 'Area must contain letters';
    }
    return null;
  }

  static String? fixedDigits(String? value, String label, int length) {
    final digits = onlyDigits(value ?? '');
    if (digits.length != length) return '$label must be exactly $length digits';
    return null;
  }

  static String? nonNegativeNumber(String? value, String label) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$label is required';
    final number = num.tryParse(v);
    if (number == null) return 'Enter a valid $label';
    if (number < 0) return '$label cannot be negative';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v)) {
      return 'Password must include 1 uppercase letter';
    }
    if (!RegExp(r'\d').hasMatch(v)) return 'Password must include 1 number';
    return null;
  }

  static String onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');
}

class CnicInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = Validators.onlyDigits(newValue.text);
    final clipped = digits.length > 13 ? digits.substring(0, 13) : digits;
    String formatted = clipped;
    if (clipped.length > 5 && clipped.length <= 12) {
      formatted = '${clipped.substring(0, 5)}-${clipped.substring(5)}';
    } else if (clipped.length > 12) {
      formatted = '${clipped.substring(0, 5)}-${clipped.substring(5, 12)}-${clipped.substring(12)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PakistaniPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = Validators.onlyDigits(newValue.text);
    final clipped = digits.length > 11 ? digits.substring(0, 11) : digits;
    String formatted = clipped;
    if (clipped.length > 4) {
      formatted = '${clipped.substring(0, 4)}-${clipped.substring(4)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class DigitsOnlyLengthFormatter extends TextInputFormatter {
  DigitsOnlyLengthFormatter(this.maxLength);

  final int maxLength;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = Validators.onlyDigits(newValue.text);
    final clipped = digits.length > maxLength
        ? digits.substring(0, maxLength)
        : digits;
    return TextEditingValue(
      text: clipped,
      selection: TextSelection.collapsed(offset: clipped.length),
    );
  }
}
