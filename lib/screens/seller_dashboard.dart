import 'package:flutter/material.dart';
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
  late List<SalesEntry> _soapSales;
  late List<ProductMovementEntry> _soapMovement;
  late List<SalesEntry> _specialSales;
  late List<ProductMovementEntry> _specialMovement;
  late List<SalesEntry> _paintSales;
  late List<ProductMovementEntry> _paintMovement;

  @override
  void initState() {
    super.initState();
    _resetData();
  }

  void _resetData() {
    _soapSales = _initSoapSales();
    _soapMovement = _initSoapMovement();
    _specialSales = _initSpecialSales();
    _specialMovement = _initSpecialMovement();
    _paintSales = _initPaintSales();
    _paintMovement = _initPaintMovement();
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
                          title: '🧼 Weekly Soap Sales',
                          icon: Icons.clean_hands_outlined,
                          salesEntries: _soapSales,
                          movementEntries: _soapMovement,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 48),
                        
                        _buildCategorySection(
                          title: '✨ Special Products',
                          icon: Icons.star_border_rounded,
                          salesEntries: _specialSales,
                          movementEntries: _specialMovement,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 48),
                        
                        _buildCategorySection(
                          title: '🎨 Paint Sales',
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

        // Sales Spreadsheet Table
        SpreadsheetTable(
          columns: const [
            SpreadsheetColumn(header: 'Product Name', width: 140, isProductName: true),
            SpreadsheetColumn(header: 'Qty', width: 70, isNumeric: true),
            SpreadsheetColumn(header: 'Price', width: 80, isNumeric: true),
            SpreadsheetColumn(header: 'Total', width: 90, isCalculated: true, isNumeric: true, isReadOnly: true),
            SpreadsheetColumn(header: 'Received', width: 90, isNumeric: true),
            SpreadsheetColumn(header: 'Balance', width: 90, isCalculated: true, isNumeric: true, isReadOnly: true),
          ],
          rowCount: salesEntries.length,
          footerBuilder: (col) {
            switch (col) {
              case 0:
                return const CellData(value: 'TOTAL', hint: '', textColor: null);
              case 1:
                final sum = salesEntries.fold<int>(0, (s, e) => s + e.quantitySold);
                return CellData(value: sum > 0 ? sum.toString() : '');
              case 2:
                return const CellData(value: '---');
              case 3:
                return CellData(value: totalSales > 0 ? totalSales.toStringAsFixed(2) : '');
              case 4:
                return CellData(value: totalReceived > 0 ? totalReceived.toStringAsFixed(2) : '');
              case 5:
                return CellData(
                  value: totalBalance != 0 ? totalBalance.toStringAsFixed(2) : '',
                  textColor: totalBalance > 0 ? colorScheme.error : (totalBalance < 0 ? colorScheme.primary : null),
                );
              default:
                return const CellData();
            }
          },
          cellBuilder: (row, col) {
            final entry = salesEntries[row];
            switch (col) {
              case 0:
                return CellData(value: entry.productName, hint: 'Product...');
              case 1:
                return CellData(value: entry.quantitySold > 0 ? entry.quantitySold.toString() : '', hint: '0');
              case 2:
                return CellData(value: entry.unitPrice > 0 ? entry.unitPrice.toStringAsFixed(2) : '', hint: '0.00');
              case 3:
                return CellData(value: entry.totalPrice > 0 ? entry.totalPrice.toStringAsFixed(2) : '', hint: '0.00');
              case 4:
                return CellData(value: entry.amountReceived > 0 ? entry.amountReceived.toStringAsFixed(2) : '', hint: '0.00');
              case 5:
                final bal = entry.balanceDue;
                return CellData(
                  value: bal != 0 ? bal.toStringAsFixed(2) : '',
                  hint: '0.00',
                  textColor: bal > 0 ? colorScheme.error : (bal < 0 ? colorScheme.primary : null),
                );
              default:
                return const CellData();
            }
          },
          onCellChanged: (row, col, value) {
            setState(() {
              final entry = salesEntries[row];
              switch (col) {
                case 0:
                  entry.productName = value;
                  break;
                case 1:
                  entry.quantitySold = int.tryParse(value) ?? 0;
                  break;
                case 2:
                  entry.unitPrice = double.tryParse(value) ?? 0.0;
                  break;
                case 4:
                  entry.amountReceived = double.tryParse(value) ?? 0.0;
                  break;
              }
            });
          },
          onAddRow: () {
            setState(() => salesEntries.add(SalesEntry()));
          },
          onDeleteRow: (index) {
            if (salesEntries.length > 1) {
              setState(() => salesEntries.removeAt(index));
            }
          },
          canDeleteRows: true,
        ),
        const SizedBox(height: 24),

        // Movement Spreadsheet Table
        SpreadsheetTable(
          columns: const [
            SpreadsheetColumn(header: 'Product Name', width: 140, isProductName: true),
            SpreadsheetColumn(header: 'Prev Stock', width: 90, isNumeric: true),
            SpreadsheetColumn(header: 'Moved', width: 80, isNumeric: true),
            SpreadsheetColumn(header: 'Added', width: 80, isNumeric: true),
            SpreadsheetColumn(header: 'Current', width: 90, isCalculated: true, isNumeric: true, isReadOnly: true),
          ],
          rowCount: movementEntries.length,
          footerBuilder: (col) {
            switch (col) {
              case 0:
                return const CellData(value: 'TOTAL', hint: '', textColor: null);
              case 1:
                final sum = movementEntries.fold<int>(0, (s, e) => s + e.previousStock);
                return CellData(value: sum > 0 ? sum.toString() : '');
              case 2:
                final sum = movementEntries.fold<int>(0, (s, e) => s + e.productsMoved);
                return CellData(value: sum > 0 ? sum.toString() : '');
              case 3:
                final sum = movementEntries.fold<int>(0, (s, e) => s + e.newStockAdded);
                return CellData(value: sum > 0 ? sum.toString() : '');
              case 4:
                final sum = movementEntries.fold<int>(0, (s, e) => s + e.currentStock);
                return CellData(value: sum > 0 ? sum.toString() : '');
              default:
                return const CellData();
            }
          },
          cellBuilder: (row, col) {
            final entry = movementEntries[row];
            switch (col) {
              case 0:
                return CellData(value: entry.productName, hint: 'Product...');
              case 1:
                return CellData(value: entry.previousStock > 0 ? entry.previousStock.toString() : '', hint: '0');
              case 2:
                return CellData(value: entry.productsMoved > 0 ? entry.productsMoved.toString() : '', hint: '0');
              case 3:
                return CellData(value: entry.newStockAdded > 0 ? entry.newStockAdded.toString() : '', hint: '0');
              case 4:
                return CellData(value: entry.currentStock > 0 ? entry.currentStock.toString() : '', hint: '0');
              default:
                return const CellData();
            }
          },
          onCellChanged: (row, col, value) {
            setState(() {
              final entry = movementEntries[row];
              switch (col) {
                case 0:
                  entry.productName = value;
                  break;
                case 1:
                  entry.previousStock = int.tryParse(value) ?? 0;
                  break;
                case 2:
                  entry.productsMoved = int.tryParse(value) ?? 0;
                  break;
                case 3:
                  entry.newStockAdded = int.tryParse(value) ?? 0;
                  break;
              }
            });
          },
          onAddRow: () {
             setState(() => movementEntries.add(ProductMovementEntry()));
          },
          onDeleteRow: (index) {
            if (movementEntries.length > 1) {
              setState(() => movementEntries.removeAt(index));
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
      setState(() {
         _resetData();
      });
    }
  }
}
