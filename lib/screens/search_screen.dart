import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../utils/format.dart';
import 'product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final String initialKeyword;

  const SearchScreen({
    super.key,
    this.initialKeyword = '',
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ProductService _productService = ProductService();

  final TextEditingController _keywordCtrl = TextEditingController();
  final TextEditingController _minPriceCtrl = TextEditingController();
  final TextEditingController _maxPriceCtrl = TextEditingController();

  /// '', 'price,asc', 'price,desc', 'name,asc', 'name,desc'
  String _sort = '';
  bool _loading = false;
  List<Product> _results = [];

  @override
  void initState() {
    super.initState();
    _keywordCtrl.text = widget.initialKeyword;
    if (widget.initialKeyword.isNotEmpty) {
      _search();
    }
  }

  @override
  void dispose() {
    _keywordCtrl.dispose();
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  // ================== CALL API TÌM KIẾM ==================
  Future<void> _search() async {
    try {
      setState(() => _loading = true);

      // 👉 dùng double? thay vì int?
      double? minPrice;
      double? maxPrice;

      final minText = _minPriceCtrl.text.trim();
      final maxText = _maxPriceCtrl.text.trim();

      if (minText.isNotEmpty) {
        minPrice = double.tryParse(minText);
      }
      if (maxText.isNotEmpty) {
        maxPrice = double.tryParse(maxText);
      }

      final keyword = _keywordCtrl.text.trim();

      final list = await _productService.searchProducts(
        query: keyword.isEmpty ? null : keyword,
        minPrice: minPrice,
        maxPrice: maxPrice,
        sort: _sort.isEmpty ? null : _sort,
        page: 0,
        size: 20,
      );

      if (!mounted) return;
      setState(() {
        _results = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi tìm kiếm: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f4ff),
      appBar: AppBar(
        title: const Text('Tìm kiếm sản phẩm'),
      ),
      body: Column(
        children: [
          // ========= KHU VỰC BỘ LỌC =========
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Keyword
                TextField(
                  controller: _keywordCtrl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'Nhập tên sản phẩm...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // Min / Max price
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Giá từ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _maxPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Đến',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Sort dropdown
                Row(
                  children: [
                    const Text(
                      'Sắp xếp:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _sort,
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: '',
                            child: Text('Mặc định'),
                          ),
                          DropdownMenuItem(
                            value: 'price,asc',
                            child: Text('Giá tăng dần'),
                          ),
                          DropdownMenuItem(
                            value: 'price,desc',
                            child: Text('Giá giảm dần'),
                          ),
                          DropdownMenuItem(
                            value: 'name,asc',
                            child: Text('Tên A → Z'),
                          ),
                          DropdownMenuItem(
                            value: 'name,desc',
                            child: Text('Tên Z → A'),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _sort = v ?? '';
                          });
                          _search();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Nút tìm
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _search,
                    icon: const Icon(Icons.search),
                    label: const Text('Tìm kiếm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ========= KẾT QUẢ =========
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                ? const Center(
              child: Text('Không tìm thấy sản phẩm phù hợp'),
            )
                : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 250,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final p = _results[i];
                return _productCard(p);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(Product p) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: p),
          ),
        );
      },
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
            Container(
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
      ),
    );
  }
}
