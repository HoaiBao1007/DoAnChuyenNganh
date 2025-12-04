// lib/screens/home_screen.dart

import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/rating_summary.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/rating_service.dart';
import '../utils/format.dart';

import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'notification_screen.dart';
import '../state/cart_state.dart';
import '../state/notification_state.dart'; // 👈 THÊM: state số thông báo
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();
  final CartService _cartService = CartService();
  final RatingService _ratingService = RatingService(); // ⭐

  final Map<int, RatingSummary> _ratingCache = {}; // ⭐ Cache rating

  List<Product> products = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCartCount();
  }

  // ================= CART COUNT =================
  Future<void> _loadCartCount() async {
    try {
      final cart = await _cartService.getMyCart();
      CartState.cartCount.value = cart.totalQuantity;
    } catch (_) {}
  }

  // ================= LOAD PRODUCTS =================
  Future<void> _loadProducts() async {
    try {
      setState(() => loading = true);

      final loggedIn = await _authService.isLoggedIn();
      List<Product> list = [];

      if (loggedIn) {
        try {
          list = await _productService.getUserRecommendations(limit: 12);
        } catch (_) {
          await _authService.logout();
          list = await _productService.getGuestRecommendations(limit: 12);
        }
      } else {
        list = await _productService.getGuestRecommendations(limit: 12);
      }

      if (!mounted) return;

      setState(() {
        products = list;
        loading = false;
      });

      _fetchRatings(list); // ⭐ Load rating
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Lỗi tải sản phẩm: $e")));
    }
  }

  // =========== LOAD RATING SUMMARY CHO MỖI SẢN PHẨM ===========
  Future<void> _fetchRatings(List<Product> list) async {
    for (final p in list) {
      if (_ratingCache.containsKey(p.id)) continue;

      try {
        final summary = await _ratingService.getRatingSummary(p.id);
        if (!mounted) return;
        setState(() {
          _ratingCache[p.id] = summary;
        });
      } catch (_) {}
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F0FE), // 💙 MÀU XANH NHẠT
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F0FE), // 💙 AppBar trùng màu nền
        elevation: 0,
        title: const Text(
          "Xin chào",
          style: TextStyle(color: Colors.black87, fontSize: 22),
        ),
        actions: [
          // 🛒 GIỎ HÀNG CÓ BADGE
          ValueListenableBuilder<int>(
            valueListenable: CartState.cartCount,
            builder: (_, count, __) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.deepPurple, // 👈 dễ nhìn hơn
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // 🔔 THÔNG BÁO CÓ BADGE
          ValueListenableBuilder<int>(
            valueListenable: NotificationState.unreadCount,
            builder: (_, count, __) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.deepPurple, // 👈 đồng bộ màu
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationScreen(),
                        ),
                      );
                      // tuỳ bạn: sau khi mở danh sách thông báo có thể reset về 0
                      // NotificationState.unreadCount.value = 0;
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadProducts();
          await _loadCartCount();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBox(),
              const SizedBox(height: 20),
              _buildBanner(),
              const SizedBox(height: 20),
              _buildCategories(),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Sản phẩm nổi bật",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
              loading
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
                  : _buildProductGrid(),
            ],
          ),
        ),
      ),
    );
  }

  // =============== SEARCH BOX ===============
  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: TextField(
          readOnly: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          ),
          decoration: const InputDecoration(
            hintText: "Tìm sản phẩm...",
            border: InputBorder.none,
            icon: Icon(Icons.search),
          ),
        ),
      ),
    );
  }

  // =============== BANNER ===============
  Widget _buildBanner() {
    return SizedBox(
      height: 150,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.88),
        itemCount: 3,
        itemBuilder: (_, i) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            margin: const EdgeInsets.only(left: 16, right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: [
                Colors.deepPurple,
                Colors.pinkAccent,
                Colors.blueAccent,
              ][i],
            ),
            child: Center(
              child: Text(
                [
                  "Giảm giá tới 50% 🎉",
                  "Hàng mới về hôm nay",
                  "Miễn phí vận chuyển 🚚",
                ][i],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // =============== CATEGORIES ===============
  Widget _buildCategories() {
    final cats = [
      // bạn điền lại danh mục nếu cần
    ];

    return SizedBox(
      height: 95,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        children: cats.map((c) {
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.deepPurple.shade100,
                  child: Icon(
                    c["icon"] as IconData,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  c["name"] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // =============== PRODUCT GRID ===============
  Widget _buildProductGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 260,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (_, i) => _productCard(products[i]),
    );
  }

  // =============== PRODUCT CARD (CÓ RATING) ===============
  Widget _productCard(Product p) {
    final rating = _ratingCache[p.id];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: "product_${p.id}",
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
                  image: DecorationImage(
                    image: NetworkImage(p.imageUrl ?? ""),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên sản phẩm
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // ⭐ Rating
                  if (rating != null && rating.ratingCount > 0)
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating.averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "(${rating.ratingCount})",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 4),

                  // Giá
                  Text(
                    Format.currency(p.price),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
