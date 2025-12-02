// lib/screens/home_screen.dart

import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../utils/format.dart';

import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'notification_screen.dart';
import '../state/cart_state.dart';
import 'search_screen.dart'; // 👈 màn tìm kiếm riêng

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();
  final CartService _cartService = CartService();

  List<Product> products = [];
  bool loading = true;
  bool isLoggedIn = false;

  final List<Color> _bannerColors = [
    Colors.deepPurple,
    Colors.pinkAccent,
    Colors.blueAccent,
  ];

  final List<String> _bannerTexts = [
    "Giảm giá tới 50% 🎉",
    "Hàng mới về hôm nay",
    "Miễn phí vận chuyển 🚚",
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();     // gợi ý theo user/guest
    _loadCartCount();    // lấy số lượng giỏ hàng ban đầu
  }

  // =================== LOAD CART COUNT ===================
  Future<void> _loadCartCount() async {
    try {
      final cart = await _cartService.getMyCart();
      CartState.cartCount.value = cart.totalQuantity;
    } catch (_) {
      // nếu lỗi (chưa đăng nhập, 401, ...) thì giữ nguyên
    }
  }

  // =================== LOAD PRODUCTS MẶC ĐỊNH ===================
  Future<void> _loadProducts() async {
    try {
      if (mounted) {
        setState(() {
          loading = true;
        });
      }

      final loggedIn = await _authService.isLoggedIn();
      List<Product> list = [];

      if (loggedIn) {
        // đã đăng nhập → gọi gợi ý cho user
        try {
          list = await _productService.getUserRecommendations(limit: 12);
        } catch (_) {
          // token có thể hết hạn → logout và dùng guest
          await _authService.logout();
          list = await _productService.getGuestRecommendations(limit: 12);
        }
      } else {
        // chưa đăng nhập → luôn dùng guest
        list = await _productService.getGuestRecommendations(limit: 12);
      }

      if (!mounted) return;
      setState(() {
        products = list;
        loading = false;
        isLoggedIn = loggedIn;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi tải sản phẩm: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f4ff),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Xin chào 👋",
          style: TextStyle(color: Colors.black87, fontSize: 22),
        ),
        actions: [
          // Icon giỏ hàng có badge
          ValueListenableBuilder<int>(
            valueListenable: CartState.cartCount,
            builder: (_, count, __) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CartScreen(),
                        ),
                      );
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
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadProducts();   // load lại gợi ý
          await _loadCartCount();  // cập nhật lại số lượng giỏ
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ô tìm kiếm → mở SearchScreen
              Padding(
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SearchScreen(),
                        ),
                      );
                    },
                    decoration: const InputDecoration(
                      hintText: "Tìm sản phẩm...",
                      border: InputBorder.none,
                      icon: Icon(Icons.search),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Banner
              _buildBanner(),
              const SizedBox(height: 20),

              // Danh mục
              _buildCategories(),
              const SizedBox(height: 20),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Sản phẩm nổi bật",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 10),

              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                _buildProductGrid(),
            ],
          ),
        ),
      ),
    );
  }

  // ========= BANNER =========
  Widget _buildBanner() {
    return SizedBox(
      height: 150,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.88),
        itemCount: _bannerTexts.length,
        itemBuilder: (_, i) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            margin: const EdgeInsets.only(left: 16, right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: _bannerColors[i],
            ),
            child: Center(
              child: Text(
                _bannerTexts[i],
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

  // ========= DANH MỤC =========
  Widget _buildCategories() {
    final cats = [
      {"icon": Icons.phone_android, "name": "Điện thoại"},
      {"icon": Icons.chair_outlined, "name": "Nội thất"},
      {"icon": Icons.laptop_mac, "name": "Laptop"},
      {"icon": Icons.watch_outlined, "name": "Đồng hồ"},
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
                  child: Icon(c["icon"] as IconData, color: Colors.deepPurple),
                ),
                const SizedBox(height: 6),
                Text(
                  c["name"] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                )
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ========= GRID SẢN PHẨM =========
  Widget _buildProductGrid() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 600),
      opacity: loading ? 0 : 1,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 250,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemBuilder: (_, i) {
          final p = products[i];
          return _animatedProductCard(p, i);
        },
      ),
    );
  }

  Widget _animatedProductCard(Product p, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.9, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 450),
              pageBuilder: (_, a, __) => FadeTransition(
                opacity: a,
                child: ProductDetailScreen(product: p),
              ),
            ),
          );
        },
        child: _productCard(p),
      ),
    );
  }

  Widget _productCard(Product p) {
    return Container(
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
          )
        ],
      ),
    );
  }
}
