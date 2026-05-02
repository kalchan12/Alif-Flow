import 'package:flutter/material.dart';
import 'package:alif_flow/theme/app_theme.dart';
import 'package:alif_flow/theme/theme_provider.dart';
import 'package:alif_flow/screens/login_screen.dart';
import 'package:alif_flow/screens/registration_screen.dart';
import 'package:alif_flow/screens/seller_dashboard.dart';
import 'package:alif_flow/screens/admin_dashboard.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

// IMPORTANT: Replace these with your actual Supabase project URL and Anon Key
const supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';

/// Global theme provider instance accessible throughout the app.
final themeProvider = ThemeProvider();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const AlifFlowApp());
}

class AlifFlowApp extends StatelessWidget {
  const AlifFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        return MaterialApp(
          title: 'Alif-Flow',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegistrationScreen(),
            '/seller_dashboard': (context) => const SellerDashboard(),
            '/admin_dashboard': (context) => const AdminDashboard(),
          },
        );
      },
    );
  }
}
