import 'package:flutter/material.dart';

import '../services/rating_service.dart';

class RatingScreen extends StatefulWidget {
  final int productId;
  final String productName;

  const RatingScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final _ratingService = RatingService();
  final _commentCtrl = TextEditingController();
  double _rating = 5.0;
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      await _ratingService.createRating(
        productId: widget.productId,
        ratingValue: _rating,
        comment: _commentCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã gửi đánh giá")),
      );
      Navigator.pop(context, true); // trả về true cho màn trước nếu cần
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi gửi đánh giá: $e")),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildStarRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final filled = _rating >= starIndex;
        return IconButton(
          onPressed: () {
            setState(() {
              _rating = starIndex.toDouble();
            });
          },
          icon: Icon(
            filled ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Đánh giá: ${widget.productName}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Text(
              "Chọn số sao",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildStarRow(),
            const SizedBox(height: 16),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Nhận xét (không bắt buộc)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
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
                  _submitting ? "Đang gửi..." : "Gửi đánh giá",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
