// lib/screens/all_vouchers_screen.dart

import 'package:do_an_chuyen_nganh/models/VoucherResponse.dart';
import 'package:flutter/material.dart';

import '../services/voucher_service.dart';
import '../services/minigame_service.dart';   // 👈 DÙNG ĐỂ ĐỔI VOUCHER
import '../utils/format.dart';

class AllVouchersScreen extends StatefulWidget {
  const AllVouchersScreen({super.key});

  @override
  State<AllVouchersScreen> createState() => _AllVouchersScreenState();
}

class _AllVouchersScreenState extends State<AllVouchersScreen> {
  final VoucherService _voucherService = VoucherService();
  final MinigameService _minigameService = MinigameService(); // 👈

  List<VoucherResponse> _vouchers = [];
  bool _loading = true;
  String? _error;

  String? _redeemingCode; // 👈 đang đổi voucher nào (để show loading)

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // GET /voucher/vouchers
      final list = await _voucherService.getAllVouchers();

      if (!mounted) return;
      setState(() {
        _vouchers = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _discountText(VoucherResponse v) {
    if (v.discountType == 'PERCENT') {
      return "- ${v.discountValue.toStringAsFixed(0)}%";
    }
    return "- ${Format.currency(v.discountValue)}";
  }

  String _dateRange(VoucherResponse v) {
    if (v.startDate == null && v.endDate == null) {
      return "Không giới hạn thời gian";
    }
    final from = v.startDate != null ? Format.date(v.startDate!) : "...";
    final to = v.endDate != null ? Format.date(v.endDate!) : "...";
    return "$from - $to";
  }

  Color _statusColor(VoucherResponse v) {
    switch (v.status) {
      case 'ACTIVE':
        return Colors.green;
      case 'EXPIRED':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  // ====== GỌI API ĐỔI VOUCHER BẰNG ĐIỂM ======
  Future<void> _redeemVoucher(VoucherResponse v) async {
    // chỉ cho đổi khi đang ACTIVE và còn số lượng
    if (v.status != 'ACTIVE' || v.quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voucher không khả dụng để đổi.')),
      );
      return;
    }

    if (_redeemingCode != null) return; // đang đổi cái khác rồi

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận đổi điểm'),
        content: Text(
          'Bạn muốn dùng ${v.pointCost} điểm để đổi voucher ${v.code}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đổi'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _redeemingCode = v.code);
    try {
      await _minigameService.redeemVoucher(code: v.code);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đổi voucher ${v.code} thành công!')),
      );

      // có thể reload lại danh sách cho chắc
      await _loadVouchers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đổi voucher: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _redeemingCode = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f4ff),
      appBar: AppBar(
        title: const Text("Toàn bộ voucher"),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          Center(
            child: Text(
              "Lỗi tải voucher:\n$_error",
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    if (_vouchers.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Center(child: Text("Hiện chưa có voucher nào.")),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vouchers.length,
      itemBuilder: (_, i) {
        final v = _vouchers[i];
        final remain = v.quantity;

        final isRedeeming = _redeemingCode == v.code;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // bên trái: thông tin voucher
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // mã voucher + trạng thái
                    Row(
                      children: [
                        Text(
                          v.code,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusColor(v).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            v.status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _statusColor(v),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),
                    Text(
                      _discountText(v),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Điểm cần: ${v.pointCost}",
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Số lượng: $remain",
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dateRange(v),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // nút Đổi bằng điểm
              ElevatedButton(
                onPressed: (v.status != 'ACTIVE' || v.quantity <= 0 || isRedeeming)
                    ? null
                    : () => _redeemVoucher(v),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isRedeeming
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  "Đổi bằng điểm",
                  style: TextStyle(fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
