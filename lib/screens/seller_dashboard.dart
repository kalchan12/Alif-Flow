import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alif_flow/models/sales_entry.dart';
import 'package:alif_flow/models/product_price.dart';
import 'package:alif_flow/services/pricing_service.dart';
import 'package:alif_flow/utils/ui_helpers.dart';
import 'package:alif_flow/widgets/responsive_layout.dart';
import 'package:alif_flow/widgets/spreadsheet_table.dart';
import 'package:alif_flow/screens/pricing_screen.dart';
import 'package:alif_flow/screens/my_reports_screen.dart';
import 'package:alif_flow/theme/theme_provider.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  int _selectedIndex = 0;
  final PricingService _pricingService = PricingService();

  // --- State Variables ---
  bool _isLoading = true;
  List<ProductPrice> _allProducts = [];
  Map<String, List<ProductPrice>> _productsByCategory = {};

  // Sales & movement data per category
  final Map<String, List<SalesEntry>> _salesByCategory = {};
  final Map<String, List<ProductMovementEntry>> _movementByCategory = {};

  // Category display config
  final Map<String, String> _categoryDisplayNames = {
    'soap': 'Weekly Soap Sales',
    'special': 'Weekly Special Products',
    'paint': 'Weekly Paint Sales',
  };
  final Map<String, IconData> _categoryIcons = {
    'soap': Icons.clean_hands_outlined,
    'special': Icons.star_border_rounded,
    'paint': Icons.format_paint_outlined,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Load products from Supabase, then load cached sales/movement data.
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Fetch products from database
      _productsByCategory = await _pricingService.fetchProductsByCategory();
      _allProducts = _productsByCategory.values.expand((list) => list).toList();

      // 2. Load cached sales/movement data or initialize from products
      final prefs = await SharedPreferences.getInstance();

      for (final category in _productsByCategory.keys) {
        final products = _productsByCategory[category]!;

        // Try loading cached sales
        final salesJson = prefs.getString('${category}Sales');
        if (salesJson != null) {
          final List<dynamic> list = jsonDecode(salesJson);
          _salesByCategory[category] = list
              .map((e) => SalesEntry.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          // Initialize from product catalog
          _salesByCategory[category] = products
              .map((p) => SalesEntry(
                    productName: p.productName,
                    category: p.category,
                    unitPrice: p.unitPrice,
                  ))
              .toList();
        }

        // Try loading cached movement
        final movementJson = prefs.getString('${category}Movement');
        if (movementJson != null) {
          final List<dynamic> list = jsonDecode(movementJson);
          _movementByCategory[category] = list
              .map((e) => ProductMovementEntry.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          _movementByCategory[category] = products
              .map((p) => ProductMovementEntry(productName: p.productName))
              .toList();
        }

        // Always sync prices from database to sales entries
        _syncPricesForCategory(category);
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      // If fetch fails, try to use whatever cached data we have
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// Sync unit prices from the product catalog to sales entries.
  void _syncPricesForCategory(String category) {
    final sales = _salesByCategory[category];
    if (sales == null) return;

    for (final entry in sales) {
      final price = _pricingService.getPriceForProduct(entry.productName, _allProducts);
      if (price > 0) {
        entry.unitPrice = price;
      }
    }
  }

  Future<void> _saveCategoryLocally(String categoryKey) async {
    final sales = _salesByCategory[categoryKey];
    final movement = _movementByCategory[categoryKey];
    if (sales == null || movement == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        '${categoryKey}Sales', jsonEncode(sales.map((e) => e.toJson()).toList()));
    await prefs.setString('${categoryKey}Movement',
        jsonEncode(movement.map((e) => e.toJson()).toList()));

    if (mounted) {
      UiHelpers.showCustomToast(
        context,
        'Saved $categoryKey draft locally!',
      );
    }
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Dashboard'),
        actions: [
          ListenableBuilder(
            listenable: themeProvider,
            builder: (context, _) {
              return IconButton(
                icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: 'Toggle Theme',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              UiHelpers.showLogoutConfirmationDialog(context);
            },
          ),
        ],
      ),
      body: ResponsiveLayout(
        mobileBody: _buildBody(),
        tabletBody: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Sales Entry'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: Text('History'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.attach_money_rounded),
                  selectedIcon: Icon(Icons.attach_money_rounded),
                  label: Text('Pricing'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: ResponsiveLayout.isMobile(context)
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Sales Entry',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.attach_money_rounded),
                  selectedIcon: Icon(Icons.attach_money_rounded),
                  label: 'Pricing',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (_selectedIndex) {
      case 0:
        return _buildSalesEntryTab();
      case 1:
        return MyReportsScreen(
          onRegenerate: (data) {
            // Populate the sales entry tab with regenerated data
            final salesByCategory = data['salesByCategory'] as Map<String, List<SalesEntry>>;
            final movementByCategory = data['movementByCategory'] as Map<String, List<ProductMovementEntry>>;
            setState(() {
              _salesByCategory.clear();
              _movementByCategory.clear();
              _salesByCategory.addAll(salesByCategory);
              _movementByCategory.addAll(movementByCategory);
              _selectedIndex = 0; // Switch to Sales Entry tab
            });
          },
        );
      case 2:
        return const PricingScreen();
      default:
        return Center(
          child: Text('Content for tab $_selectedIndex'),
        );
    }
  }

  Widget _buildSalesEntryTab() {
    final colorScheme = Theme.of(context).colorScheme;
    final categories = _productsByCategory.keys.toList();

    return Column(
      children: [
        // Scrollable content
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < categories.length; i++) ...[
                          _buildCategorySection(
                            title: _categoryDisplayNames[categories[i]] ?? categories[i],
                            categoryKey: categories[i],
                            icon: _categoryIcons[categories[i]] ?? Icons.category,
                            salesEntries: _salesByCategory[categories[i]]!,
                            movementEntries: _movementByCategory[categories[i]]!,
                            colorScheme: colorScheme,
                          ),
                          if (i < categories.length - 1) const SizedBox(height: 48),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Sticky Footer
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
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
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _submitReport,
                        icon: const Icon(Icons.preview_rounded, size: 18),
                        label: const Text('Preview Report'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: colorScheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _submitReport,
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Submit Report'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection({
    required String title,
    required String categoryKey,
    required IconData icon,
    required List<SalesEntry> salesEntries,
    required List<ProductMovementEntry> movementEntries,
    required ColorScheme colorScheme,
  }) {
    final double totalSales =
        salesEntries.fold(0.0, (s, e) => s + e.totalPrice);
    final double totalReceived =
        salesEntries.fold(0.0, (s, e) => s + e.amountReceived);
    final double totalBalance = totalSales - totalReceived;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: icon,
          title: title,
          subtitle: '${salesEntries.length} items',
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 12),

        // Merged Spreadsheet Table
        SpreadsheetTable(
          onUpdateLocally: () => _saveCategoryLocally(categoryKey),
          columns: const [
            SpreadsheetColumn(
                header: 'Product Name', width: 140, isProductName: true, isReadOnly: true),
            SpreadsheetColumn(header: 'Qty', width: 70, isNumeric: true),
            SpreadsheetColumn(
                header: 'Price',
                width: 80,
                isNumeric: true,
                isReadOnly: true,
                isCalculated: true),
            SpreadsheetColumn(
                header: 'Total Sale',
                width: 90,
                isCalculated: true,
                isNumeric: true,
                isReadOnly: true),
            SpreadsheetColumn(header: 'Received', width: 90, isNumeric: true),
            SpreadsheetColumn(
                header: 'Balance',
                width: 90,
                isCalculated: true,
                isNumeric: true,
                isReadOnly: true),
            SpreadsheetColumn(header: 'Prev Stock', width: 90, isNumeric: true),
            SpreadsheetColumn(header: 'Moved', width: 80, isNumeric: true),
            SpreadsheetColumn(header: 'Added', width: 80, isNumeric: true),
            SpreadsheetColumn(
                header: 'Current Stock',
                width: 90,
                isCalculated: true,
                isNumeric: true,
                isReadOnly: true),
          ],
          rowCount: salesEntries.length,
          footerBuilder: (col) {
            switch (col) {
              case 0:
                return const CellData(value: 'TOTAL', hint: '', textColor: null);
              case 1:
                final sum =
                    salesEntries.fold<int>(0, (s, e) => s + e.quantitySold);
                return CellData(value: sum > 0 ? sum.toString() : '');
              case 2:
                return const CellData(value: '---');
              case 3:
                return CellData(
                    value:
                        totalSales > 0 ? totalSales.toStringAsFixed(2) : '');
              case 4:
                return CellData(
                    value: totalReceived > 0
                        ? totalReceived.toStringAsFixed(2)
                        : '');
              case 5:
                return CellData(
                  value: totalBalance != 0
                      ? totalBalance.toStringAsFixed(2)
                      : '',
                  textColor: totalBalance > 0
                      ? colorScheme.error
                      : (totalBalance < 0 ? colorScheme.primary : null),
                );
              case 6:
                final sum = movementEntries.fold<int>(
                    0, (s, e) => s + e.previousStock);
                return CellData(value: sum > 0 ? sum.toString() : '');
              case 7:
                final sum = movementEntries.fold<int>(
                    0, (s, e) => s + e.productsMoved);
                return CellData(value: sum > 0 ? sum.toString() : '');
              case 8:
                final sum = movementEntries.fold<int>(
                    0, (s, e) => s + e.newStockAdded);
                return CellData(value: sum > 0 ? sum.toString() : '');
              case 9:
                final sum = movementEntries.fold<int>(
                    0, (s, e) => s + e.currentStock);
                return CellData(value: sum > 0 ? sum.toString() : '');
              default:
                return const CellData();
            }
          },
          cellBuilder: (row, col) {
            final sales = salesEntries[row];
            final movement = movementEntries[row];
            switch (col) {
              case 0:
                return CellData(
                    value: sales.productName, hint: 'Product...');
              case 1:
                return CellData(
                    value: sales.quantitySold > 0
                        ? sales.quantitySold.toString()
                        : '',
                    hint: '0');
              case 2:
                return CellData(
                    value: sales.unitPrice > 0
                        ? sales.unitPrice.toStringAsFixed(2)
                        : '',
                    hint: '0.00');
              case 3:
                return CellData(
                    value: sales.totalPrice > 0
                        ? sales.totalPrice.toStringAsFixed(2)
                        : '',
                    hint: '0.00');
              case 4:
                return CellData(
                    value: sales.amountReceived > 0
                        ? sales.amountReceived.toStringAsFixed(2)
                        : '',
                    hint: '0.00');
              case 5:
                final bal = sales.balanceDue;
                return CellData(
                  value: bal != 0 ? bal.toStringAsFixed(2) : '',
                  hint: '0.00',
                  textColor: bal > 0
                      ? colorScheme.error
                      : (bal < 0 ? colorScheme.primary : null),
                );
              case 6:
                return CellData(
                    value: movement.previousStock > 0
                        ? movement.previousStock.toString()
                        : '',
                    hint: '0');
              case 7:
                return CellData(
                    value: movement.productsMoved > 0
                        ? movement.productsMoved.toString()
                        : '',
                    hint: '0');
              case 8:
                return CellData(
                    value: movement.newStockAdded > 0
                        ? movement.newStockAdded.toString()
                        : '',
                    hint: '0');
              case 9:
                return CellData(
                    value: movement.currentStock > 0
                        ? movement.currentStock.toString()
                        : '',
                    hint: '0');
              default:
                return const CellData();
            }
          },
          onCellChanged: (row, col, value) {
            setState(() {
              final sales = salesEntries[row];
              final movement = movementEntries[row];
              switch (col) {
                // col 0 (Product Name) is read-only
                case 1:
                  sales.quantitySold = int.tryParse(value) ?? 0;
                  break;
                // col 2 (Price) is read-only — auto-filled from pricing
                // col 3 (Total Sale) is calculated
                case 4:
                  sales.amountReceived = double.tryParse(value) ?? 0.0;
                  break;
                // col 5 (Balance) is calculated
                case 6:
                  movement.previousStock = int.tryParse(value) ?? 0;
                  break;
                case 7:
                  movement.productsMoved = int.tryParse(value) ?? 0;
                  break;
                case 8:
                  movement.newStockAdded = int.tryParse(value) ?? 0;
                  break;
                // col 9 (Current Stock) is calculated
              }
            });
          },
          onAddRow: () {
            // Not allowing add row since products come from database
            UiHelpers.showCustomToast(
              context,
              'Products are managed from the Pricing tab.',
            );
          },
          onDeleteRow: (index) {
            // Not allowing delete since products come from database
            UiHelpers.showCustomToast(
              context,
              'Products are managed from the Pricing tab.',
            );
          },
          canDeleteRows: false,
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme colorScheme,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 22, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submitReport() async {
    final allSales = <SalesEntry>[];
    final allMovement = <ProductMovementEntry>[];

    for (final category in _salesByCategory.keys) {
      allSales.addAll(_salesByCategory[category]!);
      allMovement.addAll(_movementByCategory[category]!);
    }

    final result = await Navigator.pushNamed(
      context,
      '/report-preview',
      arguments: {
        'salesEntries': allSales,
        'movementEntries': allMovement,
      },
    );

    if (result == true) {
      // Admin approved — clear the cache and reload fresh
      final prefs = await SharedPreferences.getInstance();
      for (final category in _productsByCategory.keys) {
        await prefs.remove('${category}Sales');
        await prefs.remove('${category}Movement');
      }

      setState(() {
        _isLoading = true;
      });
      await _loadData();
    }
  }
}
