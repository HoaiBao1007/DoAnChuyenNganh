// lib/screens/product_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../models/cart_response.dart';
import '../services/cart_service.dart';
import '../utils/format.dart';

// ⭐ Thêm import rating
import '../services/rating_service.dart';
import '../models/rating_summary.dart';

import 'cart_screen.dart';
import 'checkout_screen.dart';
import 'login_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final CartService _cartService = CartService();

  // ⭐ Thêm RatingService
  final RatingService _ratingService = RatingService();

  bool _adding = false;
  bool _buyingNow = false;

  // ⭐ Thêm biến rating
  RatingSummary? _ratingSummary;
  bool _loadingRating = false;

  @override
  void initState() {
    super.initState();
    _loadRating(); // ⭐ load rating
  }

  // ⭐ HÀM LOAD RATING
  Future<void> _loadRating() async {
    setState(() => _loadingRating = true);

    try {
      final summary =
      await _ratingService.getRatingSummary(widget.product.id);

      if (!mounted) return;
      setState(() => _ratingSummary = summary);
    } catch (e) {
      print("Lỗi rating: $e");
    } finally {
      if (mounted) setState(() => _loadingRating = false);
    }
  }

  // ⭐ HIỂN THỊ SAO
  Widget _buildRatingRow() {
    if (_ratingSummary == null) {
      if (_loadingRating) {
        return const SizedBox(
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }
      return const SizedBox.shrink();
    }

    final avg = _ratingSummary!.averageRating;
    final count = _ratingSummary!.ratingCount;

    // tính số sao
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      IconData icon;
      if (avg >= i) {
        icon = Icons.star;
      } else if (avg >= i - 0.5) {
        icon = Icons.star_half;
      } else {
        icon = Icons.star_border;
      }
      stars.add(Icon(icon, size: 18, color: Colors.amber));
    }

    return Row(
      children: [
        ...stars,
        const SizedBox(width: 6),
        Text(avg.toStringAsFixed(1),
            style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 4),
        Text("($count đánh giá)",
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // ==================
  // GIỮ NGUYÊN TOÀN BỘ CODE CỦA BẠN BÊN DƯỚI
  // ==================

  Future<bool> _checkLoggedInAndGoLoginIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      return true;
    }

    if (!mounted) return false;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    return false;
  }

  Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null || userId.isEmpty) {
      return null;
    }
    return userId;
  }

  Future<void> _addToCart({bool goToCart = false}) async {
    if (_adding) return;
    final ok = await _checkLoggedInAndGoLoginIfNeeded();
    if (!ok) return;

    final p = widget.product;

    setState(() => _adding = true);
    try {
      await _cartService.addToCart(
        productId: p.id,
        quantity: 1,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm sản phẩm vào giỏ hàng')),
      );

      if (goToCart) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _buyNow() async {
    if (_buyingNow) return;
    final ok = await _checkLoggedInAndGoLoginIfNeeded();
    if (!ok) return;

    final p = widget.product;

    setState(() => _buyingNow = true);
    try {
      await _cartService.addToCart(productId: p.id, quantity: 1);

      final cart = await _cartService.getMyCart();
      CartItem? selectedItem;

      try {
        selectedItem =
            cart.items.firstWhere((it) => it.productId == p.id.toString());
      } catch (_) {
        selectedItem = null;
      }

      if (selectedItem == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
            Text('Không tìm thấy sản phẩm trong giỏ hàng để thanh toán'),
          ),
        );
        return;
      }

      final userId = await _getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không xác định được userId')),
        );
        return;
      }

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => CheckoutScreen(
            selectedItems: [selectedItem!], // ✅ ép non-null vì đã check ở trên
            userId: userId,
          ),
        ),
      );

      if (!mounted) return;
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đặt hàng thành công!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi mua ngay: $e')),
      );
    } finally {
      if (mounted) setState(() => _buyingNow = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return Scaffold(
      backgroundColor: const Color(0xfff8f4ff),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Hero(
              tag: "product_${p.id}",
              child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                  ? Image.network(
                p.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                const Center(child: Icon(Icons.broken_image, size: 60)),
              )
                  : const Center(child: Icon(Icons.image, size: 60)),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ⭐ HIỂN THỊ SAO NGAY DƯỚI TÊN
                  _buildRatingRow(),

                  const SizedBox(height: 8),

                  Text(
                    Format.currency(p.price),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(),

                  const SizedBox(height: 12),

                  const Text(
                    "Mô tả sản phẩm",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    p.description?.isNotEmpty == true
                        ? p.description!
                        : "Không có mô tả",
                    style: const TextStyle(fontSize: 14),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                  _adding ? null : () => _addToCart(goToCart: false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side:
                    const BorderSide(color: Colors.deepPurple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _adding
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                    CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text(
                    "Thêm vào giỏ",
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _buyingNow ? null : _buyNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _buyingNow ? "Đang xử lý..." : "Mua ngay",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
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
}
