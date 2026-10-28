import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// In-App Purchases service mock template for open-source repository.
/// Real store product IDs, purchase validation, and backend sync logic are excluded for security.
class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  bool isElite = false;
  List<ProductDetails> products = [];
  Function? onStatusChanged;

  void initialize() async {
    debugPrint("IAPService: Open-source mock initialized.");
  }

  Future<void> verifySubscription() async {}

  Future<void> loadProducts() async {}

  Future<void> buyProduct(String productId) async {
    debugPrint("IAPService: buyProduct($productId) called in open-source mock.");
  }

  Future<void> buyElite() async {
    debugPrint("IAPService: buyElite called in open-source mock.");
  }

  Future<void> buyEliteLifetime() async {
    debugPrint("IAPService: buyEliteLifetime called in open-source mock.");
  }

  Future<void> restorePurchases() async {
    debugPrint("IAPService: restorePurchases called in open-source mock.");
  }

  void dispose() {}
}
