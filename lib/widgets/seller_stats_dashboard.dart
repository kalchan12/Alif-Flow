import 'package:flutter/material.dart';

class SellerStatsDashboard extends StatelessWidget {
  final int currentDraftQuantity;
  final double currentDraftEarned;
  final int weeklyQuantity;
  final double weeklyEarned;
  final int allTimeQuantity;
  final double allTimeEarned;
  final bool isLoading;

  const SellerStatsDashboard({
    super.key,
    required this.currentDraftQuantity,
    required this.currentDraftEarned,
    required this.weeklyQuantity,
    required this.weeklyEarned,
    required this.allTimeQuantity,
    required this.allTimeEarned,
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
                Expanded(child: _buildCard('Current Draft', currentDraftQuantity, currentDraftEarned, Icons.edit_document, colorScheme, true)),
                const SizedBox(width: 12),
                Expanded(child: _buildCard('Last 7 Days', weeklyQuantity, weeklyEarned, Icons.date_range_rounded, colorScheme, false)),
                const SizedBox(width: 12),
                Expanded(child: _buildCard('All Time', allTimeQuantity, allTimeEarned, Icons.all_inclusive_rounded, colorScheme, false)),
              ],
            );
          } else {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildCard('Current Draft', currentDraftQuantity, currentDraftEarned, Icons.edit_document, colorScheme, true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCard('Last 7 Days', weeklyQuantity, weeklyEarned, Icons.date_range_rounded, colorScheme, false)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCard('All Time', allTimeQuantity, allTimeEarned, Icons.all_inclusive_rounded, colorScheme, false),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildCard(String title, int quantity, double earned, IconData icon, ColorScheme colorScheme, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPrimary ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrimary ? colorScheme.primary.withValues(alpha: 0.3) : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: isPrimary ? colorScheme.primary : colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading && !isPrimary)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            Text(
              '${quantity} items',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isPrimary ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${earned.toStringAsFixed(2)} earned',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isPrimary ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8) : colorScheme.onSurfaceVariant,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
