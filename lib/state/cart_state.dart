// lib/state/cart_state.dart
import 'package:flutter/foundation.dart';

class CartState {
  /// Số lượng sản phẩm trong giỏ (tổng quantity)
  static final ValueNotifier<int> cartCount = ValueNotifier<int>(0);
}
