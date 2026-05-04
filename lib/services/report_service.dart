import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:alif_flow/models/sales_entry.dart';

class ReportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> submitWeeklyReport({
    required List<SalesEntry> salesEntries,
    required ProductMovement productMovement,
    required double totalSales,
    required double totalReceived,
    required double totalBalance,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // 1. Create the Weekly Report header
    final reportResponse = await _supabase.from('weekly_reports').insert({
      'seller_id': user.id,
      'total_sales': totalSales,
      'total_received': totalReceived,
      'balance_due': totalBalance,
      'last_week_moved': productMovement.lastWeekMoved,
      'new_arrivals': productMovement.newArrivals,
      'currently_available': productMovement.currentlyAvailable,
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
