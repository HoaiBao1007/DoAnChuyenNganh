import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final AuthService authService = AuthService();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool loading = false;

  // ================= REGISTER =================
  Future<void> _register() async {
    setState(() => loading = true);

    try {
      await authService.register(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
        _emailController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đăng ký thành công!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi đăng ký: $e")),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(Icons.person_add,
                    size: 72, color: Colors.deepPurple),
                const SizedBox(height: 16),
                const Text("Tạo tài khoản mới",
                    style:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),

                // USERNAME
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: "Tên đăng nhập",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // EMAIL
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "Mật Khẩu",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // PASSWORD
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Email",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                // REGISTER BUTTON
                ElevatedButton(
                  onPressed: loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Đăng ký",
                      style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 16),

                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Text(
                    "Đã có tài khoản? Đăng nhập",
                    style: TextStyle(color: Colors.deepPurple.shade800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
