import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:alif_flow/models/product_price.dart';

class PricingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _cacheKey = 'cached_product_prices';

  /// Fetch all active products with prices from Supabase.
  /// Falls back to local cache if offline.
  Future<List<ProductPrice>> fetchProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('is_active', true)
          .order('category')
          .order('sort_order');

      final products = (response as List)
          .map((e) => ProductPrice.fromJson(e as Map<String, dynamic>))
          .toList();

      // Cache locally for offline use
      await _cacheProducts(products);

      return products;
    } catch (e) {
      debugPrint('Failed to fetch products from Supabase: $e');
      // Fallback to cache
      return await _getCachedProducts();
    }
  }

  /// Get products grouped by category.
  Future<Map<String, List<ProductPrice>>> fetchProductsByCategory() async {
    final products = await fetchProducts();
    final Map<String, List<ProductPrice>> grouped = {};
    for (final product in products) {
      grouped.putIfAbsent(product.category, () => []).add(product);
    }
    return grouped;
  }

  /// Get the price for a specific product by name.
  /// Returns 0.0 if not found.
  double getPriceForProduct(String productName, List<ProductPrice> products) {
    final match = products.where(
      (p) => p.productName.toLowerCase() == productName.toLowerCase(),
    );
    if (match.isNotEmpty) {
      return match.first.unitPrice;
    }
    return 0.0;
  }

  /// Admin: Directly update a product's price.
  Future<void> updatePriceAsAdmin(String productId, double newPrice) async {
    await _supabase
        .from('products')
        .update({'unit_price': newPrice})
        .eq('id', productId);
  }

  /// Seller: Submit a price change request for admin approval.
  Future<void> requestPriceChange({
    required String productId,
    required double oldPrice,
    required double newPrice,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _supabase.from('price_change_requests').insert({
      'product_id': productId,
      'requested_by': user.id,
      'old_price': oldPrice,
      'new_price': newPrice,
      'status': 'pending',
    });
  }

  /// Admin: Approve a price change request and update the product price.
  Future<void> approvePriceChange(String requestId, String productId, double newPrice) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Update the request status
    await _supabase.from('price_change_requests').update({
      'status': 'approved',
      'reviewed_by': user.id,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);

    // Update the actual product price
    await _supabase
        .from('products')
        .update({'unit_price': newPrice})
        .eq('id', productId);
  }

  /// Admin: Reject a price change request.
  Future<void> rejectPriceChange(String requestId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _supabase.from('price_change_requests').update({
      'status': 'rejected',
      'reviewed_by': user.id,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }

  /// Fetch pending price change requests (for admin).
  Future<List<PriceChangeRequest>> fetchPendingRequests() async {
    final response = await _supabase
        .from('price_change_requests')
        .select('*, products(product_name)')
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => PriceChangeRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Local Caching ──

  Future<void> _cacheProducts(List<ProductPrice> products) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = products.map((p) => p.toCacheJson()).toList();
    await prefs.setString(_cacheKey, jsonEncode(jsonList));
  }

  Future<List<ProductPrice>> _getCachedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_cacheKey);
    if (jsonStr == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonStr);
    return jsonList
        .map((e) => ProductPrice.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
