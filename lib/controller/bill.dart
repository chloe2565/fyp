import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/databaseModel.dart';
import '../../service/bill.dart';
import '../model/billDetailViewModel.dart';
import '../modules/customer/payMethod.dart';
import '../service/user.dart';

class BillController with ChangeNotifier {
  final BillService billService = BillService();
  final UserService userService = UserService();
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

  // Add bill
  bool isLoadingAddData = true;
  List<ServiceRequestModel> completableServiceRequests = [];
  Map<String, String> completableServiceRequestsDropdown = {};

  final TextEditingController billingIDController = TextEditingController();
  String? selectedServiceRequestID;
  final TextEditingController servicePriceController = TextEditingController();
  final TextEditingController outstationFeeController = TextEditingController();
  final TextEditingController totalPriceController = TextEditingController();
  String billingStatus = 'pending';
  String adminRemark = '';
  final TextEditingController createdAtController = TextEditingController();

  // Edit bill
  BillingModel? billToEdit;
  final TextEditingController serviceRequestIDController =
      TextEditingController();
  final List<String> billStatuses = ['pending', 'paid', 'cancelled'];
  String? selectedBillStatus;

  BillController() {
    // initialize();
    servicePriceController.addListener(calculateTotalPrice);
    outstationFeeController.addListener(calculateTotalPrice);
  }

  // Customer side
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

  // Employee side
  Future<void> initializeForEmployee() async {
    isLoading = true;
    notifyListeners();

    try {
      allBills = await billService.empGetBills();
      allBills.sort((a, b) {
        bool isAPaid = a.billStatus.toLowerCase() == 'paid';
        bool isBPaid = b.billStatus.toLowerCase() == 'paid';
        if (isAPaid && !isBPaid) return 1;
        if (!isAPaid && isBPaid) return -1;
        return b.billDueDate.compareTo(a.billDueDate);
      });
      filteredBills = allBills;
    } catch (e) {
      print("Error initializing Emp BillController: $e");
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
            bill.reqID.toLowerCase().contains(lowerQuery) ||
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

  Future<void> initializeAddPage() async {
    isLoadingAddData = true;
    notifyListeners();
    try {
      final nextID = await billService.generateNextBillID();
      billingIDController.text = nextID;

      completableServiceRequests = await billService
          .getCompleteServiceRequests();

      completableServiceRequestsDropdown = {
        for (var req in completableServiceRequests) req.reqID: req.reqID,
      };

      createdAtController.text = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(DateTime.now());
    } catch (e) {
      print("Error initializing Add Bill Page: $e");
    }
    isLoadingAddData = false;
    notifyListeners();
  }

  Future<void> initializeEditPage(BillingModel bill) async {
    isLoadingAddData = true;
    billToEdit = bill;
    notifyListeners();

    try {
      billingIDController.text = bill.billingID;
      serviceRequestIDController.text = bill.reqID;
      createdAtController.text = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(bill.billCreatedAt);
      selectedBillStatus = bill.billStatus;

      final details = await billService.getBillDetails(bill);

      servicePriceController.text = details.serviceBasePrice!.toStringAsFixed(
        2,
      );
      outstationFeeController.text = (details.outstationFee ?? 0.0)
          .toStringAsFixed(2);
      totalPriceController.text = bill.billAmt.toStringAsFixed(2);
      servicePriceController.addListener(calculateTotalPrice);
      outstationFeeController.addListener(calculateTotalPrice);
    } catch (e) {
      print("Error initializing Edit Bill Page: $e");
      servicePriceController.addListener(calculateTotalPrice);
      outstationFeeController.addListener(calculateTotalPrice);
    }
    isLoadingAddData = false;
    notifyListeners();
  }

  void onBillStatusChanged(String? newValue) {
    if (newValue != null) {
      selectedBillStatus = newValue;
      notifyListeners();
    }
  }

  void onServiceRequestSelected(String? reqID) {
    if (reqID == null) return;

    selectedServiceRequestID = reqID;

    final selectedReq = completableServiceRequests.firstWhere(
      (req) => req.reqID == reqID,
    );

    final tempBill = BillingModel(
      billingID: '',
      reqID: selectedReq.reqID,
      billStatus: '',
      billAmt: 0,
      billDueDate: DateTime.now(),
      billCreatedAt: DateTime.now(),
      providerID: '',
      adminRemark: '',
    );
    billService
        .getBillDetails(tempBill)
        .then((details) {
          if (details.serviceBasePrice != null &&
              details.serviceBasePrice! > 0) {
            servicePriceController.text = details.serviceBasePrice!
                .toStringAsFixed(2);
          } else {
            servicePriceController.text = "";
          }

          if (details.outstationFee != null && details.outstationFee! > 0) {
            outstationFeeController.text = (details.outstationFee!)
                .toStringAsFixed(2);
          } else {
            outstationFeeController.text = "";
          }
        })
        .catchError((e) {
          print("Error fetching details for $reqID: $e");
          servicePriceController.text = "0.00";
          outstationFeeController.text = "0.00";
        });

    notifyListeners();
  }

  void calculateTotalPrice() {
    final double servicePrice =
        double.tryParse(servicePriceController.text) ?? 0.0;
    final double outstationFee =
        double.tryParse(outstationFeeController.text) ?? 0.0;
    final double total = servicePrice + outstationFee;
    totalPriceController.text = total.toStringAsFixed(2);
  }

  Future<void> submitNewBill() async {
    if (selectedServiceRequestID == null || billingIDController.text.isEmpty) {
      throw Exception('Service Request ID and Billing ID are required.');
    }

    final String? providerID = await userService.getCurrentProviderID();
    if (providerID == null) {
      throw Exception(
        "Could not find a valid Service Provider ID for the current user.",
      );
    }
    final total = double.tryParse(totalPriceController.text) ?? 0.0;
    final createdAt = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).parse(createdAtController.text);
    final dueDate = DateTime.now().add(const Duration(days: 3));

    final newBill = BillingModel(
      billingID: billingIDController.text,
      reqID: selectedServiceRequestID!,
      billStatus: billingStatus,
      billAmt: total,
      billDueDate: dueDate,
      billCreatedAt: createdAt,
      providerID: providerID,
      adminRemark: adminRemark,
    );

    await billService.addNewBill(newBill);
    await initializeForEmployee();
  }

  Future<void> submitUpdatedBill() async {
    if (billToEdit == null) {
      throw Exception('No bill selected for editing.');
    }

    if (selectedBillStatus == null) {
      throw Exception('Bill status is not selected.');
    }

    final total = double.tryParse(totalPriceController.text) ?? 0.0;

    final Map<String, dynamic> updateData = {
      'billStatus': selectedBillStatus!,
      'billAmt': total,
    };

    await billService.updateBillAndPayment(billToEdit!.billingID, updateData);
    await initializeForEmployee();
  }

  @override
  void dispose() {
    super.dispose();
    billingIDController.dispose();
    servicePriceController.dispose();
    outstationFeeController.dispose();
    totalPriceController.dispose();
    createdAtController.dispose();
    serviceRequestIDController.dispose();
  }
}
