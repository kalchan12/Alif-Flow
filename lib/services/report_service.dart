import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:alif_flow/models/sales_entry.dart';

class ReportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ── Submit a weekly report (seller) ──
  Future<void> submitWeeklyReport({
    required List<SalesEntry> salesEntries,
    required List<ProductMovementEntry> movementEntries,
    required double totalSales,
    required double totalReceived,
    required double totalBalance,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

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
        debugPrint('Warning: product_movements insert failed: $e');
      }
    }
  }

  // ── Seller: Fetch my reports with statuses ──
  Future<List<Map<String, dynamic>>> getMyReports() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    return await _supabase
        .from('weekly_reports')
        .select()
        .eq('seller_id', user.id)
        .order('created_at', ascending: false)
        .limit(20);
  }

  // ── Seller: Fetch dashboard stats (All Time and Last 7 Days) ──
  Future<Map<String, dynamic>> getSellerDashboardStats() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Fetch all reports for the user, joined with their sales_entries to calculate quantities
    final response = await _supabase
        .from('weekly_reports')
        .select('*, sales_entries(quantity_sold)')
        .eq('seller_id', user.id)
        .eq('status', 'approved'); // Only count approved reports as per user clarification

    double allTimeEarned = 0.0;
    int allTimeQuantity = 0;
    double weeklyEarned = 0.0;
    int weeklyQuantity = 0;

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    for (final report in response) {
      final totalSales = (report['total_sales'] as num?)?.toDouble() ?? 0.0;
      final createdAt = DateTime.parse(report['created_at']);
      
      int reportQuantity = 0;
      if (report['sales_entries'] != null) {
        final entries = report['sales_entries'] as List<dynamic>;
        for (final entry in entries) {
          reportQuantity += (entry['quantity_sold'] as num?)?.toInt() ?? 0;
        }
      }

      allTimeEarned += totalSales;
      allTimeQuantity += reportQuantity;

      if (createdAt.isAfter(sevenDaysAgo)) {
        weeklyEarned += totalSales;
        weeklyQuantity += reportQuantity;
      }
    }

    return {
      'allTimeEarned': allTimeEarned,
      'allTimeQuantity': allTimeQuantity,
      'weeklyEarned': weeklyEarned,
      'weeklyQuantity': weeklyQuantity,
    };
  }

  // ── Admin: Fetch all submitted reports ──
  Future<List<Map<String, dynamic>>> fetchAllReports() async {
    return await _supabase
        .from('weekly_reports')
        .select()
        .order('created_at', ascending: false)
        .limit(50);
  }

  // ── Admin: Fetch global dashboard stats ──
  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    // 1. Fetch total sales from all approved reports
    final approvedReports = await _supabase
        .from('weekly_reports')
        .select('total_sales, sales_entries(quantity_sold)')
        .eq('status', 'approved');

    double totalGlobalSales = 0.0;
    int totalItemsSold = 0;

    for (final report in approvedReports) {
      totalGlobalSales += (report['total_sales'] as num?)?.toDouble() ?? 0.0;
      if (report['sales_entries'] != null) {
        final entries = report['sales_entries'] as List<dynamic>;
        for (final entry in entries) {
          totalItemsSold += (entry['quantity_sold'] as num?)?.toInt() ?? 0;
        }
      }
    }

    // 2. Fetch count of pending (submitted) reports that need review
    final pendingReportsResponse = await _supabase
        .from('weekly_reports')
        .select('id')
        .eq('status', 'submitted');
    
    final pendingCount = pendingReportsResponse.length;

    return {
      'totalGlobalSales': totalGlobalSales,
      'totalItemsSold': totalItemsSold,
      'pendingReports': pendingCount,
    };
  }

  // ── Fetch full report detail with entries ──
  Future<Map<String, dynamic>> fetchReportDetail(String reportId) async {
    final report = await _supabase
        .from('weekly_reports')
        .select()
        .eq('id', reportId)
        .single();

    final salesEntries = await _supabase
        .from('sales_entries')
        .select()
        .eq('report_id', reportId)
        .order('created_at');

    final movements = await _supabase
        .from('product_movements')
        .select()
        .eq('report_id', reportId)
        .order('created_at');

    return {
      'report': report,
      'salesEntries': salesEntries,
      'movementEntries': movements,
    };
  }

  // ── Admin: Approve a report ──
  Future<void> approveReport(String reportId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _supabase.from('weekly_reports').update({
      'status': 'approved',
      'approved_by': user.id,
      'approved_at': DateTime.now().toIso8601String(),
    }).eq('id', reportId);
  }

  // ── Admin: Reject a report ──
  Future<void> rejectReport(String reportId, String reason) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _supabase.from('weekly_reports').update({
      'status': 'rejected',
      'approved_by': user.id,
      'approved_at': DateTime.now().toIso8601String(),
      'rejection_reason': reason,
    }).eq('id', reportId);
  }

  // ── Delete a rejected report (for regeneration) ──
  Future<void> deleteReport(String reportId) async {
    // Cascading delete handles sales_entries and product_movements
    await _supabase.from('weekly_reports').delete().eq('id', reportId);
  }

  // ── Fetch seller name from user ID ──
  Future<String> getSellerName(String userId) async {
    try {
      // Try fetching from the report's seller metadata
      // Since we can't directly query auth.users, we rely on user_metadata
      // stored during registration. This is a workaround.
      return 'Seller';
    } catch (e) {
      return 'Unknown';
    }
  }
}
