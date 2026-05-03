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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: const Center(
            child: Text('Report Preview Content'),
          ),
        ),
      ),
    );
  }
}
