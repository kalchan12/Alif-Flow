import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alif_flow/models/sales_entry.dart';
import 'package:alif_flow/utils/ui_helpers.dart';
import 'package:alif_flow/widgets/responsive_layout.dart';
import 'package:alif_flow/widgets/spreadsheet_table.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  int _selectedIndex = 0;

  // --- Initializers ---
  List<SalesEntry> _initSoapSales() => [
    SalesEntry(productName: '5 Litre Soap'),
    SalesEntry(productName: '2 Litre Soap'),
    SalesEntry(productName: '1 Litre Soap'),
    SalesEntry(productName: 'Unbottled Soap'),
  ];
  List<ProductMovementEntry> _initSoapMovement() => _initSoapSales()
      .map((e) => ProductMovementEntry(productName: e.productName)).toList();

  List<SalesEntry> _initSpecialSales() => [
    SalesEntry(productName: '5 Litre Detergent'),
    SalesEntry(productName: '2 Litre Detergent'),
    SalesEntry(productName: '1 Litre Detergent'),
    SalesEntry(productName: 'Unbottled Detergent'),
    SalesEntry(productName: 'Varnish 1 Litre'),
    SalesEntry(productName: 'Kola 3.5'),
    SalesEntry(productName: '16kg Kola'),
  ];
  List<ProductMovementEntry> _initSpecialMovement() => _initSpecialSales()
      .map((e) => ProductMovementEntry(productName: e.productName)).toList();

  List<SalesEntry> _initPaintSales() => [
    SalesEntry(productName: 'Wubet 3.5 L unit'),
    SalesEntry(productName: 'Wubet 2.5 L Packed'),
    SalesEntry(productName: 'Super 3.5 unit'),
    SalesEntry(productName: 'Super 3.5 packed'),
    SalesEntry(productName: 'Super 20kg'),
    SalesEntry(productName: '200 ml bar soap'),
  ];
  List<ProductMovementEntry> _initPaintMovement() => _initPaintSales()
      .map((e) => ProductMovementEntry(productName: e.productName)).toList();

  // --- State Variables ---
  bool _isLoading = true;
  late List<SalesEntry> _soapSales;
  late List<ProductMovementEntry> _soapMovement;
  late List<SalesEntry> _specialSales;
  late List<ProductMovementEntry> _specialMovement;
  late List<SalesEntry> _paintSales;
  late List<ProductMovementEntry> _paintMovement;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Helper to load list
    List<T> loadList<T>(String key, T Function(Map<String, dynamic>) fromJson, List<T> Function() defaultInit) {
      final String? jsonStr = prefs.getString(key);
      if (jsonStr != null) {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        return jsonList.map((e) => fromJson(e as Map<String, dynamic>)).toList();
      }
      return defaultInit();
    }

    setState(() {
      _soapSales = loadList('soapSales', SalesEntry.fromJson, _initSoapSales);
      _soapMovement = loadList('soapMovement', ProductMovementEntry.fromJson, _initSoapMovement);
      _specialSales = loadList('specialSales', SalesEntry.fromJson, _initSpecialSales);
      _specialMovement = loadList('specialMovement', ProductMovementEntry.fromJson, _initSpecialMovement);
      _paintSales = loadList('paintSales', SalesEntry.fromJson, _initPaintSales);
      _paintMovement = loadList('paintMovement', ProductMovementEntry.fromJson, _initPaintMovement);
      _isLoading = false;
    });
  }

  Future<void> _saveCategoryLocally(String categoryKey, List<SalesEntry> sales, List<ProductMovementEntry> movement) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${categoryKey}Sales', jsonEncode(sales.map((e) => e.toJson()).toList()));
    await prefs.setString('${categoryKey}Movement', jsonEncode(movement.map((e) => e.toJson()).toList()));
    
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
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('Profile'),
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
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
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
    if (_selectedIndex == 0) {
      return _buildSalesEntryTab();
    } else {
      return Center(
        child: Text('Content for tab $_selectedIndex'),
      );
    }
  }

  Widget _buildSalesEntryTab() {
    final colorScheme = Theme.of(context).colorScheme;

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
                        _buildCategorySection(
                          title: 'Weekly Soap Sales',
                          categoryKey: 'soap',
                          icon: Icons.clean_hands_outlined,
                          salesEntries: _soapSales,
                          movementEntries: _soapMovement,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 48),
                        
                        _buildCategorySection(
                          title: 'Weekly Special Products',
                          categoryKey: 'special',
                          icon: Icons.star_border_rounded,
                          salesEntries: _specialSales,
                          movementEntries: _specialMovement,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 48),
                        
                        _buildCategorySection(
                          title: 'Weekly Paint Sales',
                          categoryKey: 'paint',
                          icon: Icons.format_paint_outlined,
                          salesEntries: _paintSales,
                          movementEntries: _paintMovement,
                          colorScheme: colorScheme,
                        ),
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
    final double totalSales = salesEntries.fold(0.0, (s, e) => s + e.totalPrice);
    final double totalReceived = salesEntries.fold(0.0, (s, e) => s + e.amountReceived);
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
          onUpdateLocally: () => _saveCategoryLocally(categoryKey, salesEntries, movementEntries),
          columns: const [
            SpreadsheetColumn(header: 'Product Name', width: 140, isProductName: true),
            SpreadsheetColumn(header: 'Qty', width: 70, isNumeric: true),
            SpreadsheetColumn(header: 'Price', width: 80, isNumeric: true),
            SpreadsheetColumn(header: 'Total Sale', width: 90, isCalculated: true, isNumeric: true, isReadOnly: true),
            SpreadsheetColumn(header: 'Received', width: 90, isNumeric: true),
            SpreadsheetColumn(header: 'Balance', width: 90, isCalculated: true, isNumeric: true, isReadOnly: true),
            SpreadsheetColumn(header: 'Prev Stock', width: 90, isNumeric: true),
            SpreadsheetColumn(header: 'Moved', width: 80, isNumeric: true),
            SpreadsheetColumn(header: 'Added', width: 80, isNumeric: true),
            SpreadsheetColumn(header: 'Current Stock', width: 90, isCalculated: true, isNumeric: true, isReadOnly: true),
          ],
          rowCount: salesEntries.length,
          footerBuilder: (col) {
            switch (col) {
              case 0: return const CellData(value: 'TOTAL', hint: '', textColor: null);
              case 1:
                final sum = salesEntries.fold<int>(0, (s, e) => s + e.quantitySold);
                return CellData(value: sum > 0 ? sum.toString() : '');
              case 2: return const CellData(value: '---');
              case 3: return CellData(value: totalSales > 0 ? totalSales.toStringAsFixed(2) : '');
              case 4: return CellData(value: totalReceived > 0 ? totalReceived.toStringAsFixed(2) : '');
              case 5: return CellData(
                  value: totalBalance != 0 ? totalBalance.toStringAsFixed(2) : '',
                  textColor: totalBalance > 0 ? colorScheme.error : (totalBalance < 0 ? colorScheme.primary : null),
                );
              case 6:
                final sum = movementEntries.fold<int>(0, (s, e) => s + e.previousStock);
                return CellData(value: sum > 0 ? sum.toString() : '');
              case 7:
                final sum = movementEntries.fold<int>(0, (s, e) => s + e.productsMoved);
                return CellData(value: sum > 0 ? sum.toString() : '');
              case 8:
                final sum = movementEntries.fold<int>(0, (s, e) => s + e.newStockAdded);
                return CellData(value: sum > 0 ? sum.toString() : '');
              case 9:
                final sum = movementEntries.fold<int>(0, (s, e) => s + e.currentStock);
                return CellData(value: sum > 0 ? sum.toString() : '');
              default: return const CellData();
            }
          },
          cellBuilder: (row, col) {
            final sales = salesEntries[row];
            final movement = movementEntries[row];
            switch (col) {
              case 0: return CellData(value: sales.productName, hint: 'Product...');
              case 1: return CellData(value: sales.quantitySold > 0 ? sales.quantitySold.toString() : '', hint: '0');
              case 2: return CellData(value: sales.unitPrice > 0 ? sales.unitPrice.toStringAsFixed(2) : '', hint: '0.00');
              case 3: return CellData(value: sales.totalPrice > 0 ? sales.totalPrice.toStringAsFixed(2) : '', hint: '0.00');
              case 4: return CellData(value: sales.amountReceived > 0 ? sales.amountReceived.toStringAsFixed(2) : '', hint: '0.00');
              case 5:
                final bal = sales.balanceDue;
                return CellData(
                  value: bal != 0 ? bal.toStringAsFixed(2) : '',
                  hint: '0.00',
                  textColor: bal > 0 ? colorScheme.error : (bal < 0 ? colorScheme.primary : null),
                );
              case 6: return CellData(value: movement.previousStock > 0 ? movement.previousStock.toString() : '', hint: '0');
              case 7: return CellData(value: movement.productsMoved > 0 ? movement.productsMoved.toString() : '', hint: '0');
              case 8: return CellData(value: movement.newStockAdded > 0 ? movement.newStockAdded.toString() : '', hint: '0');
              case 9: return CellData(value: movement.currentStock > 0 ? movement.currentStock.toString() : '', hint: '0');
              default: return const CellData();
            }
          },
          onCellChanged: (row, col, value) {
            setState(() {
              final sales = salesEntries[row];
              final movement = movementEntries[row];
              switch (col) {
                case 0: 
                  sales.productName = value; 
                  movement.productName = value;
                  break;
                case 1: sales.quantitySold = int.tryParse(value) ?? 0; break;
                case 2: sales.unitPrice = double.tryParse(value) ?? 0.0; break;
                case 4: sales.amountReceived = double.tryParse(value) ?? 0.0; break;
                case 6: movement.previousStock = int.tryParse(value) ?? 0; break;
                case 7: movement.productsMoved = int.tryParse(value) ?? 0; break;
                case 8: movement.newStockAdded = int.tryParse(value) ?? 0; break;
              }
            });
          },
          onAddRow: () {
            setState(() {
              salesEntries.add(SalesEntry());
              movementEntries.add(ProductMovementEntry());
            });
          },
          onDeleteRow: (index) {
            if (salesEntries.length > 1) {
              setState(() {
                salesEntries.removeAt(index);
                movementEntries.removeAt(index);
              });
            }
          },
          canDeleteRows: true,
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
    final allSales = [..._soapSales, ..._specialSales, ..._paintSales];
    final allMovement = [..._soapMovement, ..._specialMovement, ..._paintMovement];

    final result = await Navigator.pushNamed(
      context, 
      '/report-preview',
      arguments: {
        'salesEntries': allSales,
        'movementEntries': allMovement,
      },
    );

    if (result == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all drafts

      setState(() {
         _isLoading = true;
      });
      await _loadSavedData();
    }
  }
}
