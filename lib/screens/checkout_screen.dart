// lib/screens/checkout_screen.dart

import 'package:flutter/material.dart';

import '../models/create_order_request.dart';
import '../models/cart_response.dart';
import '../services/order_service.dart';

class CheckoutScreen extends StatefulWidget {
  /// Danh sách sản phẩm được chọn trong giỏ hàng để thanh toán
  final List<CartItem> selectedItems;

  const CheckoutScreen({
    super.key,
    required this.selectedItems,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderService = OrderService();

  bool _submitting = false;

  // SHIPPING
  final _shippingAddress1Ctrl = TextEditingController(text: "123 Đường ABC");
  final _shippingAddress2Ctrl = TextEditingController(text: "Chung cư ABC");
  final _shippingCityCtrl = TextEditingController(text: "TP.HCM");
  final _shippingPostalCtrl = TextEditingController(text: "700000");

  // BILLING
  final _billingAddress1Ctrl = TextEditingController(text: "456 Đường DEF");
  final _billingAddress2Ctrl = TextEditingController();
  final _billingCityCtrl = TextEditingController(text: "Hà Nội");
  final _billingPostalCtrl = TextEditingController(text: "100000");

  // PAYMENT + VOUCHER
  String _paymentMethod = "COD";
  final _voucherCtrl = TextEditingController();

  @override
  void dispose() {
    _shippingAddress1Ctrl.dispose();
    _shippingAddress2Ctrl.dispose();
    _shippingCityCtrl.dispose();
    _shippingPostalCtrl.dispose();

    _billingAddress1Ctrl.dispose();
    _billingAddress2Ctrl.dispose();
    _billingCityCtrl.dispose();
    _billingPostalCtrl.dispose();

    _voucherCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      // === SHIPPING ===
      final shipping = AddressRequest(
        addressLine1: _shippingAddress1Ctrl.text.trim(),
        addressLine2: _shippingAddress2Ctrl.text.trim().isEmpty
            ? null
            : _shippingAddress2Ctrl.text.trim(),
        city: _shippingCityCtrl.text.trim(),
        postalCode: _shippingPostalCtrl.text.trim(),
        country: "Vietnam",
      );

      // === BILLING ===
      final billing = AddressRequest(
        addressLine1: _billingAddress1Ctrl.text.trim(),
        addressLine2: _billingAddress2Ctrl.text.trim().isEmpty
            ? null
            : _billingAddress2Ctrl.text.trim(),
        city: _billingCityCtrl.text.trim(),
        postalCode: _billingPostalCtrl.text.trim(),
        country: "Vietnam",
      );

      // === ITEMS (từ giỏ hàng) ===
      final items = widget.selectedItems
          .map(
            (e) => OrderItemRequest(
          productId: int.tryParse(e.productId) ?? 0,
          quantity: e.quantity,
        ),
      )
          .toList();

      final req = CreateOrderRequest(
        shippingAddress: shipping,
        billingAddress: billing,
        paymentMethod: _paymentMethod,
        voucherCode: _voucherCtrl.text.trim().isEmpty
            ? null
            : _voucherCtrl.text.trim(),
        items: items,
      );

      final order = await _orderService.createOrder(req);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đặt hàng thành công! Mã đơn: ${order.id}")),
      );

      // báo về CartScreen để reload, xoá item đã thanh toán tuỳ logic
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi đặt hàng: $e")),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thanh toán")),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                "Địa chỉ giao hàng",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _input(_shippingAddress1Ctrl, "Địa chỉ dòng 1"),
              const SizedBox(height: 8),
              _input(
                _shippingAddress2Ctrl,
                "Địa chỉ dòng 2 (không bắt buộc)",
                required: false,
              ),
              const SizedBox(height: 8),
              _input(_shippingCityCtrl, "Thành phố"),
              const SizedBox(height: 8),
              _input(_shippingPostalCtrl, "Mã bưu điện"),

              const SizedBox(height: 20),
              const Text(
                "Địa chỉ thanh toán",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _input(_billingAddress1Ctrl, "Địa chỉ dòng 1"),
              const SizedBox(height: 8),
              _input(
                _billingAddress2Ctrl,
                "Địa chỉ dòng 2 (không bắt buộc)",
                required: false,
              ),
              const SizedBox(height: 8),
              _input(_billingCityCtrl, "Thành phố"),
              const SizedBox(height: 8),
              _input(_billingPostalCtrl, "Mã bưu điện"),

              const SizedBox(height: 20),
              const Text(
                "Phương thức thanh toán",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                items: const [
                  DropdownMenuItem(
                    value: "COD",
                    child: Text("Thanh toán khi nhận hàng (COD)"),
                  ),
                  DropdownMenuItem(
                    value: "BANK_TRANSFER",
                    child: Text("Chuyển khoản ngân hàng"),
                  ),
                  DropdownMenuItem(
                    value: "MOMO",
                    child: Text("Ví MoMo"),
                  ),
                ],
                onChanged: (v) => setState(() => _paymentMethod = v!),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                "Mã giảm giá (voucher)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _input(_voucherCtrl, "Nhập mã nếu có", required: false),

              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _submitting ? "Đang đặt hàng..." : "Đặt hàng",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Input tiện dụng
  Widget _input(
      TextEditingController c,
      String label, {
        bool required = true,
      }) {
    return TextFormField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? "Bắt buộc" : null
          : null,
    );
  }
}
