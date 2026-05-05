import 'package:flutter/material.dart';
import 'package:alif_flow/services/report_service.dart';
import 'package:alif_flow/screens/pricing_screen.dart';
import 'package:alif_flow/utils/ui_helpers.dart';
import 'package:alif_flow/widgets/responsive_layout.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final ReportService _reportService = ReportService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      _reports = await _reportService.fetchAllReports();
    } catch (e) {
      if (mounted) {
        UiHelpers.showCustomToast(context, 'Error loading reports: $e', isError: true);
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadReports,
            tooltip: 'Refresh',
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
                  icon: Icon(Icons.assessment_outlined),
                  selectedIcon: Icon(Icons.assessment),
                  label: Text('Reports'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.attach_money_rounded),
                  selectedIcon: Icon(Icons.attach_money_rounded),
                  label: Text('Pricing'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
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
                  icon: Icon(Icons.assessment_outlined),
                  selectedIcon: Icon(Icons.assessment),
                  label: 'Reports',
                ),
                NavigationDestination(
                  icon: Icon(Icons.attach_money_rounded),
                  selectedIcon: Icon(Icons.attach_money_rounded),
                  label: 'Pricing',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildReportsTab();
      case 1:
        return const PricingScreen();
      default:
        return Center(
          child: Text('Content for tab $_selectedIndex'),
        );
    }
  }

  Widget _buildReportsTab() {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('No reports submitted yet',
                style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant)),
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

    // Separate submitted (pending) from rest
    final pending = _reports.where((r) => r['status'] == 'submitted').toList();
    final processed = _reports.where((r) => r['status'] != 'submitted').toList();

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pending.isNotEmpty) ...[
                _buildSectionTitle('Pending Review', Icons.hourglass_top, Colors.orange, colorScheme),
                const SizedBox(height: 8),
                for (final report in pending) _buildReportCard(report, colorScheme),
                const SizedBox(height: 24),
              ],
              if (processed.isNotEmpty) ...[
                _buildSectionTitle('Processed', Icons.done_all_rounded, colorScheme.primary, colorScheme),
                const SizedBox(height: 8),
                for (final report in processed) _buildReportCard(report, colorScheme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
      ],
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, ColorScheme colorScheme) {
    final status = report['status'] as String? ?? 'submitted';
    final totalSales = (report['total_sales'] as num?)?.toDouble() ?? 0.0;
    final balance = (report['balance_due'] as num?)?.toDouble() ?? 0.0;
    final createdAt = (report['created_at'] as String?)?.split('T')[0] ?? '';
    final sellerId = report['seller_id'] as String? ?? '';

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
          color: status == 'submitted'
              ? Colors.orange.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final result = await Navigator.pushNamed(
            context,
            '/admin-report-detail',
            arguments: {'reportId': report['id']},
          );
          if (result == true) {
            _loadReports(); // Refresh after action
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seller: ${sellerId.substring(0, 8)}...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(createdAt, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(
                      'Sales: \$${totalSales.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colorScheme.primary),
                    ),
                    if (balance > 0)
                      Text(
                        'Balance: \$${balance.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                  ],
                ),
              ),

              // Status badge + arrow
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
