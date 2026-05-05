import 'package:flutter/foundation.dart';

class SalesEntry {
  final String id;
  String productName;
  String category;
  int quantitySold;
  double unitPrice;
  double? manualTotal; // null = auto-calculate
  double amountReceived;

  SalesEntry({
    String? id,
    this.productName = '',
    this.category = '',
    this.quantitySold = 0,
    this.unitPrice = 0.0,
    this.manualTotal,
    this.amountReceived = 0.0,
  }) : id = id ?? UniqueKey().toString();

  double get totalPrice => manualTotal ?? (quantitySold * unitPrice);
  double get balanceDue => totalPrice - amountReceived;

  SalesEntry copyWith({
    String? productName,
    String? category,
    int? quantitySold,
    double? unitPrice,
    double? manualTotal,
    double? amountReceived,
  }) {
    return SalesEntry(
      id: id,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      quantitySold: quantitySold ?? this.quantitySold,
      unitPrice: unitPrice ?? this.unitPrice,
      manualTotal: manualTotal ?? this.manualTotal,
      amountReceived: amountReceived ?? this.amountReceived,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'category': category,
      'quantitySold': quantitySold,
      'unitPrice': unitPrice,
      'manualTotal': manualTotal,
      'amountReceived': amountReceived,
    };
  }

  factory SalesEntry.fromJson(Map<String, dynamic> json) {
    return SalesEntry(
      id: json['id'] as String?,
      productName: json['productName'] as String? ?? '',
      category: json['category'] as String? ?? '',
      quantitySold: (json['quantitySold'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      manualTotal: (json['manualTotal'] as num?)?.toDouble(),
      amountReceived: (json['amountReceived'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ProductMovement {
  int lastWeekMoved;
  int newArrivals;
  int? manualCurrentStock; // null = auto-calculate

  ProductMovement({
    this.lastWeekMoved = 0,
    this.newArrivals = 0,
    this.manualCurrentStock,
  });

  int get currentlyAvailable => manualCurrentStock ?? (newArrivals - lastWeekMoved);
}

class ProductMovementEntry {
  final String id;
  String productName;
  int previousStock;
  int productsMoved;
  int newStockAdded;
  int? manualCurrentStock; // null = auto-calculate

  ProductMovementEntry({
    String? id,
    this.productName = '',
    this.previousStock = 0,
    this.productsMoved = 0,
    this.newStockAdded = 0,
    this.manualCurrentStock,
  }) : id = id ?? UniqueKey().toString();

  int get currentStock =>
      manualCurrentStock ?? (previousStock - productsMoved + newStockAdded);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'previousStock': previousStock,
      'productsMoved': productsMoved,
      'newStockAdded': newStockAdded,
      'manualCurrentStock': manualCurrentStock,
    };
  }

  factory ProductMovementEntry.fromJson(Map<String, dynamic> json) {
    return ProductMovementEntry(
      id: json['id'] as String?,
      productName: json['productName'] as String? ?? '',
      previousStock: (json['previousStock'] as num?)?.toInt() ?? 0,
      productsMoved: (json['productsMoved'] as num?)?.toInt() ?? 0,
      newStockAdded: (json['newStockAdded'] as num?)?.toInt() ?? 0,
      manualCurrentStock: (json['manualCurrentStock'] as num?)?.toInt(),
    );
  }
}
