import 'package:flutter/foundation.dart';
import '../model/databaseModel.dart';
import '../../service/bill.dart';
import '../../service/payment.dart';

enum UserType { customer, employee }

class BillPaymentController extends ChangeNotifier {
  final BillService billService = BillService();
  final PaymentService paymentService = PaymentService();

  List<BillingModel> allBills = [];
  List<PaymentModel> allPayments = [];

  List<BillingModel> filteredBills = [];
  List<PaymentModel> filteredPayments = [];

  bool isLoadingBills = false;
  bool isLoadingPayments = false;

  String searchQuery = '';
  DateTime? startDate;
  DateTime? endDate;
  double? minAmount;
  double? maxAmount;
  Map<String, String> statusFilter = {};
  Map<String, String> paymentMethodFilter = {};

  List<BillingModel> get rawFilteredBills => filteredBills;
  List<PaymentModel> get rawFilteredPayments => filteredPayments;
  bool get isLoadingBill => isLoadingBills;
  bool get isLoadingPay => isLoadingPayments;
  bool get isLoading => isLoadingBills || isLoadingPayments;

  Future<void> initializeForCustomer() async {
    await Future.wait([
      initializeBills(userType: UserType.customer),
      initializePayments(userType: UserType.customer),
    ]);
  }

  Future<void> initializeForEmployee() async {
    await Future.wait([
      initializeBills(userType: UserType.employee),
      initializePayments(userType: UserType.employee),
    ]);
  }

  Future<void> initialize() async {
    await initializeForCustomer();
  }

  Future<void> initializeBills({required UserType userType}) async {
    isLoadingBills = true;
    notifyListeners();

    try {
      if (userType == UserType.customer) {
        allBills = await billService.getBills();
      } else {
        allBills = await billService.empGetBills();
      }

      allBills.sort((a, b) {
        bool isAPaid = a.billStatus.toLowerCase() == 'paid';
        bool isBPaid = b.billStatus.toLowerCase() == 'paid';
        if (isAPaid && !isBPaid) return 1;
        if (!isAPaid && isBPaid) return -1;
        return b.billDueDate.compareTo(a.billDueDate);
      });

      filteredBills = List.from(allBills);
    } catch (e) {
      print('Error initializing bills: $e');
      allBills = [];
      filteredBills = [];
    } finally {
      isLoadingBills = false;
      notifyListeners();
    }
  }

  Future<void> initializePayments({required UserType userType}) async {
    isLoadingPayments = true;
    notifyListeners();

    try {
      if (userType == UserType.customer) {
        allPayments = await paymentService.getPayments();
      } else {
        allPayments = await paymentService.empGetPayments();
      }

      allPayments.sort((a, b) => b.payCreatedAt.compareTo(a.payCreatedAt));

      filteredPayments = List.from(allPayments);
    } catch (e) {
      print('Error initializing payments: $e');
      allPayments = [];
      filteredPayments = [];
    } finally {
      isLoadingPayments = false;
      notifyListeners();
    }
  }

  void applyFilters({
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    Map<String, String>? statusFilter,
    Map<String, String>? paymentMethodFilter,
  }) {
    searchQuery = searchQuery ?? '';
    startDate = startDate;
    endDate = endDate;
    minAmount = minAmount;
    maxAmount = maxAmount;
    statusFilter = statusFilter ?? {};
    paymentMethodFilter = paymentMethodFilter ?? {};

    applyBillingFilters();
    applyPaymentFilters();

    notifyListeners();
  }

