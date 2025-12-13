// lib/screens/card_flip_game_screen.dart

import 'package:flutter/material.dart';
import '../services/minigame_service.dart';

class CardFlipGameScreen extends StatefulWidget {
  const CardFlipGameScreen({super.key});

  @override
  State<CardFlipGameScreen> createState() => _CardFlipGameScreenState();
}

class _CardFlipGameScreenState extends State<CardFlipGameScreen> {
  final MinigameService _minigameService = MinigameService();

  // 6 thẻ
  final int _cardCount = 6;
  late List<bool> _flipped;          // true = đã lật
  late List<bool?> _isWin;           // null = chưa chơi, true = trúng, false = trượt
  bool _loading = false;
  String? _lastMessage;              // thông điệp backend trả về lần gần nhất

  @override
  void initState() {
    super.initState();
    _flipped = List<bool>.filled(_cardCount, false);
    _isWin = List<bool?>.filled(_cardCount, null);
  }

  Future<void> _onCardTap(int index) async {
    if (_loading) return;
    if (_flipped[index]) return; // lật rồi thì thôi

    setState(() => _loading = true);

    final choice = index + 1; // API dùng 1..6

    try {
      final msg = await _minigameService.flipCard(choice: choice);

      // đoán xem có trúng quà không (nếu msg có chữ "điểm" thì coi là trúng)
      final lower = msg.toLowerCase();
      final win = lower.contains("điểm");

      if (!mounted) return;
      setState(() {
        _flipped[index] = true;
        _isWin[index] = win;
        _lastMessage = msg;
      });

      // popup kết quả – sau khi bấm Đóng thì reset lại 6 thẻ
      if (mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(win ? "🎁 Bạn trúng quà!" : "😢 Rất tiếc"),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Đóng"),
              ),
            ],
          ),
        );

        // Sau khi đóng dialog, reset bàn chơi để bắt đầu lượt tiếp theo
        if (mounted) {
          _resetLocalBoard();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi lật thẻ: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resetLocalBoard() {
    setState(() {
      _flipped = List<bool>.filled(_cardCount, false);
      _isWin = List<bool?>.filled(_cardCount, null);
      _lastMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f4ff),
      appBar: AppBar(
        title: const Text("Minigame lật thẻ"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _resetLocalBoard,
            tooltip: "Làm mới bàn chơi (chỉ reset UI, backend vẫn giới hạn lượt)",
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Có 6 thẻ, trong đó 3 thẻ có quà và 3 thẻ không có quà.\n"
                  "Bạn được lật 2 thẻ mỗi ngày (backend kiểm soát lượt).\n"
                  "Sau khi lật xong 1 thẻ, bàn chơi sẽ được làm mới để bạn chọn thẻ tiếp theo.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),

          // Lưới 6 thẻ (3 x 2)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: _cardCount,
              itemBuilder: (context, index) {
                final flipped = _flipped[index];
                final win = _isWin[index];

                return GestureDetector(
                  onTap: _loading ? null : () => _onCardTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: flipped
                          ? (win == true
                          ? Colors.greenAccent.shade100
                          : Colors.grey.shade300)
                          : Colors.deepPurple,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: flipped
                          ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            win == true
                                ? Icons.card_giftcard
                                : Icons.close,
                            size: 32,
                            color: win == true
                                ? Colors.deepPurple
                                : Colors.redAccent,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            win == true ? "Có quà" : "Không có quà",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                          : const Text(
                        "?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: CircularProgressIndicator(),
            )
          else if (_lastMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                _lastMessage!,
                textAlign: TextAlign.center,
                style:
                const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}
