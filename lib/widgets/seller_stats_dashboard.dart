import 'package:flutter/material.dart';
import 'package:alif_flow/utils/ui_helpers.dart';

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
    final iconColor = isPrimary ? colorScheme.onPrimary : colorScheme.primary;
    final bgDeco = isPrimary
        ? BoxDecoration(
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
          )
        : BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          );

    final titleColor = isPrimary ? colorScheme.onPrimary.withValues(alpha: 0.9) : colorScheme.onSurfaceVariant;
    final valueColor = isPrimary ? colorScheme.onPrimary : colorScheme.onSurface;
    final subValueColor = isPrimary ? colorScheme.onPrimary.withValues(alpha: 0.8) : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: bgDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPrimary ? colorScheme.onPrimary.withValues(alpha: 0.2) : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isLoading && !isPrimary)
            SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
            )
          else ...[
            Text(
              '${UiHelpers.formatNumber(quantity)} items',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: valueColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${UiHelpers.formatNumber(earned)} earned',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: subValueColor,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
