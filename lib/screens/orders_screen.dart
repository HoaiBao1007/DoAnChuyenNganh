import 'package:flutter/material.dart';

import '../models/order_response.dart';
import '../services/order_service.dart';
import '../utils/format.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _orderService = OrderService();
  List<OrderResponse> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final list = await _orderService.getMyOrders();
      if (!mounted) return;
      setState(() {
        _orders = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi tải đơn hàng: $e")),
      );
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return "";
    final two = (int n) => n.toString().padLeft(2, '0');
    return "${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đơn hàng của tôi")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? const Center(child: Text("Chưa có đơn hàng"))
          : RefreshIndicator(
        onRefresh: _loadOrders,
        child: ListView.builder(
          itemCount: _orders.length,
          itemBuilder: (_, i) {
            final o = _orders[i];
            return Card(
              margin:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text("Đơn #${o.id} - ${o.status}"),
                subtitle: Text(
                  "Тổng tiền: ${Format.currency(o.totalAmount)}\nNgày: ${o.orderDate}\n"
                      "Ngày: ${_formatDate(o.orderDate)}\n"
                      "Số sản phẩm: ${o.items.length}",
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
