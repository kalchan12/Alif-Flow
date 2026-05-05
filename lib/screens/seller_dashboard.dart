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

  // Sales data
  final List<SalesEntry> _salesEntries = [
    SalesEntry(productName: '5 Litre Soap'),
    SalesEntry(productName: '2 Litre Soap'),
    SalesEntry(productName: '1 Litre Soap'),
    SalesEntry(productName: 'Unbottled Soap'),
  ];
  final List<ProductMovementEntry> _movementEntries = [
    ProductMovementEntry(productName: '5 Litre Soap'),
    ProductMovementEntry(productName: '2 Litre Soap'),
    ProductMovementEntry(productName: '1 Litre Soap'),
    ProductMovementEntry(productName: 'Unbottled Soap'),
  ];


  // --- Entry Management ---

  void _addSalesEntry() {
    setState(() {
      _salesEntries.add(SalesEntry());
    });
  }

  void _removeSalesEntry(int index) {
    if (_salesEntries.length > 1) {
      setState(() {
        _salesEntries.removeAt(index);
      });
    }
  }

  void _addMovementEntry() {
    setState(() {
      _movementEntries.add(ProductMovementEntry());
    });
  }

  void _removeMovementEntry(int index) {
    if (_movementEntries.length > 1) {
      setState(() {
        _movementEntries.removeAt(index);
      });
    }
  }

  // --- Computed Summary ---

  double get _totalSales =>
      _salesEntries.fold(0.0, (sum, e) => sum + e.totalPrice);

  double get _totalReceived =>
      _salesEntries.fold(0.0, (sum, e) => sum + e.amountReceived);

  double get _totalBalance => _totalSales - _totalReceived;

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
                        // Section Header: Sales Entry
                        _buildSectionHeader(
                          icon: Icons.receipt_long_outlined,
                          title: 'Weekly Sales Entry',
                          subtitle: '${_salesEntries.length} product(s)',
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
                          rowCount: _salesEntries.length,
                          footerBuilder: (col) {
                            switch (col) {
                              case 0:
                                return const CellData(value: 'TOTAL', hint: '', textColor: null);
                              case 1:
                                final sum = _salesEntries.fold<int>(0, (s, e) => s + e.quantitySold);
                                return CellData(value: sum > 0 ? sum.toString() : '');
                              case 2:
                                return const CellData(value: '---');
                              case 3:
                                return CellData(value: _totalSales > 0 ? _totalSales.toStringAsFixed(2) : '');
                              case 4:
                                return CellData(value: _totalReceived > 0 ? _totalReceived.toStringAsFixed(2) : '');
                              case 5:
                                return CellData(
                                  value: _totalBalance != 0 ? _totalBalance.toStringAsFixed(2) : '',
                                  textColor: _totalBalance > 0 ? colorScheme.error : (_totalBalance < 0 ? colorScheme.primary : null),
                                );
                              default:
                                return const CellData();
                            }
                          },
                          cellBuilder: (row, col) {
                            final entry = _salesEntries[row];
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
                              final entry = _salesEntries[row];
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
                          onAddRow: _addSalesEntry,
                          onDeleteRow: _removeSalesEntry,
                          canDeleteRows: true,
                        ),
                        const SizedBox(height: 32),

                        // Product Movement Section
                        _buildSectionHeader(
                          icon: Icons.local_shipping_outlined,
                          title: 'Product Movement',
                          subtitle: '${_movementEntries.length} product(s) inventory',
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 12),
                        
                        // Movement Spreadsheet Table
                        SpreadsheetTable(
                          columns: const [
                            SpreadsheetColumn(header: 'Product Name', width: 140, isProductName: true),
                            SpreadsheetColumn(header: 'Prev Stock', width: 90, isNumeric: true),
                            SpreadsheetColumn(header: 'Moved', width: 80, isNumeric: true),
                            SpreadsheetColumn(header: 'Added', width: 80, isNumeric: true),
                            SpreadsheetColumn(header: 'Current', width: 90, isCalculated: true, isNumeric: true, isReadOnly: true),
                          ],
                          rowCount: _movementEntries.length,
                          footerBuilder: (col) {
                            switch (col) {
                              case 0:
                                return const CellData(value: 'TOTAL', hint: '', textColor: null);
                              case 1:
                                final sum = _movementEntries.fold<int>(0, (s, e) => s + e.previousStock);
                                return CellData(value: sum > 0 ? sum.toString() : '');
                              case 2:
                                final sum = _movementEntries.fold<int>(0, (s, e) => s + e.productsMoved);
                                return CellData(value: sum > 0 ? sum.toString() : '');
                              case 3:
                                final sum = _movementEntries.fold<int>(0, (s, e) => s + e.newStockAdded);
                                return CellData(value: sum > 0 ? sum.toString() : '');
                              case 4:
                                final sum = _movementEntries.fold<int>(0, (s, e) => s + e.currentStock);
                                return CellData(value: sum > 0 ? sum.toString() : '');
                              default:
                                return const CellData();
                            }
                          },
                          cellBuilder: (row, col) {
                            final entry = _movementEntries[row];
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
                              final entry = _movementEntries[row];
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
                          onAddRow: _addMovementEntry,
                          onDeleteRow: _removeMovementEntry,
                          canDeleteRows: true,
                        ),
                        const SizedBox(height: 32),

                        const SizedBox(height: 16),
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

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme colorScheme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 22, color: colorScheme.primary),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }


  Future<void> _submitReport() async {
    final result = await Navigator.pushNamed(
      context, 
      '/report-preview',
      arguments: {
        'salesEntries': _salesEntries,
        'movementEntries': _movementEntries,
      },
    );

    if (result == true) {
      setState(() {
        _salesEntries.clear();
        _salesEntries.addAll([
          SalesEntry(productName: '5 Litre Soap'),
          SalesEntry(productName: '2 Litre Soap'),
          SalesEntry(productName: '1 Litre Soap'),
          SalesEntry(productName: 'Unbottled Soap'),
        ]);
        _movementEntries.clear();
        _movementEntries.addAll([
          ProductMovementEntry(productName: '5 Litre Soap'),
          ProductMovementEntry(productName: '2 Litre Soap'),
          ProductMovementEntry(productName: '1 Litre Soap'),
          ProductMovementEntry(productName: 'Unbottled Soap'),
        ]);
      });
    }
  }
}
