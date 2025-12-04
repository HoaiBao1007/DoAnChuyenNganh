// lib/screens/edit_account_screen.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class EditAccountScreen extends StatefulWidget {
  const EditAccountScreen({super.key});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _currentPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();

  final AuthService _authService = AuthService();

  bool _loading = false;
  String? _userId; // lấy từ API /user/users/me

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _authService.getMyProfile();
      if (!mounted) return;
      setState(() {
        _userId = profile.id;
        _emailCtrl.text = profile.email ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi lấy thông tin tài khoản: $e')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không xác định được tài khoản.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _authService.updateAccount(
        userId: _userId!,
        email: _emailCtrl.text.trim(),
        newPassword: _newPwdCtrl.text.trim().isEmpty
            ? null
            : _newPwdCtrl.text.trim(),
        currentPassword: _currentPwdCtrl.text.trim().isEmpty
            ? null
            : _currentPwdCtrl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật tài khoản thành công')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật tài khoản: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _currentPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sửa thông tin tài khoản'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Email',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Nhập email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Email không được để trống';
                  }
                  if (!v.contains('@')) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              const Text(
                'Mật khẩu hiện tại (để đổi mật khẩu)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _currentPwdCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Nhập mật khẩu hiện tại (có thể bỏ trống nếu chỉ đổi email)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Mật khẩu mới',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _newPwdCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Nhập mật khẩu mới (bỏ trống nếu không đổi)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length < 6) {
                    return 'Mật khẩu phải từ 6 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Lưu thay đổi',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
