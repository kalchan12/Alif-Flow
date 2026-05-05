/// Represents a product from the database with its current price.
class ProductPrice {
  final String id;
  String productName;
  String category;
  double unitPrice;
  bool isActive;
  int sortOrder;
  final DateTime? updatedAt;

  ProductPrice({
    required this.id,
    required this.productName,
    required this.category,
    this.unitPrice = 0.0,
    this.isActive = true,
    this.sortOrder = 0,
    this.updatedAt,
  });

  factory ProductPrice.fromJson(Map<String, dynamic> json) {
    return ProductPrice(
      id: json['id'] as String,
      productName: json['product_name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_name': productName,
      'category': category,
      'unit_price': unitPrice,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  /// For local caching
  Map<String, dynamic> toCacheJson() {
    return {
      'id': id,
      'product_name': productName,
      'category': category,
      'unit_price': unitPrice,
      'is_active': isActive,
      'sort_order': sortOrder,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Represents a price change request from a seller.
class PriceChangeRequest {
  final String id;
  final String productId;
  final String productName;
  final String requestedBy;
  final double oldPrice;
  final double newPrice;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;

  PriceChangeRequest({
    required this.id,
    required this.productId,
    required this.productName,
    required this.requestedBy,
    required this.oldPrice,
    required this.newPrice,
    this.status = 'pending',
    required this.createdAt,
  });

  factory PriceChangeRequest.fromJson(Map<String, dynamic> json) {
    return PriceChangeRequest(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: json['products'] != null ? json['products']['product_name'] as String? ?? 'Unknown Product' : 'Unknown Product',
      requestedBy: json['requested_by'] as String,
      oldPrice: (json['old_price'] as num?)?.toDouble() ?? 0.0,
      newPrice: (json['new_price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