  void applyBillingFilters() {
    filteredBills = allBills.where((bill) {
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesBillingID = bill.billingID.toLowerCase().contains(query);
        final matchesReqID = bill.reqID.toLowerCase().contains(query);
        final matchesAmount = bill.billAmt.toString().contains(query);
        final matchesStatus = bill.billStatus.toLowerCase().contains(query);

        if (!matchesBillingID &&
            !matchesReqID &&
            !matchesAmount &&
            !matchesStatus) {
          return false;
        }
      }

      if (startDate != null) {
        final billDate = DateTime(
          bill.billDueDate.year,
          bill.billDueDate.month,
          bill.billDueDate.day,
        );
        final start = DateTime(
          startDate!.year,
          startDate!.month,
          startDate!.day,
        );
        if (billDate.isBefore(start)) {
          return false;
        }
      }

      if (endDate != null) {
        final billDate = DateTime(
          bill.billDueDate.year,
          bill.billDueDate.month,
          bill.billDueDate.day,
        );
        final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
        if (billDate.isAfter(end)) {
          return false;
        }
      }

      // Amount range filter
      if (minAmount != null && bill.billAmt < minAmount!) {
        return false;
      }

      if (maxAmount != null && bill.billAmt > maxAmount!) {
        return false;
      }

      // Status filter
      if (statusFilter.isNotEmpty) {
        final statusKey = bill.billStatus.toLowerCase();
        if (!statusFilter.containsKey(statusKey)) {
          return false;
        }
      }

      return true;
    }).toList();

    filteredBills.sort((a, b) {
      bool isAPaid = a.billStatus.toLowerCase() == 'paid';
      bool isBPaid = b.billStatus.toLowerCase() == 'paid';
      if (isAPaid && !isBPaid) return 1;
      if (!isAPaid && isBPaid) return -1;
      return b.billDueDate.compareTo(a.billDueDate);
    });
  }

  void applyPaymentFilters() {
    filteredPayments = allPayments.where((payment) {
      // Search query filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesBillingID = payment.billingID.toLowerCase().contains(
          query,
        );
        final matchesAmount = payment.payAmt.toString().contains(query);
        final matchesMethod = payment.payMethod.toLowerCase().contains(query);
        final matchesStatus = payment.payStatus.toLowerCase().contains(query);

        if (!matchesBillingID &&
            !matchesAmount &&
            !matchesMethod &&
            !matchesStatus) {
          return false;
        }
      }

      // Date range filter
      if (startDate != null) {
        final paymentDate = DateTime(
          payment.payCreatedAt.year,
          payment.payCreatedAt.month,
          payment.payCreatedAt.day,
        );
        final start = DateTime(
          startDate!.year,
          startDate!.month,
          startDate!.day,
        );
        if (paymentDate.isBefore(start)) {
          return false;
        }
      }

      if (endDate != null) {
        final paymentDate = DateTime(
          payment.payCreatedAt.year,
          payment.payCreatedAt.month,
          payment.payCreatedAt.day,
        );
        final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
        if (paymentDate.isAfter(end)) {
          return false;
        }
      }

      // Amount range filter
      if (minAmount != null && payment.payAmt < minAmount!) {
        return false;
      }

      if (maxAmount != null && payment.payAmt > maxAmount!) {
        return false;
      }

      // Status filter
      if (statusFilter.isNotEmpty) {
        final statusKey = payment.payStatus.toLowerCase();
        if (!statusFilter.containsKey(statusKey)) {
          return false;
        }
      }

      // Payment method filter
      if (paymentMethodFilter.isNotEmpty) {
        if (!paymentMethodFilter.containsKey(payment.payMethod)) {
          return false;
        }
      }

      return true;
    }).toList();

    filteredPayments.sort((a, b) => b.payCreatedAt.compareTo(a.payCreatedAt));
  }

  void resetFilters() {
    searchQuery = '';
    startDate = null;
    endDate = null;
    minAmount = null;
    maxAmount = null;
    statusFilter = {};
    paymentMethodFilter = {};

    filteredBills = List.from(allBills);
    filteredPayments = List.from(allPayments);

    notifyListeners();
  }

  Future<void> refresh({UserType userType = UserType.customer}) async {
    if (userType == UserType.customer) {
      await initializeForCustomer();
    } else {
      await initializeForEmployee();
    }
    applyFilters(
      searchQuery: searchQuery,
      startDate: startDate,
      endDate: endDate,
      minAmount: minAmount,
      maxAmount: maxAmount,
      statusFilter: statusFilter,
      paymentMethodFilter: paymentMethodFilter,
    );
  }

  @override
  void dispose() {
    allBills.clear();
    allPayments.clear();
    filteredBills.clear();
    filteredPayments.clear();
    super.dispose();
  }
}
