import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final double totalSales;
  final double totalReceived;
  final double totalBalance;

  const SummaryCard({
    super.key,
    required this.totalSales,
    required this.totalReceived,
    required this.totalBalance,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.3),
              colorScheme.surface,
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    size: 20,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Weekly Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Metrics
            _buildMetricRow(
              context,
              icon: Icons.point_of_sale,
              label: 'Total Sales',
              value: totalSales,
              color: colorScheme.primary,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
            _buildMetricRow(
              context,
              icon: Icons.payments_outlined,
              label: 'Amount Received',
              value: totalReceived,
              color: colorScheme.tertiary,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: totalBalance > 0
                    ? colorScheme.errorContainer.withValues(alpha: 0.4)
                    : colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: totalBalance > 0
                      ? colorScheme.error.withValues(alpha: 0.3)
                      : colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: _buildMetricRow(
                context,
                icon: totalBalance > 0
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
                label: 'Outstanding Balance',
                value: totalBalance,
                color: totalBalance > 0 ? colorScheme.error : colorScheme.primary,
                colorScheme: colorScheme,
                isBold: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required double value,
    required Color color,
    required ColorScheme colorScheme,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
