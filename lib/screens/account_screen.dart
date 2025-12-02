// lib/screens/account_screen.dart

import 'package:flutter/material.dart';

import '../services/auth_service.dart';

import 'login_screen.dart';
import 'my_orders_screen.dart';
import 'notification_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthService _authService = AuthService();

  bool _loadingUser = true;
  bool _loggedIn = false;
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final loggedIn = await _authService.isLoggedIn();
    final username = await _authService.getUsername();

    if (!mounted) return;
    setState(() {
      _loggedIn = loggedIn;
      _username = username;
      _loadingUser = false;
    });
  }

  Future<void> _requireLoginAndRun(VoidCallback action) async {
    if (!_loggedIn) {
      // chuyển sang Login
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      // sau khi quay lại, reload trạng thái
      await _loadUserInfo();
      if (!_loggedIn) return;
    }
    action();
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    setState(() {
      _loggedIn = false;
      _username = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã đăng xuất")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f4ff),
      appBar: AppBar(
        title: const Text('Tài khoản'),
        elevation: 0.5,
        backgroundColor: Colors.white,
      ),
      body: _loadingUser
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          const SizedBox(height: 16),

          // ====== THÔNG TIN USER ======
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.deepPurple.shade100,
                  child: const Icon(
                    Icons.person,
                    size: 36,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _loggedIn
                            ? (_username ?? "Người dùng")
                            : "Khách",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _loggedIn
                            ? "Đã đăng nhập"
                            : "Bạn chưa đăng nhập",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_loggedIn)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
                      ).then((_) => _loadUserInfo());
                    },
                    child: const Text(
                      "Đăng nhập",
                      style: TextStyle(color: Colors.deepPurple),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ====== ĐƠN MUA ======
          _sectionTitle("Đơn mua"),
          _card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.receipt_long,
                      color: Colors.deepPurple),
                  title: const Text("Tất cả đơn mua"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _requireLoginAndRun(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyOrdersScreen(),
                      ),
                    );
                  }),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _orderStatusItem(
                        icon: Icons.inventory_2_outlined,
                        label: "Chờ xác nhận",
                      ),
                      _orderStatusItem(
                        icon: Icons.local_shipping_outlined,
                        label: "Chờ giao",
                      ),
                      _orderStatusItem(
                        icon: Icons.check_circle_outline,
                        label: "Đã giao",
                      ),
                      _orderStatusItem(
                        icon: Icons.cancel_outlined,
                        label: "Đã huỷ",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ====== CÀI ĐẶT / THÔNG TIN KHÁC ======
          _sectionTitle("Tiện ích"),
          _card(
            child: Column(
              children: [
                _menuItem(
                  icon: Icons.location_on_outlined,
                  label: "Địa chỉ của tôi",
                  onTap: () => _requireLoginAndRun(() {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "Tính năng địa chỉ đang được phát triển.")),
                    );
                  }),
                ),
                const Divider(height: 1),
                _menuItem(
                  icon: Icons.notifications_none,
                  label: "Thông báo",
                  onTap: () => _requireLoginAndRun(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    );
                  }),
                ),
                const Divider(height: 1),
                _menuItem(
                  icon: Icons.card_giftcard_outlined,
                  label: "Ví Voucher",
                  onTap: () => _requireLoginAndRun(() {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "Tính năng ví voucher đang được phát triển.")),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ====== ĐĂNG XUẤT ======
          if (_loggedIn)
            _card(
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  "Đăng xuất",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: _logout,
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ====== WIDGET PHỤ ======

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: child,
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _orderStatusItem({
    required IconData icon,
    required String label,
  }) {
    return InkWell(
      onTap: () => _requireLoginAndRun(() {
        // Tạm thời mở MyOrdersScreen, sau này bạn có thể truyền filter trạng thái
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
        );
      }),
      child: Column(
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(height: 4),
          SizedBox(
            width: 70,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
