import 'package:flutter/material.dart';
import 'package:alif_flow/models/sales_entry.dart';
import 'package:alif_flow/services/report_service.dart';
import 'package:alif_flow/services/pdf_report_service.dart';
import 'package:alif_flow/utils/ui_helpers.dart';

class MyReportsScreen extends StatefulWidget {
  /// Callback to switch the seller dashboard to the Sales Entry tab
  /// and populate it with regenerated draft data.
  final void Function(Map<String, dynamic> regeneratedData)? onRegenerate;

  const MyReportsScreen({super.key, this.onRegenerate});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final ReportService _reportService = ReportService();
  final PdfReportService _pdfService = PdfReportService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _reports = [];

  // Date filter
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  List<Map<String, dynamic>> get _filteredReports {
    if (_filterStartDate == null && _filterEndDate == null) return _reports;

    return _reports.where((report) {
      final createdAtStr = report['created_at'] as String?;
      if (createdAtStr == null) return false;
      final createdAt = DateTime.tryParse(createdAtStr);
      if (createdAt == null) return false;

      final dateOnly = DateTime(createdAt.year, createdAt.month, createdAt.day);
      if (_filterStartDate != null && dateOnly.isBefore(_filterStartDate!)) return false;
      if (_filterEndDate != null && dateOnly.isAfter(_filterEndDate!)) return false;
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      _reports = await _reportService.getMyReports();
    } catch (e) {
      if (mounted) {
        UiHelpers.showCustomToast(context, 'Failed to load reports: $e', isError: true);
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now,
      initialDateRange: _filterStartDate != null && _filterEndDate != null
          ? DateTimeRange(start: _filterStartDate!, end: _filterEndDate!)
          : DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _filterStartDate = picked.start;
        _filterEndDate = picked.end;
      });
    }
  }

  void _clearFilter() {
    setState(() {
      _filterStartDate = null;
      _filterEndDate = null;
    });
  }

  Future<void> _regenerateReport(Map<String, dynamic> report) async {
    final reportId = report['id'] as String;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Regenerate Report'),
        content: const Text(
          'This will create a new draft with the same products but zeroed quantities. '
          'You can then adjust quantities and amounts before resubmitting.\n\n'
          'The rejected report will be removed.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Fetch the rejected report detail to get the product list
      final detail = await _reportService.fetchReportDetail(reportId);
      final salesRaw = detail['salesEntries'] as List;
      final movementRaw = detail['movementEntries'] as List;

      // Build regenerated data: same products, zeroed quantities
      final regeneratedSales = salesRaw.map((e) {
        final map = e as Map<String, dynamic>;
        return SalesEntry(
          productName: map['product_name'] ?? '',
          category: map['category'] ?? '',
          quantitySold: 0,
          unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
          amountReceived: 0.0,
        );
      }).toList();

      final regeneratedMovement = movementRaw.map((e) {
        final map = e as Map<String, dynamic>;
        return ProductMovementEntry(
          productName: map['product_name'] ?? '',
          previousStock: 0,
          productsMoved: 0,
          newStockAdded: 0,
        );
      }).toList();

      // Delete the rejected report from DB
      await _reportService.deleteReport(reportId);

      // Group by category for the dashboard
      final Map<String, List<SalesEntry>> salesByCategory = {};
      final Map<String, List<ProductMovementEntry>> movementByCategory = {};

      for (int i = 0; i < regeneratedSales.length; i++) {
        final cat = regeneratedSales[i].category.isNotEmpty
            ? regeneratedSales[i].category
            : 'other';
        salesByCategory.putIfAbsent(cat, () => []).add(regeneratedSales[i]);
        if (i < regeneratedMovement.length) {
          movementByCategory.putIfAbsent(cat, () => []).add(regeneratedMovement[i]);
        }
      }

      if (mounted) {
        UiHelpers.showCustomToast(context, 'Draft regenerated. Fill in the corrected data.');

        // Notify parent to switch to Sales Entry tab with regenerated data
        if (widget.onRegenerate != null) {
          widget.onRegenerate!({
            'salesByCategory': salesByCategory,
            'movementByCategory': movementByCategory,
          });
        }
      }
    } catch (e) {
      if (mounted) {
        UiHelpers.showCustomToast(context, 'Error regenerating: $e', isError: true);
      }
    }
  }

