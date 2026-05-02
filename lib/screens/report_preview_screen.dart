import 'package:flutter/material.dart';
import 'package:alif_flow/theme/app_theme.dart';

class ReportPreviewScreen extends StatelessWidget {
  const ReportPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Report'),
      ),
      body: const Center(
        child: Text('Report Preview Content'),
      ),
    );
  }
}
