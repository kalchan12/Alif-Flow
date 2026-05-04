import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alif_flow/models/sales_entry.dart';

class SalesEntryCard extends StatefulWidget {
  final SalesEntry entry;
  final int index;
  final List<String> productSuggestions;
  final List<String> categorySuggestions;
  final VoidCallback onRemove;
  final VoidCallback onDuplicate;
  final ValueChanged<SalesEntry> onChanged;

  const SalesEntryCard({
    super.key,
    required this.entry,
    required this.index,
    required this.productSuggestions,
    required this.categorySuggestions,
    required this.onRemove,
    required this.onDuplicate,
    required this.onChanged,
  });

  @override
  State<SalesEntryCard> createState() => _SalesEntryCardState();
}

class _SalesEntryCardState extends State<SalesEntryCard>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _productController;
  late final TextEditingController _categoryController;
  late final TextEditingController _qtyController;
  late final TextEditingController _unitPriceController;
  late final TextEditingController _totalController;
  late final TextEditingController _receivedController;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _productController = TextEditingController(text: widget.entry.productName);
    _categoryController = TextEditingController(text: widget.entry.category);
    _qtyController = TextEditingController(
      text: widget.entry.quantitySold > 0 ? widget.entry.quantitySold.toString() : '',
    );
    _unitPriceController = TextEditingController(
      text: widget.entry.unitPrice > 0 ? widget.entry.unitPrice.toStringAsFixed(2) : '',
    );
    _totalController = TextEditingController(
      text: widget.entry.manualTotal != null
          ? widget.entry.manualTotal!.toStringAsFixed(2)
          : '',
    );
    _receivedController = TextEditingController(
      text: widget.entry.amountReceived > 0
          ? widget.entry.amountReceived.toStringAsFixed(2)
          : '',
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _productController.dispose();
    _categoryController.dispose();
    _qtyController.dispose();
    _unitPriceController.dispose();
    _totalController.dispose();
    _receivedController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    final qty = int.tryParse(_qtyController.text) ?? 0;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;
    final manualTotal = _totalController.text.isNotEmpty
        ? double.tryParse(_totalController.text)
        : null;
    final received = double.tryParse(_receivedController.text) ?? 0.0;

    widget.onChanged(SalesEntry(
      id: widget.entry.id,
      productName: _productController.text,
      category: _categoryController.text,
      quantitySold: qty,
      unitPrice: unitPrice,
      manualTotal: manualTotal,
      amountReceived: received,
    ));
  }

  double get _calculatedTotal {
    final qty = int.tryParse(_qtyController.text) ?? 0;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;
    final manualTotal = _totalController.text.isNotEmpty
        ? double.tryParse(_totalController.text)
        : null;
    return manualTotal ?? (qty * unitPrice);
  }

  double get _balanceDue {
    final received = double.tryParse(_receivedController.text) ?? 0.0;
    return _calculatedTotal - received;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            // Card Header
            InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${widget.index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _productController.text.isNotEmpty
                            ? _productController.text
                            : 'Product ${widget.index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Duplicate button
                    IconButton(
                      icon: Icon(Icons.copy_rounded, size: 18, color: colorScheme.primary),
                      onPressed: widget.onDuplicate,
                      tooltip: 'Duplicate',
                      visualDensity: VisualDensity.compact,
                    ),
                    // Remove button
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, size: 18, color: colorScheme.error),
                      onPressed: widget.onRemove,
                      tooltip: 'Remove',
                      visualDensity: VisualDensity.compact,
                    ),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),

            // Card Body
            AnimatedCrossFade(
              firstChild: _buildCardBody(colorScheme),
              secondChild: const SizedBox.shrink(),
              crossFadeState:
                  _isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 250),
              sizeCurve: Curves.easeInOut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBody(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Product Name (Autocomplete)
          _buildLabel('Product Name', colorScheme),
          const SizedBox(height: 6),
          Autocomplete<String>(
            initialValue: _productController.value,
            optionsBuilder: (TextEditingValue value) {
              if (value.text.isEmpty) return widget.productSuggestions;
              return widget.productSuggestions.where(
                (s) => s.toLowerCase().contains(value.text.toLowerCase()),
              );
            },
            onSelected: (String selection) {
              _productController.text = selection;
              _notifyChange();
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              // Sync controller text
              if (controller.text != _productController.text) {
                controller.text = _productController.text;
              }
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: _inputDecoration(
                  hint: 'Select or type product name',
                  icon: Icons.inventory_2_outlined,
                  colorScheme: colorScheme,
                ),
                onChanged: (v) {
                  _productController.text = v;
                  _notifyChange();
                },
                textInputAction: TextInputAction.next,
              );
            },
          ),
          const SizedBox(height: 14),

          // Category (Autocomplete)
          _buildLabel('Category', colorScheme),
          const SizedBox(height: 6),
          Autocomplete<String>(
            initialValue: _categoryController.value,
            optionsBuilder: (TextEditingValue value) {
              if (value.text.isEmpty) return widget.categorySuggestions;
              return widget.categorySuggestions.where(
                (s) => s.toLowerCase().contains(value.text.toLowerCase()),
              );
            },
            onSelected: (String selection) {
              _categoryController.text = selection;
              _notifyChange();
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              if (controller.text != _categoryController.text) {
                controller.text = _categoryController.text;
              }
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: _inputDecoration(
                  hint: 'Select or type category',
                  icon: Icons.category_outlined,
                  colorScheme: colorScheme,
                ),
                onChanged: (v) {
                  _categoryController.text = v;
                  _notifyChange();
                },
                textInputAction: TextInputAction.next,
              );
            },
          ),
          const SizedBox(height: 14),

          // Quantity Sold & Unit Price (side by side)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Quantity Sold', colorScheme),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _qtyController,
                      decoration: _inputDecoration(
                        hint: '0',
                        icon: Icons.numbers,
                        colorScheme: colorScheme,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) {
                        setState(() {});
                        _notifyChange();
                      },
                      textInputAction: TextInputAction.next,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Unit Price', colorScheme),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _unitPriceController,
                      decoration: _inputDecoration(
                        hint: '0.00',
                        icon: Icons.attach_money,
                        colorScheme: colorScheme,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      onChanged: (_) {
                        setState(() {});
                        _notifyChange();
                      },
                      textInputAction: TextInputAction.next,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Total Price (auto-calculated with manual override)
          _buildLabel('Total Price', colorScheme, isCalculated: true),
          const SizedBox(height: 6),
          TextField(
            controller: _totalController,
            decoration: _inputDecoration(
              hint: _calculatedTotal.toStringAsFixed(2),
              icon: Icons.calculate_outlined,
              colorScheme: colorScheme,
              isCalculated: true,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            onChanged: (_) {
              setState(() {});
              _notifyChange();
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),

          // Amount Received
          _buildLabel('Amount Received', colorScheme),
          const SizedBox(height: 6),
          TextField(
            controller: _receivedController,
            decoration: _inputDecoration(
              hint: '0.00',
              icon: Icons.payments_outlined,
              colorScheme: colorScheme,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            onChanged: (_) {
              setState(() {});
              _notifyChange();
            },
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16),

          // Balance Due (read-only highlight)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _balanceDue > 0
                  ? colorScheme.errorContainer.withValues(alpha: 0.4)
                  : colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _balanceDue > 0
                    ? colorScheme.error.withValues(alpha: 0.3)
                    : colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _balanceDue > 0
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      size: 18,
                      color: _balanceDue > 0
                          ? colorScheme.error
                          : colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Balance Due',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Text(
                  _balanceDue.toStringAsFixed(2),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _balanceDue > 0
                        ? colorScheme.error
                        : colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, ColorScheme colorScheme, {bool isCalculated = false}) {
    return Row(
      children: [
        Text(
          text,
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
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required ColorScheme colorScheme,
    bool isCalculated = false,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: isCalculated
          ? colorScheme.tertiaryContainer.withValues(alpha: 0.2)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );
  }
}
