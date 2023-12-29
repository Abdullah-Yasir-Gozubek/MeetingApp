import 'package:flutter/foundation.dart';
import 'package:flutter_login_screen/model/notification.dart';

class NotificationProvider extends ChangeNotifier {
  Map<String, AppNotification> _notifications = {};

  NotificationProvider() {
    _notifications.clear();
  }

  Map<String, AppNotification> get notifications => _notifications;

  void addNotification(String id, AppNotification notification) {
    _notifications[id] = notification;
    notifyListeners();
  }

  void removeNotification(String id) {
    _notifications.remove(id);
    notifyListeners(); // Inform the UI of the change
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }
}
