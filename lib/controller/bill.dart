import 'package:flutter/material.dart';
import '../model/databaseModel.dart';
import '../../service/bill.dart';
import '../model/billDetailViewModel.dart';
import '../modules/customer/payMethod.dart';

class BillController with ChangeNotifier {
  final BillService billService = BillService();
  late BillingModel selectedBillingModel;

  // List State
  bool isLoading = true;
  bool isFiltering = false;
  List<BillingModel> allBills = [];
  List<BillingModel> filteredBills = [];

  bool get Loading => isLoading;
  bool get liltering => isFiltering;
  List<BillingModel> get filtered => filteredBills;

  // Detail State
  bool detailIsLoading = true;
  BillDetailViewModel? detailViewModel;
  String? detailError;

  bool get detailLoading => detailIsLoading;
  BillDetailViewModel? get detailModel => detailViewModel;
  String? get detailErrorText => detailError;

  BillController() {
    initialize();
  }

  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();

    try {
      allBills = await billService.getBills();
      allBills.sort((a, b) {
        bool isAPaid = a.billStatus.toLowerCase() == 'paid';
        bool isBPaid = b.billStatus.toLowerCase() == 'paid';
        if (isAPaid && !isBPaid) return 1;
        if (!isAPaid && isBPaid) return -1;
        return b.billDueDate.compareTo(a.billDueDate);
      });
      filteredBills = allBills;
    } catch (e) {
      print("Error initializing BillController: $e");
      allBills = [];
      filteredBills = [];
    }

    isLoading = false;
    notifyListeners();
  }

  void onSearchChanged(String query) {
    if (query.isEmpty) {
      filteredBills = allBills;
    } else {
      final lowerQuery = query.toLowerCase();
      filteredBills = allBills.where((bill) {
        return bill.billingID.toLowerCase().contains(lowerQuery) ||
            bill.billStatus.toLowerCase().contains(lowerQuery) ||
            bill.billAmt.toString().contains(lowerQuery);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> loadBillDetails(BillingModel bill) async {
    selectedBillingModel = bill;
    try {
      detailIsLoading = true;
      detailError = null;
      detailViewModel = null;
      detailViewModel = await billService.getBillDetails(bill);
    } catch (e) {
      detailError = "Failed to load billing details: $e";
    } finally {
      detailIsLoading = false;
      notifyListeners();
    }
  }

  void clearBillDetails() {
    detailIsLoading = true;
    detailViewModel = null;
    detailError = null;
  }

  void navigateToPayment(BuildContext context) {
    if (detailViewModel == null) {
      print("Bill details not loaded yet.");
      return;
    }

    print("Navigating to payment page for ${detailViewModel?.billingID}");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentMethodScreen(
          billingModel: selectedBillingModel,
          billDetailViewModel: detailViewModel!,
        ),
      ),
    );
  }
}
