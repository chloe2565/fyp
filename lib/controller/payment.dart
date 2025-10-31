// controller/payment.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../model/databaseModel.dart';
import '../../service/payment.dart';
import '../../service/bill.dart';
import '../../model/paymentDetailViewModel.dart';

class PaymentController with ChangeNotifier {
  final PaymentService paymentService = PaymentService();
  final BillService billService = BillService(); // <-- NEW

  // ────── LIST STATE ──────
  bool isLoading = true;
  bool isFiltering = false;
  List<PaymentModel> allPayments = [];
  List<PaymentModel> filteredPayments = [];

  // ────── DETAIL STATE ──────
  bool detailIsLoading = true;
  PaymentDetailViewModel? detailViewModel;
  String? detailError;

  // ────── GETTERS ──────
  bool get loading => isLoading;
  bool get filtering => isFiltering;
  List<PaymentModel> get filtered => filteredPayments;

  bool get detailLoading => detailIsLoading;
  PaymentDetailViewModel? get detailModel => detailViewModel;
  String? get detailErrorText => detailError;

  PaymentController() {
    initialize();
  }

  // ────── LIST INITIALISATION ──────
  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();

    try {
      allPayments = await paymentService.getPayments();
      allPayments.sort((a, b) => b.payCreatedAt.compareTo(a.payCreatedAt));
      filteredPayments = List.from(allPayments);
    } catch (e) {
      print("Error initializing PaymentController: $e");
      allPayments = [];
      filteredPayments = [];
    }

    isLoading = false;
    notifyListeners();
  }

  // ────── SEARCH ──────
  void onSearchChanged(String query) {
    if (query.isEmpty) {
      filteredPayments = List.from(allPayments);
    } else {
      final lower = query.toLowerCase();
      filteredPayments = allPayments.where((p) {
        return p.billingID.toLowerCase().contains(lower) ||
            p.payMethod.toLowerCase().contains(lower) ||
            p.payStatus.toLowerCase().contains(lower) ||
            p.payAmt.toString().contains(lower);
      }).toList();
    }
    notifyListeners();
  }

  // ────── DETAIL LOADER ──────
  Future<void> loadPaymentDetails(PaymentModel payment) async {
    detailIsLoading = true;
    detailError = null;
    detailViewModel = null;
    notifyListeners();

    try {
      // 1. Get the Billing record (we need reqID)
      final billingSnap = await FirebaseFirestore.instance
          .collection('Billing')
          .doc(payment.billingID)
          .get();

      if (!billingSnap.exists) throw Exception('Billing not found');

      final billing = BillingModel.fromMap(billingSnap.data()!);

      // 2. Reuse the **exact same** logic that BillService uses
      final billDetail = await billService.getBillDetails(billing);

      detailViewModel = PaymentDetailViewModel(
        billingID: payment.billingID,
        payStatus: payment.payStatus,
        payMethod: payment.payMethod,
        payAmt: payment.payAmt,
        payCreatedAt: payment.payCreatedAt,
        customerName: billDetail.customerName,
        customerContact: billDetail.customerContact,
        customerAddress: billDetail.customerAddress,
        serviceName: billDetail.serviceName,
        serviceBasePrice: billDetail.serviceBasePrice ?? 0.0,
        outstationFee: billDetail.outstationFee,
        totalPrice: billDetail.totalPrice,
        handymanName: billDetail.handymanName,
        bookingTimestamp: billDetail.bookingTimestamp,
        serviceCompleteTimestamp: billDetail.serviceCompleteTimestamp,
        paymentTimestamp: payment.payCreatedAt,
      );
    } catch (e) {
      detailError = 'Failed to load details: $e';
      print(e);
    } finally {
      detailIsLoading = false;
      notifyListeners();
    }
  }

  void clearDetails() {
    detailIsLoading = true;
    detailViewModel = null;
    detailError = null;
  }
}
