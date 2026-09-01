import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';

void showAdminSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        margin: const EdgeInsets.all(18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: AdminColors.darkText,
        behavior: SnackBarBehavior.floating,
      ),
    );
}
