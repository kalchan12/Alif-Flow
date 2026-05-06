import 'package:flutter/material.dart';
import 'package:alif_flow/models/sales_entry.dart';
import 'package:alif_flow/utils/ui_helpers.dart';
import 'package:alif_flow/services/report_service.dart';
import 'package:alif_flow/widgets/spreadsheet_table.dart';

class ReportPreviewScreen extends StatefulWidget {
  const ReportPreviewScreen({super.key});

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  final ReportService _reportService = ReportService();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final List<SalesEntry> salesEntries = arguments?['salesEntries'] ?? [];
    final List<ProductMovementEntry> movementEntries =
        arguments?['movementEntries'] ?? [];

    final colorScheme = Theme.of(context).colorScheme;

    // Calculate totals
    double totalSales = 0;
    double totalReceived = 0;
    for (var entry in salesEntries) {
      totalSales += entry.totalPrice;
      totalReceived += entry.amountReceived;
    }
    double totalBalance = totalSales - totalReceived;

    // Group entries by category for display
    final Map<String, List<int>> categoryIndices = {};
    for (int i = 0; i < salesEntries.length; i++) {
      final cat = salesEntries[i].category.isNotEmpty
          ? salesEntries[i].category
          : 'other';
      categoryIndices.putIfAbsent(cat, () => []).add(i);
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

    return Scaffold(
      backgroundColor:
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      appBar: AppBar(
        title: const Text('Report Preview'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                // Report Header Card
                _buildHeaderCard(colorScheme, salesEntries, totalBalance),
                const SizedBox(height: 16),

                // Merged spreadsheet per category
                for (final category in categoryIndices.keys) ...[
                  _buildCategoryPreview(
                    category: category,
                    displayName:
                        categoryDisplayNames[category] ?? category,
                    icon: categoryIcons[category] ?? Icons.category,
                    indices: categoryIndices[category]!,
                    salesEntries: salesEntries,
                    movementEntries: movementEntries,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 16),
                ],

                // Final Totals Card
                Card(
                  elevation: 0,
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        _buildTotalRow(
                            'Gross Sales', totalSales, colorScheme),
                        const SizedBox(height: 8),
                        _buildTotalRow(
                            'Amount Received', totalReceived, colorScheme),
                        const Divider(height: 24),
                        _buildTotalRow(
                            'Net Balance Due', totalBalance, colorScheme,
                            isGrandTotal: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _showConfirmDialog(
                              context,
                              salesEntries,
                              movementEntries,
                              totalSales,
                              totalReceived,
                              totalBalance,
                            ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _isSubmitting
                          ? 'Submitting...'
                          : 'Confirm and Submit Report',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
      ColorScheme colorScheme, List<SalesEntry> salesEntries, double totalBalance) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WEEKLY SALES REPORT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Alif-Flow Business',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow('Date Generated',
                DateTime.now().toString().split(' ')[0]),
            _buildInfoRow(
                'Items Count', salesEntries.length.toString()),
            _buildInfoRow(
              'Status',
              totalBalance > 0 ? 'Balance Pending' : 'Paid in Full',
              valueColor:
                  totalBalance > 0 ? colorScheme.error : Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  /// Build a merged spreadsheet preview for one category.
  Widget _buildCategoryPreview({
    required String category,
    required String displayName,
    required IconData icon,
    required List<int> indices,
    required List<SalesEntry> salesEntries,
    required List<ProductMovementEntry> movementEntries,
    required ColorScheme colorScheme,
  }) {
    // Extract the subset of entries for this category
    final catSales = indices.map((i) => salesEntries[i]).toList();
    final catMovement = indices
        .map((i) => i < movementEntries.length ? movementEntries[i] : null)
        .toList();

    final double catTotalSales =
        catSales.fold(0.0, (s, e) => s + e.totalPrice);
    final double catTotalReceived =
        catSales.fold(0.0, (s, e) => s + e.amountReceived);
    final double catTotalBalance = catTotalSales - catTotalReceived;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Merged spreadsheet — all read-only for preview
            SpreadsheetTable(
              columns: const [
                SpreadsheetColumn(
                    header: 'Product Name',
                    width: 140,
                    isProductName: true,
                    isReadOnly: true),
                SpreadsheetColumn(
                    header: 'Qty',
                    width: 70,
                    isNumeric: true,
                    isReadOnly: true),
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
                SpreadsheetColumn(
                    header: 'Received',
                    width: 90,
                    isNumeric: true,
                    isReadOnly: true),
                SpreadsheetColumn(
                    header: 'Balance',
                    width: 90,
                    isCalculated: true,
                    isNumeric: true,
                    isReadOnly: true),
                SpreadsheetColumn(
                    header: 'Prev Stock',
                    width: 90,
                    isNumeric: true,
                    isReadOnly: true),
                SpreadsheetColumn(
                    header: 'Moved',
                    width: 80,
                    isNumeric: true,
                    isReadOnly: true),
                SpreadsheetColumn(
                    header: 'Added',
                    width: 80,
                    isNumeric: true,
                    isReadOnly: true),
                SpreadsheetColumn(
                    header: 'Current Stock',
                    width: 90,
                    isCalculated: true,
                    isNumeric: true,
                    isReadOnly: true),
              ],
              rowCount: catSales.length,
              footerBuilder: (col) {
                switch (col) {
                  case 0:
                    return const CellData(
                        value: 'TOTAL', hint: '', textColor: null);
                  case 1:
                    final sum = catSales.fold<int>(
                        0, (s, e) => s + e.quantitySold);
                    return CellData(
                        value: sum > 0 ? sum.toString() : '');
                  case 2:
                    return const CellData(value: '---');
                  case 3:
                    return CellData(
                        value: catTotalSales > 0
                            ? catTotalSales.toStringAsFixed(2)
                            : '');
                  case 4:
                    return CellData(
                        value: catTotalReceived > 0
                            ? catTotalReceived.toStringAsFixed(2)
                            : '');
                  case 5:
                    return CellData(
                      value: catTotalBalance != 0
                          ? catTotalBalance.toStringAsFixed(2)
                          : '',
                      textColor: catTotalBalance > 0
                          ? colorScheme.error
                          : (catTotalBalance < 0
                              ? colorScheme.primary
                              : null),
                    );
                  case 6:
                    final sum = catMovement.fold<int>(
                        0, (s, e) => s + (e?.previousStock ?? 0));
                    return CellData(
                        value: sum > 0 ? sum.toString() : '');
                  case 7:
                    final sum = catMovement.fold<int>(
                        0, (s, e) => s + (e?.productsMoved ?? 0));
                    return CellData(
                        value: sum > 0 ? sum.toString() : '');
                  case 8:
                    final sum = catMovement.fold<int>(
                        0, (s, e) => s + (e?.newStockAdded ?? 0));
                    return CellData(
                        value: sum > 0 ? sum.toString() : '');
                  case 9:
                    final sum = catMovement.fold<int>(
                        0, (s, e) => s + (e?.currentStock ?? 0));
                    return CellData(
                        value: sum > 0 ? sum.toString() : '');
                  default:
                    return const CellData();
                }
              },
              cellBuilder: (row, col) {
                final sales = catSales[row];
                final movement = catMovement[row];
                switch (col) {
                  case 0:
                    return CellData(value: sales.productName);
                  case 1:
                    return CellData(
                        value: sales.quantitySold > 0
                            ? sales.quantitySold.toString()
                            : '');
                  case 2:
                    return CellData(
                        value: sales.unitPrice > 0
                            ? sales.unitPrice.toStringAsFixed(2)
                            : '');
                  case 3:
                    return CellData(
                        value: sales.totalPrice > 0
                            ? sales.totalPrice.toStringAsFixed(2)
                            : '');
                  case 4:
                    return CellData(
                        value: sales.amountReceived > 0
                            ? sales.amountReceived.toStringAsFixed(2)
                            : '');
                  case 5:
                    final bal = sales.balanceDue;
                    return CellData(
                      value: bal != 0 ? bal.toStringAsFixed(2) : '',
                      textColor: bal > 0
                          ? colorScheme.error
                          : (bal < 0 ? colorScheme.primary : null),
                    );
                  case 6:
                    return CellData(
                        value: (movement?.previousStock ?? 0) > 0
                            ? movement!.previousStock.toString()
                            : '');
                  case 7:
                    return CellData(
                        value: (movement?.productsMoved ?? 0) > 0
                            ? movement!.productsMoved.toString()
                            : '');
                  case 8:
                    return CellData(
                        value: (movement?.newStockAdded ?? 0) > 0
                            ? movement!.newStockAdded.toString()
                            : '');
                  case 9:
                    return CellData(
                        value: (movement?.currentStock ?? 0) > 0
                            ? movement!.currentStock.toString()
                            : '');
                  default:
                    return const CellData();
                }
              },
              onCellChanged: (row, col, value) {
                // All read-only in preview
              },
              onAddRow: () {},
              canDeleteRows: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, ColorScheme colorScheme,
      {bool isGrandTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isGrandTotal ? 18 : 14,
            fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.normal,
            color: isGrandTotal
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isGrandTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: isGrandTotal
                ? (value > 0 ? colorScheme.error : colorScheme.primary)
                : colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    List<SalesEntry> salesEntries,
    List<ProductMovementEntry> movementEntries,
    double totalSales,
    double totalReceived,
    double totalBalance,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Submission'),
        content: const Text(
            'Are you sure you want to submit this weekly report? Once submitted, it cannot be edited.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog

              setState(() => _isSubmitting = true);

              try {
                await _reportService.submitWeeklyReport(
                  salesEntries: salesEntries,
                  movementEntries: movementEntries,
                  totalSales: totalSales,
                  totalReceived: totalReceived,
                  totalBalance: totalBalance,
                );

                if (!context.mounted) return;

                UiHelpers.showCustomToast(
                    context, 'Report submitted successfully!');
                Navigator.of(context)
                    .pop(true); // Return true to indicate success
              } catch (e) {
                if (!context.mounted) return;
                String errorMessage = 'Error submitting report';
                final errorStr = e.toString().toLowerCase();

                if (errorStr.contains('socketexception') || 
                    errorStr.contains('network_error') || 
                    errorStr.contains('failed host lookup') ||
                    errorStr.contains('connection timed out')) {
                  errorMessage = 'No internet connection. Please check your network and try again.';
                } else {
                  errorMessage = 'Error: ${e.toString()}';
                }

                UiHelpers.showCustomToast(
                  context, 
                  errorMessage, 
                  isError: true,
                );
              } finally {
                if (mounted) {
                  setState(() => _isSubmitting = false);
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
