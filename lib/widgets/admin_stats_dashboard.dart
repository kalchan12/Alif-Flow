import 'package:flutter/material.dart';

class AdminStatsDashboard extends StatelessWidget {
  final double totalGlobalSales;
  final int totalItemsSold;
  final int pendingReports;
  final bool isLoading;

  const AdminStatsDashboard({
    super.key,
    required this.totalGlobalSales,
    required this.totalItemsSold,
    required this.pendingReports,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          
          if (isWide) {
            return Row(
              children: [
                Expanded(child: _buildPrimaryCard('Total Revenue', '\$${totalGlobalSales.toStringAsFixed(2)}', Icons.account_balance_wallet_rounded, colorScheme)),
                const SizedBox(width: 16),
                Expanded(child: _buildSecondaryCard('Items Sold', '$totalItemsSold', Icons.shopping_bag_rounded, colorScheme)),
                const SizedBox(width: 16),
                Expanded(child: _buildSecondaryCard('Pending Reviews', '$pendingReports', Icons.assignment_late_rounded, colorScheme, isAlert: pendingReports > 0)),
              ],
            );
          } else {
            return Column(
              children: [
                _buildPrimaryCard('Total Revenue', '\$${totalGlobalSales.toStringAsFixed(2)}', Icons.account_balance_wallet_rounded, colorScheme),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildSecondaryCard('Items Sold', '$totalItemsSold', Icons.shopping_bag_rounded, colorScheme)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildSecondaryCard('Pending Reviews', '$pendingReports', Icons.assignment_late_rounded, colorScheme, isAlert: pendingReports > 0)),
                  ],
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildPrimaryCard(String title, String value, IconData icon, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: colorScheme.onPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimary.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isLoading)
            SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: colorScheme.onPrimary,
                letterSpacing: -0.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSecondaryCard(String title, String value, IconData icon, ColorScheme colorScheme, {bool isAlert = false}) {
    final iconColor = isAlert ? colorScheme.error : colorScheme.primary;
    final bgCol = isAlert ? colorScheme.errorContainer : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAlert ? colorScheme.error.withValues(alpha: 0.5) : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isAlert ? colorScheme.onErrorContainer : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: iconColor),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isAlert ? colorScheme.error : colorScheme.onSurface,
              ),
            ),
        ],
      ),
    );
  }
}
