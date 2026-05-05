import 'package:flutter/material.dart';
import 'package:alif_flow/models/sales_entry.dart';
import 'package:alif_flow/services/report_service.dart';
import 'package:alif_flow/services/pdf_report_service.dart';
import 'package:alif_flow/utils/ui_helpers.dart';
import 'package:alif_flow/widgets/spreadsheet_table.dart';

class AdminReportDetailScreen extends StatefulWidget {
  const AdminReportDetailScreen({super.key});

  @override
  State<AdminReportDetailScreen> createState() => _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState extends State<AdminReportDetailScreen> {
  final ReportService _reportService = ReportService();
  final PdfReportService _pdfService = PdfReportService();

  bool _isLoading = true;
  bool _isActioning = false;
  Map<String, dynamic>? _reportData;
  List<SalesEntry> _salesEntries = [];
  List<ProductMovementEntry> _movementEntries = [];

  String? _reportId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reportId == null) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _reportId = args?['reportId'] as String?;
      if (_reportId != null) {
        _loadReportDetail();
      }
    }
  }

  Future<void> _loadReportDetail() async {
    if (_reportId == null) return;
    setState(() => _isLoading = true);

    try {
      final detail = await _reportService.fetchReportDetail(_reportId!);
      final report = detail['report'] as Map<String, dynamic>;
      final salesRaw = detail['salesEntries'] as List;
      final movementRaw = detail['movementEntries'] as List;

      _salesEntries = salesRaw.map((e) {
        final map = e as Map<String, dynamic>;
        return SalesEntry(
          productName: map['product_name'] ?? '',
          category: map['category'] ?? '',
          quantitySold: (map['quantity_sold'] as num?)?.toInt() ?? 0,
          unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
          amountReceived: (map['amount_received'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      _movementEntries = movementRaw.map((e) {
        final map = e as Map<String, dynamic>;
        return ProductMovementEntry(
          productName: map['product_name'] ?? '',
          previousStock: (map['previous_stock'] as num?)?.toInt() ?? 0,
          productsMoved: (map['products_moved'] as num?)?.toInt() ?? 0,
          newStockAdded: (map['new_stock_added'] as num?)?.toInt() ?? 0,
        );
      }).toList();

      setState(() {
        _reportData = report;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        UiHelpers.showCustomToast(context, 'Error loading report: $e', isError: true);
      }
    }
  }

  Future<void> _approveReport() async {
    setState(() => _isActioning = true);
    try {
      await _reportService.approveReport(_reportId!);
      if (mounted) {
        UiHelpers.showCustomToast(context, 'Report approved successfully!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        UiHelpers.showCustomToast(context, 'Error approving report: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isActioning = false);
    }
  }

  Future<void> _rejectReport() async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejecting this report:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                UiHelpers.showCustomToast(ctx, 'Please enter a reason', isError: true);
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActioning = true);
    try {
      await _reportService.rejectReport(_reportId!, reasonController.text.trim());
      if (mounted) {
        UiHelpers.showCustomToast(context, 'Report rejected.');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        UiHelpers.showCustomToast(context, 'Error rejecting report: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isActioning = false);
      reasonController.dispose();
    }
  }

  Future<void> _exportPdf() async {
    final report = _reportData!;
    final totalSales = (report['total_sales'] as num?)?.toDouble() ?? 0.0;
    final totalReceived = (report['total_received'] as num?)?.toDouble() ?? 0.0;
    final totalBalance = (report['balance_due'] as num?)?.toDouble() ?? 0.0;
    final date = (report['created_at'] as String?)?.split('T')[0] ?? '';

    await _pdfService.generateAndPrintReport(
      salesEntries: _salesEntries,
      movementEntries: _movementEntries,
      totalSales: totalSales,
      totalReceived: totalReceived,
      totalBalance: totalBalance,
      reportDate: date,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Detail'),
        actions: [
          if (_reportData != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              tooltip: 'Export PDF',
              onPressed: _exportPdf,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reportData == null
              ? const Center(child: Text('Report not found'))
              : _buildContent(colorScheme),
    );
  }

  Widget _buildContent(ColorScheme colorScheme) {
    final report = _reportData!;
    final status = report['status'] as String? ?? 'submitted';
    final totalSales = (report['total_sales'] as num?)?.toDouble() ?? 0.0;
    final totalReceived = (report['total_received'] as num?)?.toDouble() ?? 0.0;
    final totalBalance = (report['balance_due'] as num?)?.toDouble() ?? 0.0;
    final createdAt = (report['created_at'] as String?)?.split('T')[0] ?? 'Unknown';
    final rejectionReason = report['rejection_reason'] as String?;

    // Group by category
    final Map<String, List<int>> categoryIndices = {};
    for (int i = 0; i < _salesEntries.length; i++) {
      final cat = _salesEntries[i].category.isNotEmpty ? _salesEntries[i].category : 'other';
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

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    // Status & info card
                    _buildHeaderCard(colorScheme, status, createdAt, totalBalance, rejectionReason),
                    const SizedBox(height: 16),

                    // Spreadsheet tables per category
                    for (final category in categoryIndices.keys) ...[
                      _buildCategoryPreview(
                        category: category,
                        displayName: categoryDisplayNames[category] ?? category,
                        icon: categoryIcons[category] ?? Icons.category,
                        indices: categoryIndices[category]!,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Totals card
                    Card(
                      elevation: 0,
                      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
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
                  ],
                ),
              ),
            ),
          ),
        ),

        // Action buttons (only for submitted reports)
        if (status == 'submitted')
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
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
                          onPressed: _isActioning ? null : _rejectReport,
                          icon: const Icon(Icons.close_rounded, size: 18, color: Colors.red),
                          label: const Text('Reject', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isActioning ? null : _approveReport,
                          icon: _isActioning
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Approve'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: Colors.green,
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

  Widget _buildHeaderCard(ColorScheme colorScheme, String status, String date, double balance, String? rejectionReason) {
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_top;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Report',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Submitted', date),
            _buildInfoRow('Items', _salesEntries.length.toString()),
            _buildInfoRow('Balance', balance > 0 ? '\$${balance.toStringAsFixed(2)} pending' : 'Paid in full',
                valueColor: balance > 0 ? Colors.red : Colors.green),
            if (rejectionReason != null && rejectionReason.isNotEmpty) ...[
              const Divider(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rejection Reason:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(rejectionReason, style: TextStyle(color: colorScheme.onSurface, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPreview({
    required String category,
    required String displayName,
    required IconData icon,
    required List<int> indices,
    required ColorScheme colorScheme,
  }) {
    final catSales = indices.map((i) => _salesEntries[i]).toList();
    final catMovement = indices.map((i) => i < _movementEntries.length ? _movementEntries[i] : null).toList();

    final catTotalSales = catSales.fold(0.0, (s, e) => s + e.totalPrice);
    final catTotalReceived = catSales.fold(0.0, (s, e) => s + e.amountReceived);
    final catTotalBalance = catTotalSales - catTotalReceived;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(displayName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
              ],
            ),
            const SizedBox(height: 12),
            SpreadsheetTable(
              columns: const [
                SpreadsheetColumn(header: 'Product Name', width: 140, isProductName: true, isReadOnly: true),
                SpreadsheetColumn(header: 'Qty', width: 70, isNumeric: true, isReadOnly: true),
                SpreadsheetColumn(header: 'Price', width: 80, isNumeric: true, isReadOnly: true, isCalculated: true),
                SpreadsheetColumn(header: 'Total Sale', width: 90, isCalculated: true, isNumeric: true, isReadOnly: true),
                SpreadsheetColumn(header: 'Received', width: 90, isNumeric: true, isReadOnly: true),
                SpreadsheetColumn(header: 'Balance', width: 90, isCalculated: true, isNumeric: true, isReadOnly: true),
                SpreadsheetColumn(header: 'Prev Stock', width: 90, isNumeric: true, isReadOnly: true),
                SpreadsheetColumn(header: 'Moved', width: 80, isNumeric: true, isReadOnly: true),
                SpreadsheetColumn(header: 'Added', width: 80, isNumeric: true, isReadOnly: true),
                SpreadsheetColumn(header: 'Current Stock', width: 90, isCalculated: true, isNumeric: true, isReadOnly: true),
              ],
              rowCount: catSales.length,
              footerBuilder: (col) {
                switch (col) {
                  case 0: return const CellData(value: 'TOTAL');
                  case 1: return CellData(value: catSales.fold<int>(0, (s, e) => s + e.quantitySold).toString());
                  case 2: return const CellData(value: '---');
                  case 3: return CellData(value: catTotalSales > 0 ? catTotalSales.toStringAsFixed(2) : '');
                  case 4: return CellData(value: catTotalReceived > 0 ? catTotalReceived.toStringAsFixed(2) : '');
                  case 5: return CellData(
                      value: catTotalBalance != 0 ? catTotalBalance.toStringAsFixed(2) : '',
                      textColor: catTotalBalance > 0 ? colorScheme.error : (catTotalBalance < 0 ? colorScheme.primary : null));
                  case 6: return CellData(value: catMovement.fold<int>(0, (s, e) => s + (e?.previousStock ?? 0)).toString());
                  case 7: return CellData(value: catMovement.fold<int>(0, (s, e) => s + (e?.productsMoved ?? 0)).toString());
                  case 8: return CellData(value: catMovement.fold<int>(0, (s, e) => s + (e?.newStockAdded ?? 0)).toString());
                  case 9: return CellData(value: catMovement.fold<int>(0, (s, e) => s + (e?.currentStock ?? 0)).toString());
                  default: return const CellData();
                }
              },
              cellBuilder: (row, col) {
                final s = catSales[row];
                final m = catMovement[row];
                switch (col) {
                  case 0: return CellData(value: s.productName);
                  case 1: return CellData(value: s.quantitySold > 0 ? s.quantitySold.toString() : '');
                  case 2: return CellData(value: s.unitPrice > 0 ? s.unitPrice.toStringAsFixed(2) : '');
                  case 3: return CellData(value: s.totalPrice > 0 ? s.totalPrice.toStringAsFixed(2) : '');
                  case 4: return CellData(value: s.amountReceived > 0 ? s.amountReceived.toStringAsFixed(2) : '');
                  case 5:
                    final bal = s.balanceDue;
                    return CellData(value: bal != 0 ? bal.toStringAsFixed(2) : '', textColor: bal > 0 ? colorScheme.error : (bal < 0 ? colorScheme.primary : null));
                  case 6: return CellData(value: (m?.previousStock ?? 0) > 0 ? m!.previousStock.toString() : '');
                  case 7: return CellData(value: (m?.productsMoved ?? 0) > 0 ? m!.productsMoved.toString() : '');
                  case 8: return CellData(value: (m?.newStockAdded ?? 0) > 0 ? m!.newStockAdded.toString() : '');
                  case 9: return CellData(value: (m?.currentStock ?? 0) > 0 ? m!.currentStock.toString() : '');
                  default: return const CellData();
                }
              },
              onCellChanged: (row, col, value) {},
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, ColorScheme colorScheme, {bool isGrandTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isGrandTotal ? 18 : 14, fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.normal)),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isGrandTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: isGrandTotal ? (value > 0 ? colorScheme.error : colorScheme.primary) : colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