  Future<void> _exportPdf(Map<String, dynamic> report) async {
    try {
      final reportId = report['id'] as String;
      final detail = await _reportService.fetchReportDetail(reportId);
      final salesRaw = detail['salesEntries'] as List;
      final movementRaw = detail['movementEntries'] as List;

      final salesEntries = salesRaw.map((e) {
        final map = e as Map<String, dynamic>;
        return SalesEntry(
          productName: map['product_name'] ?? '',
          category: map['category'] ?? '',
          quantitySold: (map['quantity_sold'] as num?)?.toInt() ?? 0,
          unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
          amountReceived: (map['amount_received'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      final movementEntries = movementRaw.map((e) {
        final map = e as Map<String, dynamic>;
        return ProductMovementEntry(
          productName: map['product_name'] ?? '',
          previousStock: (map['previous_stock'] as num?)?.toInt() ?? 0,
          productsMoved: (map['products_moved'] as num?)?.toInt() ?? 0,
          newStockAdded: (map['new_stock_added'] as num?)?.toInt() ?? 0,
        );
      }).toList();

      await _pdfService.generateAndPrintReport(
        salesEntries: salesEntries,
        movementEntries: movementEntries,
        totalSales: (report['total_sales'] as num?)?.toDouble() ?? 0.0,
        totalReceived: (report['total_received'] as num?)?.toDouble() ?? 0.0,
        totalBalance: (report['balance_due'] as num?)?.toDouble() ?? 0.0,
        reportDate: (report['created_at'] as String?)?.split('T')[0],
      );
    } catch (e) {
      if (mounted) {
        UiHelpers.showCustomToast(context, 'Error exporting PDF: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('No reports yet',
                style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('Submitted reports will appear here.',
                style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6))),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadReports,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredReports.length + 2, // header + filter + reports
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, size: 20, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('My Reports',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                ],
              ),
            );
          }

          if (index == 1) {
            // Date filter bar
            final hasFilter = _filterStartDate != null || _filterEndDate != null;
            final filterLabel = hasFilter
                ? '${_filterStartDate!.year}-${_filterStartDate!.month.toString().padLeft(2, '0')}-${_filterStartDate!.day.toString().padLeft(2, '0')}  →  ${_filterEndDate!.year}-${_filterEndDate!.month.toString().padLeft(2, '0')}-${_filterEndDate!.day.toString().padLeft(2, '0')}'
                : 'All dates';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDateRange,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.date_range_rounded, size: 18, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                filterLabel,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: hasFilter ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                                  fontWeight: hasFilter ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, color: colorScheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (hasFilter) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _clearFilter,
                      icon: Icon(Icons.clear_rounded, size: 20, color: colorScheme.error),
                      tooltip: 'Clear filter',
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          final report = _filteredReports[index - 2];
          return _buildReportCard(report, colorScheme);
        },
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, ColorScheme colorScheme) {
    final status = report['status'] as String? ?? 'submitted';
    final totalSales = (report['total_sales'] as num?)?.toDouble() ?? 0.0;
    final balance = (report['balance_due'] as num?)?.toDouble() ?? 0.0;
    final createdAt = (report['created_at'] as String?)?.split('T')[0] ?? '';
    final rejectionReason = report['rejection_reason'] as String?;

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
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: status == 'rejected'
              ? Colors.red.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Icon(statusIcon, size: 20, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Weekly Report',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Info
            Row(
              children: [
                _buildInfoChip(Icons.calendar_today, createdAt, colorScheme),
                const SizedBox(width: 12),
                _buildInfoChip(Icons.attach_money, '\$${UiHelpers.formatNumber(totalSales)}', colorScheme),
                if (balance > 0) ...[
                  const SizedBox(width: 12),
                  _buildInfoChip(Icons.warning_amber_rounded,
                      '\$${UiHelpers.formatNumber(balance)} due', colorScheme,
                      color: Colors.red),
                ],
              ],
            ),

            // Rejection reason
            if (status == 'rejected' && rejectionReason != null && rejectionReason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rejection Reason:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(rejectionReason, style: TextStyle(color: colorScheme.onSurface, fontSize: 12)),
                  ],
                ),
              ),
            ],

            // Action buttons
            const SizedBox(height: 12),
            Row(
              children: [
                if (status == 'rejected')
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _regenerateReport(report),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Regenerate', style: TextStyle(fontSize: 13)),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                if (status == 'rejected') const SizedBox(width: 8),
                if (status == 'approved')
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _exportPdf(report),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                      label: const Text('Download PDF', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                if (status == 'submitted')
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.hourglass_top, size: 16, color: colorScheme.onSurfaceVariant),
                      label: Text('Awaiting Review',
                          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, ColorScheme colorScheme, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(fontSize: 12, color: color ?? colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
