import '../../models/admin_models.dart';
import '../../data/dummy_data.dart';
import '../../viewmodels/admin_view_models.dart';

class AdminDashboardViewModel extends BaseAdminViewModel {
  final stats = DummyData.dashboardStats();
  final quickActions = DummyData.quickActions();
  final activities = DummyData.activities();
  final notifications = DummyData.notifications();
  final chartValues = const [18.0, 24.0, 21.0, 32.0, 38.0, 45.0, 58.0];

  List<ActivityItem> get filteredActivities {
    if (query.isEmpty) return activities;
    return activities
        .where((a) => a.title.toLowerCase().contains(query) || a.subtitle.toLowerCase().contains(query))
        .toList();
  }

  int get unreadCount => notifications.where((n) => n.unread).length;

  void markAllRead() {
    for (final notification in notifications) {
      notification.unread = false;
    }
    notifyListeners();
  }
}