// lib/screens/checkout_screen.dart

import 'package:do_an_chuyen_nganh/models/VoucherResponse.dart';
import 'package:do_an_chuyen_nganh/screens/order_detail_screen.dart';
import 'package:flutter/material.dart';

import '../models/create_order_request.dart';
import '../models/cart_response.dart';

import '../services/order_service.dart';
import '../services/voucher_service.dart';

class CheckoutScreen extends StatefulWidget {
  /// Danh sách sản phẩm được chọn trong giỏ hàng để thanh toán
  final List<CartItem> selectedItems;

  /// User id dùng để gọi API voucher (có thể để null → không load voucher)
  final String? userId;

  const CheckoutScreen({
    super.key,
    required this.selectedItems,
    this.userId,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderService = OrderService();
  final _voucherService = VoucherService();

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

  // VOUCHER LIST
  bool _loadingVouchers = false;
  List<VoucherResponse> _vouchers = [];
  VoucherResponse? _selectedVoucher;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    // Nếu chưa có userId thì không gọi API, tránh lỗi
    final uid = widget.userId;
    if (uid == null || uid.trim().isEmpty) {
      return;
    }

    setState(() {
      _loadingVouchers = true;
    });
    try {
      final list = await _voucherService.getAvailableVouchers(uid);
      if (!mounted) return;
      setState(() {
        _vouchers = list;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi tải voucher: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingVouchers = false;
        });
      }
    }
  }

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

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(order: order),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi đặt hàng: $e")),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _openVoucherPicker() {
    if (_loadingVouchers) return;

    if (_vouchers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bạn không có voucher khả dụng.")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const Text(
                  "Chọn voucher",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _vouchers.length,
                    itemBuilder: (_, i) {
                      final v = _vouchers[i];
                      return ListTile(
                        title: Text(v.code),
                        subtitle: Text(
                          v.discountType == "PERCENT"
                              ? "Giảm ${v.discountValue}%"
                              : "Giảm ${v.discountValue}",
                        ),

                        onTap: () {
                          setState(() {
                            _selectedVoucher = v;
                            _voucherCtrl.text = v.code;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

              // Ô nhập + nút chọn voucher
              Row(
                children: [
                  Expanded(
                    child: _input(
                      _voucherCtrl,
                      "Nhập mã nếu có",
                      required: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _loadingVouchers ? null : _openVoucherPicker,
                    child: _loadingVouchers
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                      CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text("Chọn"),
                  ),
                ],
              ),

              if (_selectedVoucher != null) ...[
                const SizedBox(height: 6),
                Text(
                  "Đã chọn: ${_selectedVoucher!.code} "
                      "(${_selectedVoucher!.discountType == "PERCENT" ? "Giảm ${_selectedVoucher!.discountValue}%" : "Giảm ${_selectedVoucher!.discountValue}"})",
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],

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
