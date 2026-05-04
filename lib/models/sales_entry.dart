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
