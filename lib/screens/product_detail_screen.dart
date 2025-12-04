// lib/screens/product_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../models/cart_response.dart';
import '../models/rating_summary.dart';
import '../models/rating_response.dart';
import '../services/cart_service.dart';
import '../services/rating_service.dart';
import '../utils/format.dart';

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
  final RatingService _ratingService = RatingService();

  bool _adding = false; // trạng thái cho "Thêm vào giỏ"
  bool _buyingNow = false; // trạng thái cho "Mua ngay"

  // ==== STATE CHO ĐÁNH GIÁ ====
  RatingSummary? _ratingSummary;
  List<RatingResponse> _ratings = [];
  bool _loadingRating = false;

  @override
  void initState() {
    super.initState();
    _loadRating(); // load sao + danh sách đánh giá
  }

  Future<void> _loadRating() async {
    setState(() => _loadingRating = true);
    try {
      final productId = widget.product.id;

      // lấy trung bình sao
      final summary = await _ratingService.getRatingSummary(productId);
      // lấy danh sách đánh giá theo productId
      final list = await _ratingService.getRatingsByProduct(productId);

      if (!mounted) return;
      setState(() {
        _ratingSummary = summary;
        _ratings = list;
      });
    } catch (e) {
      // log nhẹ, không show lỗi to
      // print("Lỗi load rating: $e");
    } finally {
      if (mounted) setState(() => _loadingRating = false);
    }
  }

  // ====== CHECK ĐĂNG NHẬP ======
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

  /// Lấy userId (UUID) đã lưu trong SharedPreferences khi login
  Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId'); // ví dụ: "f1b7b8a5-...."

    if (userId == null || userId.isEmpty) {
      return null;
    }
    return userId;
  }

  // ================== THÊM VÀO GIỎ ==================
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

  // ================== MUA NGAY ==================
  Future<void> _buyNow() async {
    if (_buyingNow) return;

    final ok = await _checkLoggedInAndGoLoginIfNeeded();
    if (!ok) return;

    final p = widget.product;

    setState(() => _buyingNow = true);
    try {
      // 1) Đảm bảo sản phẩm có trong cart
      await _cartService.addToCart(
        productId: p.id,
        quantity: 1,
      );

      // 2) Lấy lại giỏ hàng mới nhất
      final cart = await _cartService.getMyCart();

      // 3) Tìm đúng CartItem có productId tương ứng
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

      // dùng biến tạm để tránh lỗi CartItem? -> CartItem
      final CartItem item = selectedItem;

      // 3.5) Lấy userId (UUID) từ SharedPreferences
      final userId = await _getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không xác định được userId')),
        );
        return;
      }

      // 4) Mở màn Checkout
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => CheckoutScreen(
            selectedItems: [item],
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

  // ============= HÀNG HIỂN THỊ SAO (TRUNG BÌNH) =============
  Widget _buildRatingRow() {
    if (_ratingSummary == null) {
      if (_loadingRating) {
        return const SizedBox(
          height: 18,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    final avg = _ratingSummary!.averageRating;
    final count = _ratingSummary!.ratingCount;

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
      stars.add(
        Icon(
          icon,
          size: 18,
          color: Colors.amber,
        ),
      );
    }

    return Row(
      children: [
        ...stars,
        const SizedBox(width: 6),
        Text(
          avg.toStringAsFixed(1),
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(width: 4),
        Text(
          "($count đánh giá)",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  // ============= DANH SÁCH ĐÁNH GIÁ =============
  Widget _buildRatingSection() {
    if (_loadingRating && _ratings.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_ratings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          "Chưa có đánh giá nào cho sản phẩm này.",
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: _ratings.map((r) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // tên user + số sao
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    r.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (i) {
                      final starIndex = i + 1;
                      return Icon(
                        starIndex <= r.ratingValue
                            ? Icons.star
                            : Icons.star_border,
                        size: 16,
                        color: Colors.amber,
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (r.comment != null && r.comment!.isNotEmpty)
                Text(
                  r.comment!,
                  style: const TextStyle(fontSize: 13),
                ),
              if (r.createdAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  Format.dateTime(r.createdAt!),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return Scaffold(
      backgroundColor: const Color(0xfff8f4ff),
      appBar: AppBar(
        backgroundColor: Color(0xFFE8F0FE), // 💙 đổi sang màu xanh
        elevation: 0.5,
        title: Text(
          p.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
          // Ảnh sản phẩm
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

          // Thông tin sản phẩm
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

                  // ⭐ HÀNG SAO NGAY DƯỚI TÊN
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
                  const SizedBox(height: 20),

                  const Text(
                    "Đánh giá sản phẩm",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRatingSection(),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // Thanh dưới cùng
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
              // Thêm vào giỏ
              Expanded(
                child: OutlinedButton(
                  onPressed:
                  _adding ? null : () => _addToCart(goToCart: false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: const BorderSide(color: Colors.deepPurple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _adding
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text(
                    "Thêm vào giỏ",
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Mua ngay
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
                    style: const TextStyle(fontSize: 16, color: Colors.white),
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
