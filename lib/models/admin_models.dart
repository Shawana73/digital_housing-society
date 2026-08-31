import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';

enum VerificationStatus { pending, verified, rejected }
enum PaymentStatus { pending, verified, rejected }
enum PlotStatus { available, booked, allocated }
enum BallotingLiveStatus { ready, running, paused, stopped, completed }

extension VerificationStatusX on VerificationStatus {
  String get label {
    switch (this) {
      case VerificationStatus.pending:
        return 'Pending';
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case VerificationStatus.pending:
        return AdminColors.warning;
      case VerificationStatus.verified:
        return AdminColors.success;
      case VerificationStatus.rejected:
        return AdminColors.rejected;
    }
  }
}

extension PaymentStatusX on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.verified:
        return 'Verified';
      case PaymentStatus.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case PaymentStatus.pending:
        return AdminColors.warning;
      case PaymentStatus.verified:
        return AdminColors.success;
      case PaymentStatus.rejected:
        return AdminColors.rejected;
    }
  }
}

extension PlotStatusX on PlotStatus {
  String get label {
    switch (this) {
      case PlotStatus.available:
        return 'Available';
      case PlotStatus.booked:
        return 'Booked';
      case PlotStatus.allocated:
        return 'Allocated';
    }
  }

  Color get color {
    switch (this) {
      case PlotStatus.available:
        return AdminColors.success;
      case PlotStatus.booked:
        return AdminColors.warning;
      case PlotStatus.allocated:
        return AdminColors.primary;
    }
  }
}

class DashboardStat {
  final String title;
  final String value;
  final String trend;
  final IconData icon;
  final Color color;
  final String route;

  const DashboardStat({
    required this.title,
    required this.value,
    required this.trend,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final List<Color> colors;

  const QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.colors,
  });
}

class ActivityItem {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final bool positive;

  const ActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.positive,
  });
}

class ApplicantDocument {
  final String title;
  final String number;
  final String fileSize;
  final String fileType;
  final String status;
  final IconData icon;
  final bool verified;

  const ApplicantDocument({
    required this.title,
    required this.number,
    required this.fileSize,
    required this.fileType,
    required this.status,
    required this.icon,
    required this.verified,
  });
}

class Applicant {
  final String id;
  final String name;
  final String cnic;
  final String phone;
  final String email;
  final String address;
  final String occupation;
  final String avatarLetters;
  final List<ApplicantDocument> documents;
  VerificationStatus status;

  Applicant({
    required this.id,
    required this.name,
    required this.cnic,
    required this.phone,
    required this.email,
    required this.address,
    required this.occupation,
    required this.avatarLetters,
    required this.documents,
    required this.status,
  });
}

class PaymentRecord {
  final String id;
  final String applicantName;
  final String transactionId;
  final String amount;
  final String date;
  final String method;
  final String receiptNo;
  PaymentStatus status;

  PaymentRecord({
    required this.id,
    required this.applicantName,
    required this.transactionId,
    required this.amount,
    required this.date,
    required this.method,
    required this.receiptNo,
    required this.status,
  });
}

class SocietyPlot {
  final String id;
  final String size;
  final String location;
  final String price;
  final String description;
  PlotStatus status;

  SocietyPlot({
    required this.id,
    required this.size,
    required this.location,
    required this.price,
    required this.description,
    required this.status,
  });
}

class Dealer {
  final String id;
  final String name;
  final String cnic;
  final String phone;
  final String agency;
  final String city;
  VerificationStatus status;

  Dealer({
    required this.id,
    required this.name,
    required this.cnic,
    required this.phone,
    required this.agency,
    required this.city,
    required this.status,
  });
}

class BallotingResult {
  final String applicantName;
  final String cnic;
  final String plotNo;
  final String category;
  final bool selected;

  const BallotingResult({
    required this.applicantName,
    required this.cnic,
    required this.plotNo,
    required this.category,
    required this.selected,
  });
}

class AdminNotification {
  final String id;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  bool unread;

  AdminNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.unread,
  });
}

class ReportCardModel {
  final String title;
  final String subtitle;
  final String fileType;
  final IconData icon;
  final Color color;
  final int count;

  const ReportCardModel({
    required this.title,
    required this.subtitle,
    required this.fileType,
    required this.icon,
    required this.color,
    required this.count,
  });
}
