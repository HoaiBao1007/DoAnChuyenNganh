// lib/screens/voucher_wallet_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/VoucherResponse.dart';
import '../services/voucher_service.dart';

class VoucherWalletScreen extends StatefulWidget {
  const VoucherWalletScreen({super.key});

  @override
  State<VoucherWalletScreen> createState() => _VoucherWalletScreenState();
}

class _VoucherWalletScreenState extends State<VoucherWalletScreen> {
  final VoucherService _voucherService = VoucherService();

  bool _loading = false;
  String? _error;
  List<VoucherResponse> _vouchers = [];

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId'); // UUID lưu lúc login
    if (userId == null || userId.isEmpty) return null;
    return userId;
  }

  Future<void> _loadVouchers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        setState(() {
          _error = 'Không xác định được userId, vui lòng đăng nhập lại.';
        });
        return;
      }

      final list = await _voucherService.getAvailableVouchers(userId);
      if (!mounted) return;
      setState(() {
        _vouchers = list;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ví Voucher'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadVouchers,
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
        children: [
          const SizedBox(height: 80),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Lỗi: $_error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    }

    if (_vouchers.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Center(
            child: Icon(Icons.card_giftcard_outlined,
                size: 70, color: Colors.grey),
          ),
          SizedBox(height: 12),
          Center(
            child: Text(
              'Bạn chưa có voucher nào khả dụng',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _vouchers.length,
      itemBuilder: (_, i) {
        final v = _vouchers[i];
        final discountText = v.discountType == "PERCENT"
            ? "Giảm ${v.discountValue}%"
            : "Giảm ${v.discountValue}";

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.card_giftcard,
                      color: Colors.deepPurple),
                ),
                const SizedBox(width: 12),

                // Nội dung
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.code,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        discountText,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Điểm đổi: ${v.pointCost}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (v.startDate != null && v.endDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Hiệu lực: ${v.startDate} - ${v.endDate}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ],
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
