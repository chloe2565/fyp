import 'package:flutter/material.dart';
import '../model/databaseModel.dart';
import '../../service/payment.dart'; 

class PaymentController with ChangeNotifier {
  final PaymentService _paymentService = PaymentService();

  bool _isLoading = true;
  bool _isFiltering = false;
  List<PaymentModel> _allPayments = [];
  List<PaymentModel> _filteredPayments = [];

  bool get isLoading => _isLoading;
  bool get isFiltering => _isFiltering;
  List<PaymentModel> get filteredPayments => _filteredPayments;

  PaymentController() {
    initialize();
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allPayments = await _paymentService.getPayments();
      _allPayments.sort((a, b) => b.payCreatedAt.compareTo(a.payCreatedAt));
      _filteredPayments = _allPayments;
    } catch (e) {
      print("Error initializing PaymentController: $e");
      _allPayments = [];
      _filteredPayments = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void onSearchChanged(String query) {
    _isFiltering = true;
    notifyListeners();

    if (query.isEmpty) {
      _filteredPayments = _allPayments;
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredPayments = _allPayments.where((payment) {
        return payment.billingID.toLowerCase().contains(lowerQuery) ||
            payment.payMethod.toLowerCase().contains(lowerQuery) ||
            payment.payStatus.toLowerCase().contains(lowerQuery) ||
            payment.payAmt.toString().contains(lowerQuery);
      }).toList();
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      _isFiltering = false;
      notifyListeners();
    });
  }
}