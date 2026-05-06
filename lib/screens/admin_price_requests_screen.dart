import 'package:flutter/material.dart';
import 'package:alif_flow/models/product_price.dart';
import 'package:alif_flow/services/pricing_service.dart';
import 'package:alif_flow/utils/ui_helpers.dart';
import 'package:alif_flow/widgets/responsive_layout.dart';

class AdminPriceRequestsScreen extends StatefulWidget {
  const AdminPriceRequestsScreen({super.key});

  @override
  State<AdminPriceRequestsScreen> createState() => _AdminPriceRequestsScreenState();
}

class _AdminPriceRequestsScreenState extends State<AdminPriceRequestsScreen> {
  final PricingService _pricingService = PricingService();
  bool _isLoading = true;
  List<PriceChangeRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      _requests = await _pricingService.fetchPendingRequests();
    } catch (e) {
      if (mounted) {
        UiHelpers.showCustomToast(context, 'Failed to load requests: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleApprove(PriceChangeRequest request) async {
    try {
      await _pricingService.approvePriceChange(request.id, request.productId, request.newPrice);
      if (!mounted) return;
      UiHelpers.showCustomToast(context, 'Price change approved for ${request.productName}');
      _loadRequests(); // Refresh list
    } catch (e) {
      if (!mounted) return;
      UiHelpers.showCustomToast(context, 'Failed to approve: $e', isError: true);
    }
  }

  Future<void> _handleReject(PriceChangeRequest request) async {
    try {
      await _pricingService.rejectPriceChange(request.id);
      if (!mounted) return;
      UiHelpers.showCustomToast(context, 'Price change rejected for ${request.productName}');
      _loadRequests(); // Refresh list
    } catch (e) {
      if (!mounted) return;
      UiHelpers.showCustomToast(context, 'Failed to reject: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Price Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: ResponsiveLayout(
        mobileBody: _buildBody(colorScheme),
        tabletBody: _buildBody(colorScheme),
      ),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'No pending requests',
              style: TextStyle(fontSize: 18, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _requests.length,
            itemBuilder: (context, index) {
              final req = _requests[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.price_change, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              req.productName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            _formatDate(req.createdAt),
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildPriceBox('Old Price', req.oldPrice, Colors.grey),
                          const Icon(Icons.arrow_forward, color: Colors.grey),
                          _buildPriceBox('New Price', req.newPrice, colorScheme.primary),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _handleReject(req),
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text('Reject', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: () => _handleApprove(req),
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPriceBox(String label, double price, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          '\$${UiHelpers.formatNumber(price)}',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
