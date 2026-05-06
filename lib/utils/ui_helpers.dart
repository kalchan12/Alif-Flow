import 'package:flutter/material.dart';
import 'package:alif_flow/services/auth_service.dart';

class UiHelpers {
  /// Displays a modern, theme-aware toast message (Snackbar).
  static void showCustomToast(BuildContext context, String message, {bool isError = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Choose colors based on theme and error state
    final backgroundColor = isError 
        ? colorScheme.errorContainer 
        : colorScheme.primaryContainer;
    
    final foregroundColor = isError 
        ? colorScheme.onErrorContainer 
        : colorScheme.onPrimaryContainer;

    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: foregroundColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: foregroundColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          elevation: 4,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  /// Displays a confirmation dialog before logging out.
  static Future<void> showLogoutConfirmationDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authService = AuthService();

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: colorScheme.error,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  'Are you sure you want to log out? You will need to enter your credentials to access your account again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: colorScheme.outline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Log Out',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    // If the user confirmed, execute the logout logic
    if (shouldLogout == true && context.mounted) {
      await authService.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  /// Formats numbers with comma separators and handles decimal dots.
  /// Example: 20000.00 -> 20,000.
  /// Example: 20000.50 -> 20,000.5
  static String formatNumber(dynamic value) {
    if (value == null) return '0';
    double val;
    if (value is num) {
      val = value.toDouble();
    } else if (value is String) {
      val = double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    } else {
      return value.toString();
    }

    // Split into integer and decimal parts
    String str = val.toStringAsFixed(2);
    List<String> parts = str.split('.');
    String integerPart = parts[0];
    String decimalPart = parts[1];

    // Add commas to integer part
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formattedInt = integerPart.replaceAllMapped(reg, (Match m) => '${m[1]},');

    if (decimalPart == '00') {
      return '$formattedInt.'; 
    } else {
      // Remove trailing zero if it's something like .50
      if (decimalPart.endsWith('0')) {
        decimalPart = decimalPart.substring(0, 1);
      }
      return '$formattedInt.$decimalPart';
    }
  }
}
