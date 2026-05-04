import 'package:flutter/material.dart';
import 'package:alif_flow/models/sales_entry.dart';
import 'package:alif_flow/utils/ui_helpers.dart';
import 'package:alif_flow/widgets/responsive_layout.dart';
import 'package:alif_flow/widgets/sales_entry_card.dart';
import 'package:alif_flow/widgets/product_movement_card.dart';
import 'package:alif_flow/widgets/summary_card.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  int _selectedIndex = 0;

  // Sales data
  final List<SalesEntry> _salesEntries = [SalesEntry()];
  ProductMovement _productMovement = ProductMovement();

  // Dynamic product/category suggestions (grow as users type new ones)
  final List<String> _productSuggestions = [
    '5 Litre Soap',
    '2 Litre Soap',
    '1 Litre Soap',
    'Unbottled Soap',
  ];
  final List<String> _categorySuggestions = [
    'Liquid Soap',
    'Bar Soap',
    'Detergent',
    'Cleaning Supplies',
  ];

  // --- Entry Management ---

  void _addEntry() {
    setState(() {
      _salesEntries.add(SalesEntry());
    });
  }

  void _removeEntry(int index) {
    if (_salesEntries.length > 1) {
      setState(() {
        _salesEntries.removeAt(index);
      });
    }
  }

  void _duplicateEntry(int index) {
    final source = _salesEntries[index];
    setState(() {
      _salesEntries.insert(
        index + 1,
        SalesEntry(
          productName: source.productName,
          category: source.category,
          quantitySold: source.quantitySold,
          unitPrice: source.unitPrice,
          manualTotal: source.manualTotal,
          amountReceived: source.amountReceived,
        ),
      );
    });
  }

  void _updateEntry(int index, SalesEntry updated) {
    setState(() {
      _salesEntries[index] = updated;

      // Auto-add new product/category suggestions
      if (updated.productName.isNotEmpty &&
          !_productSuggestions.contains(updated.productName)) {
        _productSuggestions.add(updated.productName);
      }
      if (updated.category.isNotEmpty &&
          !_categorySuggestions.contains(updated.category)) {
        _categorySuggestions.add(updated.category);
      }
    });
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

                        // Dynamic Sales Entry Cards
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _salesEntries.length,
                          itemBuilder: (context, index) {
                            return SalesEntryCard(
                              key: ValueKey(_salesEntries[index].id),
                              entry: _salesEntries[index],
                              index: index,
                              productSuggestions: _productSuggestions,
                              categorySuggestions: _categorySuggestions,
                              onRemove: () => _removeEntry(index),
                              onDuplicate: () => _duplicateEntry(index),
                              onChanged: (updated) =>
                                  _updateEntry(index, updated),
                            );
                          },
                        ),

                        // Add Product Button
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: OutlinedButton.icon(
                              onPressed: _addEntry,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add Product'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: colorScheme.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Product Movement Section
                        _buildSectionHeader(
                          icon: Icons.local_shipping_outlined,
                          title: 'Product Movement',
                          subtitle: 'Weekly inventory',
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 12),
                        ProductMovementCard(
                          movement: _productMovement,
                          onChanged: (updated) {
                            setState(() {
                              _productMovement = updated;
                            });
                          },
                        ),
                        const SizedBox(height: 24),

                        // Summary Section
                        SummaryCard(
                          totalSales: _totalSales,
                          totalReceived: _totalReceived,
                          totalBalance: _totalBalance,
                        ),
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
        'productMovement': _productMovement,
      },
    );

    if (result == true) {
      setState(() {
        _salesEntries.clear();
        _salesEntries.add(SalesEntry());
        _productMovement = ProductMovement();
      });
    }
  }
}
