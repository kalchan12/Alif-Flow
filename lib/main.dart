import 'package:flutter/material.dart';
import 'package:alif_flow/theme/app_theme.dart';
import 'package:alif_flow/screens/login_screen.dart';
import 'package:alif_flow/screens/registration_screen.dart';
import 'package:alif_flow/screens/seller_dashboard.dart';
import 'package:alif_flow/screens/admin_dashboard.dart';

void main() {
  runApp(const AlifFlowApp());
}

class AlifFlowApp extends StatelessWidget {
  const AlifFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alif-Flow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/seller_dashboard': (context) => const SellerDashboard(),
        '/admin_dashboard': (context) => const AdminDashboard(),
      },
    );
  }
}
