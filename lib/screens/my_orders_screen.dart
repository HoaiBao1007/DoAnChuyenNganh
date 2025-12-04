// lib/screens/my_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/order_response.dart';
import '../services/order_service.dart';
import '../utils/format.dart';           // ⬅ thêm để dùng Format.currency
import 'order_detail_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  final String? statusFilter;   // PENDING / SHIPPING / DELIVERED / CANCELLED
  final String? titleOverride;  // để đổi title cho 4 màn con

  const MyOrdersScreen({
    super.key,
    this.statusFilter,
    this.titleOverride,
  });

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final OrderService _orderService = OrderService();

  bool _loading = false;
  String? _error;
  List<OrderResponse> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  /// Map status thật của đơn hàng sang nhóm tab
  /// - PENDING     -> PENDING (chờ xác nhận)
  /// - CONFIRMED   -> SHIPPING (chờ giao)
  /// - DELIVERED   -> DELIVERED (đã giao)
  /// - CANCELLED   -> CANCELLED (đã hủy)
  String _mapStatusToTab(String rawStatus) {
    final s = rawStatus.toUpperCase();
    switch (s) {
      case 'PENDING':
        return 'PENDING';
      case 'CONFIRMED':
        return 'SHIPPING';
      case 'DELIVERED':
        return 'DELIVERED';
      case 'CANCELLED':
        return 'CANCELLED';
      default:
        return s;
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // luôn lấy hết đơn từ server
      final allOrders = await _orderService.getMyOrders();

      // nếu có filter → lọc lại trên client
      List<OrderResponse> filtered = allOrders;
      if (widget.statusFilter != null) {
        filtered = allOrders
            .where((o) => _mapStatusToTab(o.status) == widget.statusFilter)
            .toList();
      }

      // 🔽 SẮP XẾP NGƯỢC LẠI: mới nhất lên trên
      filtered.sort((a, b) {
        final ad = a.orderDate;
        final bd = b.orderDate;

        if (ad == null && bd == null) {
          // nếu không có ngày thì sort theo id giảm dần
          return b.id.compareTo(a.id);
        }
        if (ad == null) return 1;   // đơn không có ngày xuống dưới
        if (bd == null) return -1;

        // ngày mới hơn (lớn hơn) đứng trước
        return bd.compareTo(ad);
      });

      if (!mounted) return;
      setState(() {
        _orders = filtered;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titleOverride ?? 'Đơn hàng của tôi'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(
            child: Text(
              'Lỗi: $_error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    if (_orders.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(
            child: Text(
              'Không có đơn hàng phù hợp',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _orders.length,
      itemBuilder: (_, i) {
        final o = _orders[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(order: o),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Đơn #${o.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(o.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          o.status,
                          style: TextStyle(
                            fontSize: 12,
                            color: _statusColor(o.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(o.orderDate),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),

                  // ⬇ Dùng FINAL_AMOUNT thay vì totalAmount
                  Text(
                    'Tổng: ${Format.currency(o.finalAmount)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),

                  const SizedBox(height: 4),
                  Text(
                    '${o.items.length} sản phẩm',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
