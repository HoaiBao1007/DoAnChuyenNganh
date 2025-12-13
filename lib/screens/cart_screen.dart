import 'dart:convert'; // 👈 thêm
import 'package:shared_preferences/shared_preferences.dart'; // 👈 thêm

import 'package:flutter/material.dart';
import '../models/cart_response.dart';
import '../services/cart_service.dart';
import '../utils/format.dart';
import 'checkout_screen.dart';
import '../state/cart_state.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();

  CartResponse? _cart;
  bool _loading = false;
  bool _updating = false;
  String? _error;

  /// danh sách productId đang được chọn
  final Set<String> _selectedIds = {};

  // Đổi localhost → IP thật
  String fixUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    return url
        .replaceAll("localhost", "192.168.110.18")
        .replaceAll("host.docker.internal", "192.168.110.18")
        .replaceAll("productservice:8081", "192.168.110.18:8081");
  }

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  /// 🔐 Lấy userId (sub) từ JWT lưu trong SharedPreferences
  Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) return null;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload =
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final data = jsonDecode(payload) as Map<String, dynamic>;

      // Backend của bạn: "sub": "hbao"
      return data['sub']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadCart() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cart = await _cartService.getMyCart();
      if (!mounted) return;
      setState(() {
        _cart = cart;
        _selectedIds
          ..clear()
          ..addAll(cart.items.map((e) => e.productId));
      });

      // 🔥 Cập nhật badge giỏ hàng
      CartState.cartCount.value = cart.totalQuantity;
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải giỏ hàng: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeQty(String productId, int newQty) async {
    if (_updating) return;
    if (newQty <= 0) {
      await _removeItem(productId);
      return;
    }

    setState(() => _updating = true);
    try {
      await _cartService.updateQuantity(
        productId: productId,
        quantity: newQty,
      );
      await _loadCart();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật số lượng: $e')),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _removeItem(String productId) async {
    if (_updating) return;

    setState(() => _updating = true);
    try {
      await _cartService.removeItem(productId: productId);
      await _loadCart();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xoá sản phẩm: $e')),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _clearCart() async {
    if (_updating) return;

    setState(() => _updating = true);
    try {
      await _cartService.clearCart();
      await _loadCart();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xoá giỏ hàng: $e')),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  /// danh sách CartItem đang được chọn
  List<CartItem> get _selectedItems {
    if (_cart == null) return [];
    return _cart!.items
        .where((it) => _selectedIds.contains(it.productId))
        .toList();
  }

  /// tổng số lượng và tiền của các item đang được chọn
  (int totalItems, double totalPrice) get _selectedSummary {
    final items = _selectedItems;
    final totalItems =
    items.fold<int>(0, (sum, it) => sum + it.quantity);
    final totalPrice =
    items.fold<double>(0, (sum, it) => sum + it.lineItemTotal);
    return (totalItems, totalPrice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f4ff),
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: (_cart == null || _cart!.items.isEmpty || _updating)
                ? null
                : () async {
              final hasSelection = _selectedIds.isNotEmpty;
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(hasSelection
                      ? 'Xoá sản phẩm đã chọn'
                      : 'Xoá giỏ hàng'),
                  content: Text(hasSelection
                      ? 'Bạn có chắc muốn xoá các sản phẩm đang được chọn?'
                      : 'Bạn có chắc muốn xoá toàn bộ giỏ hàng không?'),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, false),
                      child: const Text('Huỷ'),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, true),
                      child: const Text('Xoá'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                if (hasSelection) {
                  // xoá từng sản phẩm đang được chọn
                  final ids = List<String>.from(_selectedIds);
                  for (final id in ids) {
                    await _removeItem(id);
                  }
                } else {
                  await _clearCart();
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadCart,
                child: _buildBody(),
              ),
            ),
            if (_cart != null && _cart!.items.isNotEmpty)
              _buildSummaryBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Lỗi: $_error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    }

    if (_cart == null || _cart!.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: Text(
              'Giỏ hàng trống',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          SizedBox(height: 40),
        ],
      );
    }

    final items = _cart!.items;
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildCartItem(items[i]),
    );
  }

  Widget _buildCartItem(CartItem item) {
    final fixedImageUrl = fixUrl(item.imageUrl);
    final selected = _selectedIds.contains(item.productId);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // checkbox chọn sản phẩm
          Checkbox(
            value: selected,
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _selectedIds.add(item.productId);
                } else {
                  _selectedIds.remove(item.productId);
                }
              });
            },
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 70,
              height: 70,
              color: Colors.grey.shade200,
              child: fixedImageUrl.isNotEmpty
                  ? Image.network(
                fixedImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, size: 40),
              )
                  : const Icon(Icons.image_not_supported, size: 40),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Format.currency(item.currentPrice),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Tạm tính: ${Format.currency(item.lineItemTotal)}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed:
                _updating ? null : () => _removeItem(item.productId),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: (_updating || item.quantity <= 1)
                        ? null
                        : () => _changeQty(
                      item.productId,
                      item.quantity - 1,
                    ),
                  ),
                  Text(
                    item.quantity.toString(),
                    style: const TextStyle(fontSize: 14),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _updating
                        ? null
                        : () => _changeQty(
                      item.productId,
                      item.quantity + 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    final (totalItems, totalPrice) = _selectedSummary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tổng ($totalItems sản phẩm)",
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  Format.currency(totalPrice),
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _updating
                ? null
                : () async {
              final items = _selectedItems;
              if (items.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Vui lòng chọn ít nhất 1 sản phẩm')),
                );
                return;
              }

              // 🔥 Lấy userId từ token
              final userId = await _getCurrentUserId();
              if (userId == null || userId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Không xác định được userId')),
                );
                return;
              }

              final ok = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => CheckoutScreen(
                    selectedItems: items,
                    userId: userId,     // 👈 truyền UUID
                  ),
                ),
              );

              // nếu checkout thành công, reload giỏ hàng
              if (ok == true) {
                await _loadCart();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              minimumSize: const Size(140, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Mua ngay",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
