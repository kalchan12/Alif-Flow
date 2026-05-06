import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alif_flow/models/product_price.dart';
import 'package:alif_flow/services/pricing_service.dart';
import 'package:alif_flow/services/auth_service.dart';
import 'package:alif_flow/utils/ui_helpers.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  final PricingService _pricingService = PricingService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, List<ProductPrice>> _productsByCategory = {};

  // Track edited prices: productId -> new price controller
  final Map<String, TextEditingController> _priceControllers = {};

  bool get _isAdmin => _authService.currentUserRole == 'Admin';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final grouped = await _pricingService.fetchProductsByCategory();
      
      // Create controllers for each product
      _priceControllers.clear();
      for (final products in grouped.values) {
        for (final product in products) {
          _priceControllers[product.id] = TextEditingController(
            text: product.unitPrice > 0 ? UiHelpers.formatNumber(product.unitPrice) : '',
          );
        }
      }

      setState(() {
        _productsByCategory = grouped;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        UiHelpers.showCustomToast(context, 'Failed to load products: $e', isError: true);
      }
    }
  }

  Future<void> _saveAllPrices() async {
    setState(() => _isSaving = true);

    try {
      int updatedCount = 0;
      int requestedCount = 0;

      for (final products in _productsByCategory.values) {
        for (final product in products) {
          final controller = _priceControllers[product.id];
          if (controller == null) continue;

          final newPrice = double.tryParse(controller.text.replaceAll(',', '')) ?? 0.0;
          if (newPrice == product.unitPrice) continue; // No change

          if (_isAdmin) {
            // Admin: directly update
            await _pricingService.updatePriceAsAdmin(product.id, newPrice);
            product.unitPrice = newPrice;
            updatedCount++;
          } else {
            // Seller: submit a change request
            await _pricingService.requestPriceChange(
              productId: product.id,
              oldPrice: product.unitPrice,
              newPrice: newPrice,
            );
            requestedCount++;
          }
        }
      }

      if (mounted) {
        if (_isAdmin && updatedCount > 0) {
          UiHelpers.showCustomToast(context, 'Updated $updatedCount product price(s).');
        } else if (!_isAdmin && requestedCount > 0) {
          UiHelpers.showCustomToast(context, 'Submitted $requestedCount price change request(s) for admin approval.');
        } else {
          UiHelpers.showCustomToast(context, 'No price changes detected.');
        }
      }
    } catch (e) {
      if (mounted) {
        UiHelpers.showCustomToast(context, 'Error saving prices: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_productsByCategory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              'Products will appear here once added to the database.',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    final categoryDisplayNames = {
      'soap': 'Soap Products',
      'special': 'Special Products',
      'paint': 'Paint Products',
    };

    final categoryIcons = {
      'soap': Icons.clean_hands_outlined,
      'special': Icons.star_border_rounded,
      'paint': Icons.format_paint_outlined,
    };

    return Column(
      children: [
        // Header bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.attach_money_rounded, size: 22, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product Pricing',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          _isAdmin ? 'Set prices directly' : 'Propose price changes',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isAdmin)
                    IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/admin-price-requests').then((_) => _loadProducts());
                      },
                      icon: Icon(Icons.pending_actions, color: colorScheme.primary),
                      tooltip: 'View Pending Requests',
                    ),
                  IconButton(
                    onPressed: _loadProducts,
                    icon: Icon(Icons.refresh_rounded, color: colorScheme.primary),
                    tooltip: 'Refresh prices',
                  ),
                ],
              ),
            ),
          ),
        ),

        // Product list
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    for (final category in _productsByCategory.keys) ...[
                      _buildCategoryCard(
                        category: category,
                        displayName: categoryDisplayNames[category] ?? category,
                        icon: categoryIcons[category] ?? Icons.category,
                        products: _productsByCategory[category]!,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 80), // Space for button
                  ],
                ),
              ),
            ),
          ),
        ),

        // Save button footer
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveAllPrices,
                    icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(_isAdmin ? Icons.save_rounded : Icons.send_rounded, size: 18),
                    label: Text(
                      _isSaving
                          ? 'Saving...'
                          : (_isAdmin ? 'Save Prices' : 'Submit Price Changes'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required String category,
    required String displayName,
    required IconData icon,
    required List<ProductPrice> products,
    required ColorScheme colorScheme,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '${products.length} items',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Product rows
          for (int i = 0; i < products.length; i++) ...[
            _buildProductRow(products[i], colorScheme, isLast: i == products.length - 1),
          ],
        ],
      ),
    );
  }

  Widget _buildProductRow(ProductPrice product, ColorScheme colorScheme, {bool isLast = false}) {
    final controller = _priceControllers[product.id];
    final updatedText = product.updatedAt != null
        ? '${product.updatedAt!.year}-${product.updatedAt!.month.toString().padLeft(2, '0')}-${product.updatedAt!.day.toString().padLeft(2, '0')}'
        : 'Not set';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.15))),
      ),
      child: Row(
        children: [
          // Product name
          Expanded(
            flex: 3,
            child: Text(
              product.productName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),

          // Price input + updated date
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      fontSize: 14,
                    ),
                    prefixText: '\$ ',
                    prefixStyle: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                updatedText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
