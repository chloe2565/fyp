import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../model/databaseModel.dart';
import '../../service/payment.dart';
import '../../service/bill.dart';
import '../../model/paymentDetailViewModel.dart';
import '../service/user.dart';

class PaymentController with ChangeNotifier {
  final PaymentService paymentService = PaymentService();
  final BillService billService = BillService();
  final UserService userService = UserService();

  bool isLoading = true;
  bool isFiltering = false;
  List<PaymentModel> allPayments = [];
  List<PaymentModel> filteredPayments = [];

  bool detailIsLoading = true;
  PaymentDetailViewModel? detailViewModel;
  String? detailError;

  bool get loading => isLoading;
  bool get filtering => isFiltering;
  List<PaymentModel> get filtered => filteredPayments;

  bool get detailLoading => detailIsLoading;
  PaymentDetailViewModel? get detailModel => detailViewModel;
  String? get detailErrorText => detailError;

  // Add & Edit new payment
  bool isLoadingAddData = true;
  List<BillingModel> pendingBills = [];
  Map<String, String> pendingBillsDropdown = {};

  final TextEditingController paymentIDController = TextEditingController();
  String? selectedBillingID;
  String? selectedPaymentMethod;
  File? selectedMediaProof;
  String? existingMediaProofName;
  final TextEditingController totalPriceController = TextEditingController();
  final TextEditingController createdAtController = TextEditingController();
  final TextEditingController paymentStatusController = TextEditingController();
  final TextEditingController adminRemarkController = TextEditingController();
  PaymentModel? existingPayment;
  static final dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  PaymentController() {
    // initialize();
  }

  // Customer side
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

  // Employee side
  Future<void> initializeForEmployee() async {
    isLoading = true;
    notifyListeners();

    try {
      allPayments = await paymentService.empGetPayments();
      allPayments.sort((a, b) => b.payCreatedAt.compareTo(a.payCreatedAt));
      filteredPayments = List.from(allPayments);
    } catch (e) {
      print("Error initializing Emp PaymentController: $e");
      allPayments = [];
      filteredPayments = [];
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> initializeAddPage() async {
    isLoadingAddData = true;
    notifyListeners();
    try {
      final nextID = await paymentService.generateNextID();
      paymentIDController.text = nextID;

      pendingBills = await billService.getPendingBills();

      pendingBillsDropdown = {
        for (var bill in pendingBills) bill.billingID: bill.billingID,
      };

      createdAtController.text = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(DateTime.now());
      paymentStatusController.text = 'Paid';

      selectedBillingID = null;
      selectedPaymentMethod = null;
      selectedMediaProof = null;
      existingMediaProofName = null;
      totalPriceController.clear();
      adminRemarkController.clear();
      existingPayment = null;
    } catch (e) {
      print("Error initializing Add Payment Page: $e");
    }
    isLoadingAddData = false;
    notifyListeners();
  }

  void initializeEditPage(PaymentModel payment) {
    isLoadingAddData = true;
    notifyListeners();

    existingPayment = payment;
    paymentIDController.text = payment.payID;
    selectedBillingID = payment.billingID;
    totalPriceController.text = payment.payAmt.toStringAsFixed(2);
    selectedPaymentMethod = payment.payMethod;
    existingMediaProofName = payment.payMediaProof;
    selectedMediaProof = null;
    createdAtController.text = dateTimeFormat.format(payment.payCreatedAt);
    paymentStatusController.text = payment.payStatus;
    adminRemarkController.text = payment.adminRemark;

    isLoadingAddData = false;
    notifyListeners();
  }

  void onBillingIDSelected(String? billID) {
    if (billID == null) {
      totalPriceController.text = "";
      selectedBillingID = null;
    } else {
      selectedBillingID = billID;
      final selectedBill = pendingBills.firstWhere(
        (bill) => bill.billingID == billID,
      );
      totalPriceController.text = selectedBill.billAmt.toStringAsFixed(2);
    }
    notifyListeners();
  }

  void onPaymentMethodSelected(String? method) {
    selectedPaymentMethod = method;
    notifyListeners();
  }

  void onPaymentStatusSelected(String? status) {
    if (status != null) {
      paymentStatusController.text = status;
      notifyListeners();
    }
  }

  Future<void> pickMediaProof() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        selectedMediaProof = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  void removeMediaProof() {
    selectedMediaProof = null;
    existingMediaProofName = null;
    notifyListeners();
  }

  Future<void> submitNewPayment() async {
    if (selectedBillingID == null ||
        selectedPaymentMethod == null ||
        totalPriceController.text.isEmpty) {
      throw Exception('Billing ID, Payment Method, and Price are required.');
    }

    if (selectedMediaProof == null) {
      throw Exception('Media proof is required.');
    }

    if (adminRemarkController.text.trim().isEmpty) {
      throw Exception('Admin remark cannot be empty.');
    }

    String mediaProofFileName = selectedMediaProof!.path.split('/').last;

    final String? providerID = await userService.getCurrentProviderID();
    if (providerID == null) {
      throw Exception("Could not find a valid Service Provider ID.");
    }

    await paymentService.createNewPayment(
      billingID: selectedBillingID!,
      payAmt: double.parse(totalPriceController.text),
      payMethod: selectedPaymentMethod!,
      providerID: providerID,
      payStatus: paymentStatusController.text,
      adminRemark: adminRemarkController.text.trim(),
      payMediaProof: mediaProofFileName,
    );

    await initializeForEmployee();
  }

  Future<void> submitPaymentUpdate(
    String payID,
    String billingID,
    Map<String, dynamic> updateData,
    String newPayStatus,
  ) async {
    final String? providerID = await userService.getCurrentProviderID();
    if (providerID == null) {
      throw Exception("Could not find a valid Service Provider ID.");
    }
    updateData['providerID'] = providerID;

    await paymentService.updatePayment(
      payID,
      billingID,
      updateData,
      newPayStatus,
    );

    await initializeForEmployee();

    existingPayment = await paymentService.getPaymentById(payID);
    notifyListeners();
  }

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

  Future<void> loadPaymentDetails(PaymentModel payment) async {
    detailIsLoading = true;
    detailError = null;
    detailViewModel = null;
    existingPayment = null;
    notifyListeners();

    try {
      final PaymentModel? freshPayment = await paymentService.getPaymentById(
        payment.payID,
      );

      if (freshPayment == null) {
        throw Exception("Payment record ${payment.payID} not found.");
      }
      existingPayment = freshPayment;

      final billingSnap = await FirebaseFirestore.instance
          .collection('Billing')
          .doc(payment.billingID)
          .get();

      if (!billingSnap.exists) throw Exception('Billing not found');

      final billing = BillingModel.fromMap(billingSnap.data()!);
      final billDetail = await billService.getBillDetails(billing);

      detailViewModel = PaymentDetailViewModel(
        billingID: freshPayment.billingID,
        payStatus: freshPayment.payStatus,
        payMethod: freshPayment.payMethod,
        payAmt: freshPayment.payAmt,
        payCreatedAt: freshPayment.payCreatedAt,
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
        paymentTimestamp: freshPayment.payCreatedAt,
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
    existingPayment = null;
  }
}
