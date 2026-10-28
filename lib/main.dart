import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'pages/auth/forgot_password_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/pelanggan/pelanggan_home_page.dart';
import 'pages/teknisi/teknisi_home_page.dart';

void main() {
  runApp(const KomporCareApp());
}

class KomporCareApp extends StatelessWidget {
  const KomporCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KomporCare',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      initialRoute: '/login',
      routes: {
        // auth
        '/login': (_) => const LoginPage(),
        '/forgot': (_) => const ForgotPasswordPage(),
        '/register': (_) => const RegisterPage(),
        // pelanggan
        '/pelanggan': (_) => const PelangganHomePage(),
        // teknisi
        '/teknisi': (_) => const TeknisiHomePage(),
      },
    );
  }
}
