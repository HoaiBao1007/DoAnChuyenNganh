// lib/screens/minigame_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';

import '../services/minigame_service.dart';
import '../models/minigame_history.dart';
import '../utils/format.dart';
import 'minigame_history_screen.dart';

class MinigameScreen extends StatefulWidget {
  const MinigameScreen({super.key});

  @override
  State<MinigameScreen> createState() => _MinigameScreenState();
}

class _WheelItem {
  final String label;
  final Color color;

  _WheelItem(this.label, this.color);
}

class _MinigameScreenState extends State<MinigameScreen> {
  final MinigameService _service = MinigameService();
  final StreamController<int> _selected = StreamController<int>();

  bool _spinning = false;
  String? _lastMessage;
  bool _loadingHistoryPreview = false;
  List<MinigameHistory> _latestHistory = [];

  // Các ô trên vòng quay (chỉ để HIỂN THỊ – backend vẫn quyết định phần thưởng)
  final List<_WheelItem> _wheelItems = [
    _WheelItem("Trượt", Colors.grey.shade300),
    _WheelItem("+10 điểm", Colors.green.shade300),
    _WheelItem("+20 điểm", Colors.green.shade400),
    _WheelItem("Voucher nhỏ", Colors.orange.shade300),
    _WheelItem("Voucher lớn", Colors.orange.shade400),
    _WheelItem("Legendary", Colors.purple.shade300),
  ];

  @override
  void initState() {
    super.initState();
    _loadHistoryPreview();
  }

  @override
  void dispose() {
    _selected.close();
    super.dispose();
  }

  // preview 3 lịch sử gần nhất
  Future<void> _loadHistoryPreview() async {
    setState(() => _loadingHistoryPreview = true);
    try {
      final list = await _service.getHistory();
      if (!mounted) return;
      setState(() {
        _latestHistory = list.take(3).toList();
      });
    } catch (_) {
      // bỏ qua lỗi
    } finally {
      if (mounted) setState(() => _loadingHistoryPreview = false);
    }
  }

  // map message backend -> nhãn ô trên vòng quay
  String _mapMessageToLabel(String msg) {
    msg = msg.toLowerCase();

    if (msg.contains("20 điểm")) return "+20 điểm";
    if (msg.contains("10 điểm")) return "+10 điểm";
    if (msg.contains("legendary")) return "Legendary";
    if (msg.contains("voucher lớn")) return "Voucher lớn";
    if (msg.contains("voucher nhỏ")) return "Voucher nhỏ";

    // còn lại xem như "Trượt"
    return "Trượt";
  }

  Future<void> _spin() async {
    if (_spinning) return;

    setState(() {
      _spinning = true;
      _lastMessage = null;
    });

    try {
      // 1) Gọi API, backend quyết định phần thưởng và tỉ lệ
      final msg = await _service.spinWheel();

      // 2) Map sang ô tương ứng trên vòng quay
      final label = _mapMessageToLabel(msg);
      int index = _wheelItems.indexWhere((e) => e.label == label);
      if (index < 0) index = 0;

      // 3) cho vòng quay quay tới ô index
      _selected.add(index);

      // 4) show message
      if (!mounted) return;
      setState(() {
        _lastMessage = msg;
      });

      // reload preview history
      await _loadHistoryPreview();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi quay vòng quay: $e")),
      );
    } finally {
      if (mounted) setState(() => _spinning = false);
    }
  }

  Future<void> _claimDailyReward() async {
    try {
      final msg = await _service.claimDailyReward();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      await _loadHistoryPreview();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi nhận quà đăng nhập: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mini game"),
      ),
      backgroundColor: const Color(0xfff8f4ff),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ====== QUÀ ĐĂNG NHẬP ======
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Quà đăng nhập hằng ngày",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Mỗi ngày đăng nhập, bạn nhận +10 điểm (nếu chưa nhận).",
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _claimDailyReward,
                      child: const Text("Nhận quà đăng nhập"),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ====== VÒNG QUAY MAY MẮN ======
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Vòng quay may mắn",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),

                  const SizedBox(height: 16),
                  SizedBox(
                    height: 260,
                    child: FortuneWheel(
                      selected: _selected.stream,
                      indicators: const <FortuneIndicator>[
                        FortuneIndicator(
                          alignment: Alignment.topCenter,
                          child: TriangleIndicator(
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                      items: [
                        for (final w in _wheelItems)
                          FortuneItem(
                            child: Text(
                              w.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            style: FortuneItemStyle(
                              color: w.color,
                              borderColor: Colors.white,
                              borderWidth: 2,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _spinning ? null : _spin,
                      child: Text(_spinning ? "Đang quay..." : "Quay ngay"),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_lastMessage != null)
                    Text(
                      _lastMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.deepPurple,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ====== LỊCH SỬ MỚI NHẤT + LINK XEM TẤT CẢ ======
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Lịch sử nhận quà gần đây",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MinigameHistoryScreen(),
                      ),
                    );
                    await _loadHistoryPreview();
                  },
                  child: const Text("Xem tất cả"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loadingHistoryPreview)
              const Center(child: CircularProgressIndicator())
            else if (_latestHistory.isEmpty)
              const Text(
                "Chưa có lịch sử minigame.",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              )
            else
              Column(
                children: _latestHistory
                    .map(
                      (h) => ListTile(
                    dense: true,
                    title: Text(h.description),
                    subtitle: Text(
                      "${h.type} • ${Format.dateTime(h.createdAt)}",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
