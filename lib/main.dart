import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/main_navigation.dart'; // import màn chính của bạn

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Mỗi lần mở app mới → xoá token cũ → luôn là guest
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('token'); // key đang dùng trong AuthService

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HyperBuy',
      theme: ThemeData(
        useMaterial3: false,
        primarySwatch: Colors.deepPurple,
      ),
      home: const MainNavigation(),   // 🔥 luôn vào MainNavigation (Trang chủ)
    );
  }
}
