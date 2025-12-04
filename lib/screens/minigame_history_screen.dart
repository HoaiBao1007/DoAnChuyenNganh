// lib/screens/minigame_history_screen.dart
import 'package:flutter/material.dart';

import '../services/minigame_service.dart';
import '../models/minigame_history.dart';
import '../utils/format.dart';

class MinigameHistoryScreen extends StatefulWidget {
  const MinigameHistoryScreen({super.key});

  @override
  State<MinigameHistoryScreen> createState() => _MinigameHistoryScreenState();
}

class _MinigameHistoryScreenState extends State<MinigameHistoryScreen> {
  final MinigameService _service = MinigameService();

  bool _loading = true;
  String? _error;
  List<MinigameHistory> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _service.getHistory();
      if (!mounted) return;
      setState(() {
        _items = list;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch sử minigame"),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
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

    if (_items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              "Chưa có lịch sử minigame.",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final h = _items[i];
        return ListTile(
          title: Text(h.description),
          subtitle: Text(
            "${h.type} • ${Format.dateTime(h.createdAt)}",
            style: const TextStyle(fontSize: 12),
          ),
          trailing: h.pointsEarned != null
              ? Text(
            "+${h.pointsEarned}đ",
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}
