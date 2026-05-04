import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alif_flow/models/sales_entry.dart';

class ProductMovementCard extends StatefulWidget {
  final ProductMovement movement;
  final ValueChanged<ProductMovement> onChanged;

  const ProductMovementCard({
    super.key,
    required this.movement,
    required this.onChanged,
  });

  @override
  State<ProductMovementCard> createState() => _ProductMovementCardState();
}

class _ProductMovementCardState extends State<ProductMovementCard> {
  late final TextEditingController _movedController;
  late final TextEditingController _arrivalsController;
  late final TextEditingController _currentStockController;

  @override
  void initState() {
    super.initState();
    _movedController = TextEditingController(
      text: widget.movement.lastWeekMoved > 0
          ? widget.movement.lastWeekMoved.toString()
          : '',
    );
    _arrivalsController = TextEditingController(
      text: widget.movement.newArrivals > 0
          ? widget.movement.newArrivals.toString()
          : '',
    );
    _currentStockController = TextEditingController(
      text: widget.movement.manualCurrentStock != null
          ? widget.movement.manualCurrentStock.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _movedController.dispose();
    _arrivalsController.dispose();
    _currentStockController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    widget.onChanged(ProductMovement(
      lastWeekMoved: int.tryParse(_movedController.text) ?? 0,
      newArrivals: int.tryParse(_arrivalsController.text) ?? 0,
      manualCurrentStock: _currentStockController.text.isNotEmpty
          ? int.tryParse(_currentStockController.text)
          : null,
    ));
  }

  int get _calculatedStock {
    final arrivals = int.tryParse(_arrivalsController.text) ?? 0;
    final moved = int.tryParse(_movedController.text) ?? 0;
    final manual = _currentStockController.text.isNotEmpty
        ? int.tryParse(_currentStockController.text)
        : null;
    return manual ?? (arrivals - moved);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
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
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_shipping_outlined,
                    size: 20,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Product Movement',
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

            // Inputs Row
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: 'Moved Out',
                    hint: '0',
                    icon: Icons.outbox_outlined,
                    controller: _movedController,
                    colorScheme: colorScheme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    label: 'New Arrivals',
                    hint: '0',
                    icon: Icons.inbox_outlined,
                    controller: _arrivalsController,
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Currently Available (auto-calculated)
            _buildField(
              label: 'Currently Available',
              hint: _calculatedStock.toString(),
              icon: Icons.warehouse_outlined,
              controller: _currentStockController,
              colorScheme: colorScheme,
              isCalculated: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required ColorScheme colorScheme,
    bool isCalculated = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (isCalculated) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Auto',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: isCalculated
                ? colorScheme.tertiaryContainer.withValues(alpha: 0.2)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) {
            setState(() {});
            _notifyChange();
          },
        ),
      ],
    );
  }
}
