import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:alif_flow/models/sales_entry.dart';

class ReportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> submitWeeklyReport({
    required List<SalesEntry> salesEntries,
    required List<ProductMovementEntry> movementEntries,
    required double totalSales,
    required double totalReceived,
    required double totalBalance,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Calculate aggregate movement totals for backward compatibility
    final totalMoved = movementEntries.fold(0, (sum, e) => sum + e.productsMoved);
    final totalArrivals = movementEntries.fold(0, (sum, e) => sum + e.newStockAdded);
    final totalAvailable = movementEntries.fold(0, (sum, e) => sum + e.currentStock);

    // 1. Create the Weekly Report header
    final reportResponse = await _supabase.from('weekly_reports').insert({
      'seller_id': user.id,
      'total_sales': totalSales,
      'total_received': totalReceived,
      'balance_due': totalBalance,
      'last_week_moved': totalMoved,
      'new_arrivals': totalArrivals,
      'currently_available': totalAvailable,
      'status': 'submitted',
    }).select().single();

    final reportId = reportResponse['id'];

    // 2. Insert all sales entries
    final entriesToInsert = salesEntries.map((e) => {
      'report_id': reportId,
      'product_name': e.productName,
      'category': e.category,
      'quantity_sold': e.quantitySold,
      'unit_price': e.unitPrice,
      'total_price': e.totalPrice,
      'amount_received': e.amountReceived,
      'balance_due': e.balanceDue,
    }).toList();

    await _supabase.from('sales_entries').insert(entriesToInsert);

    // 3. Insert all movement entries
    if (movementEntries.isNotEmpty) {
      final movementsToInsert = movementEntries.map((e) => {
        'report_id': reportId,
        'product_name': e.productName,
        'previous_stock': e.previousStock,
        'products_moved': e.productsMoved,
        'new_stock_added': e.newStockAdded,
        'current_stock': e.currentStock,
      }).toList();

      try {
        await _supabase.from('product_movements').insert(movementsToInsert);
      } catch (e) {
        // Log or handle gracefully if the table doesn't exist yet
        debugPrint('Warning: product_movements insert failed, table may not exist: $e');
      }
    }
  }

  // Fetch recent reports for this seller
  Future<List<Map<String, dynamic>>> getMyRecentReports() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    return await _supabase
        .from('weekly_reports')
        .select()
        .eq('seller_id', user.id)
        .order('created_at', ascending: false)
        .limit(10);
  }
}
