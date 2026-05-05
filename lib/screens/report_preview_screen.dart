import 'package:flutter/material.dart';
import 'package:alif_flow/models/sales_entry.dart';
import 'package:alif_flow/utils/ui_helpers.dart';

import 'package:alif_flow/services/report_service.dart';

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
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final List<SalesEntry> salesEntries = arguments?['salesEntries'] ?? [];
    final List<ProductMovementEntry> movementEntries = arguments?['movementEntries'] ?? [];

    final colorScheme = Theme.of(context).colorScheme;

    // Calculate totals
    double totalSales = 0;
    double totalReceived = 0;
    for (var entry in salesEntries) {
      totalSales += entry.totalPrice;
      totalReceived += entry.amountReceived;
    }
    double totalBalance = totalSales - totalReceived;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                Card(
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
                        _buildInfoRow('Date Generated', DateTime.now().toString().split(' ')[0]),
                        _buildInfoRow('Items Count', salesEntries.length.toString()),
                        _buildInfoRow('Status', totalBalance > 0 ? 'Balance Pending' : 'Paid in Full', 
                          valueColor: totalBalance > 0 ? colorScheme.error : Colors.green),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sales Table Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 20, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Sales Summary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSalesTable(context, salesEntries),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Inventory Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 20, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Inventory Movement',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildMovementTable(context, movementEntries),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

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
                        _buildTotalRow('Gross Sales', totalSales, colorScheme),
                        const SizedBox(height: 8),
                        _buildTotalRow('Amount Received', totalReceived, colorScheme),
                        const Divider(height: 24),
                        _buildTotalRow('Net Balance Due', totalBalance, colorScheme, isGrandTotal: true),
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
                      : () => _showConfirmDialog(context, salesEntries, movementEntries, totalSales, totalReceived, totalBalance),
                    icon: _isSubmitting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _isSubmitting ? 'Submitting...' : 'Confirm and Submit Report',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildSalesTable(BuildContext context, List<SalesEntry> entries) {
    if (entries.isEmpty) {
      return const Center(child: Text('No sales entries found.'));
    }

    return Column(
      children: [
        Row(
          children: const [
            Expanded(flex: 3, child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Expanded(flex: 1, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Expanded(flex: 2, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
        ),
        const Divider(),
        ...entries.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                flex: 3, 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.productName, style: const TextStyle(fontWeight: FontWeight.w500)),
                    if (e.category.isNotEmpty)
                      Text(e.category, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  ],
                ),
              ),
              Expanded(flex: 1, child: Text(e.quantitySold.toString(), textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text('\$${e.totalPrice.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildMovementTable(BuildContext context, List<ProductMovementEntry> entries) {
    if (entries.isEmpty) {
      return const Center(child: Text('No inventory movement found.'));
    }

    return Column(
      children: [
        Row(
          children: const [
            Expanded(flex: 3, child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Expanded(flex: 1, child: Text('Moved', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Expanded(flex: 1, child: Text('Added', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Expanded(flex: 1, child: Text('Stock', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
        ),
        const Divider(),
        ...entries.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                flex: 3, 
                child: Text(e.productName, style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
              Expanded(flex: 1, child: Text(e.productsMoved.toString(), textAlign: TextAlign.center)),
              Expanded(flex: 1, child: Text(e.newStockAdded.toString(), textAlign: TextAlign.center)),
              Expanded(flex: 1, child: Text(e.currentStock.toString(), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildTotalRow(String label, double value, ColorScheme colorScheme, {bool isGrandTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isGrandTotal ? 18 : 14,
            fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.normal,
            color: isGrandTotal ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
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
        content: const Text('Are you sure you want to submit this weekly report? Once submitted, it cannot be edited.'),
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
                
                UiHelpers.showCustomToast(context, 'Report submitted successfully!');
                Navigator.of(context).pop(true); // Return true to indicate success
              } catch (e) {
                if (!context.mounted) return;
                UiHelpers.showCustomToast(context, 'Error submitting report: $e', isError: true);
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
