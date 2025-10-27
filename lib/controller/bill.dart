import 'package:flutter/material.dart';
import '../model/databaseModel.dart';
import '../../service/bill.dart';
import '../model/billDetailViewModel.dart';
import '../modules/customer/payMethod.dart';

class BillController with ChangeNotifier {
  final BillService _billService = BillService();
  late BillingModel _selectedBillingModel;  

  // List State
  bool _isLoading = true;
  bool _isFiltering = false;
  List<BillingModel> _allBills = [];
  List<BillingModel> _filteredBills = [];

  bool get isLoading => _isLoading;
  bool get isFiltering => _isFiltering;
  List<BillingModel> get filteredBills => _filteredBills;

  // Detail State
  bool _detailIsLoading = true;
  BillDetailViewModel? _detailViewModel;
  String? _detailError;

  bool get detailIsLoading => _detailIsLoading;
  BillDetailViewModel? get detailViewModel => _detailViewModel;
  String? get detailError => _detailError;

  BillController() {
    initialize();
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allBills = await _billService.getBills();
      _allBills.sort((a, b) {
        bool isAPaid = a.billStatus.toLowerCase() == 'paid';
        bool isBPaid = b.billStatus.toLowerCase() == 'paid';
        if (isAPaid && !isBPaid) return 1;
        if (!isAPaid && isBPaid) return -1;
        return b.billDueDate.compareTo(a.billDueDate);
      });
      _filteredBills = _allBills;
    } catch (e) {
      print("Error initializing BillController: $e");
      _allBills = [];
      _filteredBills = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void onSearchChanged(String query) {
    _isFiltering = true;
    notifyListeners();

    if (query.isEmpty) {
      _filteredBills = _allBills;
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredBills = _allBills.where((bill) {
        return bill.billingID.toLowerCase().contains(lowerQuery) ||
            bill.billStatus.toLowerCase().contains(lowerQuery) ||
            bill.billAmt.toString().contains(lowerQuery);
      }).toList();
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      _isFiltering = false;
      notifyListeners();
    });
  }

  Future<void> loadBillDetails(BillingModel bill) async {
    _selectedBillingModel = bill;
    try {
      _detailIsLoading = true;
      _detailError = null;
      _detailViewModel = null;
      _detailViewModel = await _billService.getBillDetails(bill);
    } catch (e) {
      _detailError = "Failed to load billing details: $e";
    } finally {
      _detailIsLoading = false;
      notifyListeners();
    }
  }

  void clearBillDetails() {
    _detailIsLoading = true;
    _detailViewModel = null;
    _detailError = null;
  }

  void navigateToPayment(BuildContext context) {
    if (_detailViewModel == null) {
    print("Bill details not loaded yet.");
    return;
  }

    print("Navigating to payment page for ${_detailViewModel?.billingID}");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentMethodScreen(
          billingModel: _selectedBillingModel,
          billDetailViewModel: _detailViewModel!,
        ),
      ),
    );
  }
}
