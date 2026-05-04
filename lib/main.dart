import 'package:flutter/material.dart';
import 'package:alif_flow/theme/app_theme.dart';
import 'package:alif_flow/theme/theme_provider.dart';
import 'package:alif_flow/screens/login_screen.dart';
import 'package:alif_flow/screens/registration_screen.dart';
import 'package:alif_flow/screens/seller_dashboard.dart';
import 'package:alif_flow/screens/admin_dashboard.dart';
import 'package:alif_flow/screens/splash_screen.dart';
import 'package:alif_flow/screens/report_preview_screen.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    debugPrint('Warning: Supabase credentials not found in .env');
  }

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
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegistrationScreen(),
            '/seller_dashboard': (context) => const SellerDashboard(),
            '/admin_dashboard': (context) => const AdminDashboard(),
            '/report-preview': (context) => const ReportPreviewScreen(),
          },
        );
      },
    );
  }
}
