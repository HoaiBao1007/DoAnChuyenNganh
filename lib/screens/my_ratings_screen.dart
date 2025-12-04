// lib/screens/my_ratings_screen.dart

import 'package:flutter/material.dart';

import '../models/rating_response.dart';
import '../services/rating_service.dart';
import '../utils/format.dart';

class MyRatingsScreen extends StatefulWidget {
  const MyRatingsScreen({super.key});

  @override
  State<MyRatingsScreen> createState() => _MyRatingsScreenState();
}

class _MyRatingsScreenState extends State<MyRatingsScreen> {
  final RatingService _ratingService = RatingService();

  bool _loading = false;
  String? _error;
  List<RatingResponse> _ratings = [];

  @override
  void initState() {
    super.initState();
    _loadMyRatings();
  }

  Future<void> _loadMyRatings() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _ratingService.getMyRatings();
      if (!mounted) return;
      setState(() {
        _ratings = list;
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

  Future<void> _deleteRating(RatingResponse r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá đánh giá'),
        content: const Text('Bạn có chắc muốn xoá đánh giá này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _ratingService.deleteMyRating(
        productId: r.productId,
        ratingId: r.id,
      );
      if (!mounted) return;

      setState(() {
        _ratings.removeWhere((e) => e.id == r.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xoá đánh giá')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xoá đánh giá: $e')),
      );
    }
  }

  Widget _buildStars(double value) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      IconData icon;
      if (value >= i) {
        icon = Icons.star;
      } else if (value >= i - 0.5) {
        icon = Icons.star_half;
      } else {
        icon = Icons.star_border;
      }
      stars.add(Icon(
        icon,
        size: 16,
        color: Colors.amber,
      ));
    }
    return Row(children: stars);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đánh giá'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyRatings,
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

    if (_ratings.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(
            child: Icon(Icons.rate_review_outlined,
                size: 80, color: Colors.grey),
          ),
          SizedBox(height: 16),
          Center(
            child: Text(
              'Bạn chưa có đánh giá nào',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: _ratings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final r = _ratings[i];
        return Card(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // hàng trên: productId + nút xoá
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Sản phẩm #${r.productId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon:
                      const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteRating(r),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // sao + điểm số
                Row(
                  children: [
                    _buildStars(r.ratingValue),
                    const SizedBox(width: 6),
                    Text(
                      r.ratingValue.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                if (r.comment != null && r.comment!.trim().isNotEmpty)
                  Text(
                    r.comment!,
                    style: const TextStyle(fontSize: 13),
                  ),

                const SizedBox(height: 6),
                Text(
                  r.createdAt != null
                      ? Format.dateTime(r.createdAt!)
                      : '',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
