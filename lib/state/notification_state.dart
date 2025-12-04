// lib/state/notification_state.dart
import 'package:flutter/foundation.dart';

class NotificationState {
  /// Số thông báo chưa đọc
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
}
