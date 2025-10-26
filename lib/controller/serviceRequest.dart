import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/filterViewModel.dart';
import '../service/firestore_service.dart';
import '../service/user.dart';
import '../service/serviceRequest.dart';
import '../model/databaseModel.dart';
import '../../model/serviceRequestViewModel.dart';
import '../../shared/helper.dart';

FilterOutput performFiltering(FilterInput input) {
  final lowerQuery = input.searchQuery.toLowerCase();

  bool matchesSearch(RequestViewModel vm, String query) {
    if (query.isEmpty) return true;
    if (vm.title.toLowerCase().contains(query)) return true;
    if (vm.reqStatus.toLowerCase().contains(query)) return true;
    if (vm.details.any((entry) => entry.value.toLowerCase().contains(query))) {
      return true;
    }
    if (vm.amountToPay?.toLowerCase().contains(query) ?? false) return true;
    if (vm.payDueDate?.toLowerCase().contains(query) ?? false) return true;
    if (vm.paymentStatus?.toLowerCase().contains(query) ?? false) return true;

    return false;
  }

  // Filter Upcoming
  final filteredUpcoming = input.allUpcoming.where((vm) {
    final searchMatch =
        input.searchQuery.isEmpty || matchesSearch(vm, lowerQuery);
    final serviceMatch =
        input.selectedService == null || vm.title == input.selectedService;
    final statusMatch =
        input.selectedStatus == null ||
        vm.reqStatus.toLowerCase() == input.selectedStatus!.toLowerCase();
    final dateMatch =
        input.selectedDate == null ||
        DateUtils.isSameDay(vm.scheduledDateTime, input.selectedDate!);
    return searchMatch && serviceMatch && statusMatch && dateMatch;
  }).toList();

  // Filter History
  final filteredHistory = input.allHistory.where((vm) {
    final searchMatch =
        input.searchQuery.isEmpty || matchesSearch(vm, lowerQuery);
    final serviceMatch =
        input.selectedService == null || vm.title == input.selectedService;
    final statusMatch =
        input.selectedStatus == null ||
        vm.reqStatus.toLowerCase() == input.selectedStatus!.toLowerCase();
    final dateMatch =
        input.selectedDate == null ||
        DateUtils.isSameDay(vm.scheduledDateTime, input.selectedDate!);
    return searchMatch && serviceMatch && statusMatch && dateMatch;
  }).toList();

  return FilterOutput(
    filteredUpcoming: filteredUpcoming,
    filteredHistory: filteredHistory,
  );
}

class ServiceRequestController extends ChangeNotifier {
  final ServiceRequestService serviceRequest = ServiceRequestService();
  final UserService user = UserService();
  final db = FirestoreService.instance.db;

  String? currentCustomerID;
  bool isLoadingCustomer = false;
  bool isFiltering = false;
  List<RequestViewModel> allUpcomingRequests = [];
  List<RequestViewModel> allHistoryRequests = [];
  List<RequestViewModel> filteredUpcomingRequests = [];
  List<RequestViewModel> filteredHistoryRequests = [];
  List<String> allServiceNames = [];
  String searchQuery = '';
  String? selectedService;
  DateTime? selectedDate;
  String? selectedStatus;
  Timer? searchDebounce;

  Future<void> initialize() async {
    if (isLoadingCustomer) return;
    isLoadingCustomer = true;
    notifyListeners(); // Notify start loading
    currentCustomerID = await user.getCurrentCustomerID();

    if (currentCustomerID == null) {
      print("Error: Could not find customer ID for logged in user.");
      isLoadingCustomer = false;
      notifyListeners(); // Notify finish loading
      return;
    }

    await loadRequests();
  }

  Future<void> loadRequests() async {
    if (currentCustomerID == null) {
      return;
    }
    isLoadingCustomer = true;
    notifyListeners();

    final rawUpcomingData = serviceRequest.getUpcomingRequests(
      currentCustomerID!,
    );
    final rawHistoryData = serviceRequest.getHistoryRequests(
      currentCustomerID!,
    );
    final allServices = await serviceRequest.getAllServices();

    allUpcomingRequests = transformData(await rawUpcomingData);
    allHistoryRequests = transformData(await rawHistoryData);
    allServiceNames = allServices.map((s) => s.serviceName).toSet().toList();

    await applyFiltersAndNotify();
    isLoadingCustomer = false;
  }

  List<RequestViewModel> transformData(List<Map<String, dynamic>> rawList) {
    final viewModels = rawList.map((map) {
      final req = map['request'] as ServiceRequestModel;
      final service = map['service'] as ServiceModel;
      final billing = map['billing'] as BillingModel?;
      final String locationData = req.reqAddress;
      final handymanName = map['handymanName'] as String;
      final bookingDate = DateFormat(
        'MMMM dd, yyyy',
      ).format(req.scheduledDateTime);
      final startTime = DateFormat('hh:mm a').format(req.scheduledDateTime);
      String? formattedAmount;
      String? formattedDueDate;
      String? formattedBillStatus;

      if (billing != null) {
        formattedAmount = 'RM ${billing.billAmt.toStringAsFixed(2)}';
        formattedDueDate = DateFormat('MMMM dd, yyyy').format(billing.billDueDate);
        formattedBillStatus = capitalizeFirst(billing.billStatus);
      }

      return RequestViewModel(
        reqID: req.reqID,
        title: service.serviceName,
        icon: ServiceHelper.getIconForService(service.serviceName),
        reqStatus: capitalizeFirst(req.reqStatus),
        scheduledDateTime: req.scheduledDateTime,
        details: [
          MapEntry('Location', locationData),
          MapEntry('Booking date', bookingDate),
          MapEntry('Start time', startTime),
          MapEntry('Handyman name', capitalizeFirst(handymanName)),
        ],
        amountToPay: formattedAmount,
        payDueDate: formattedDueDate,
        paymentStatus: formattedBillStatus,
        requestModel: req, 
        handymanName: handymanName,
      );
    }).toList();
    return viewModels;
  }

  bool matchesSearch(RequestViewModel vm, String query) {
    if (query.isEmpty) return true;
    // Check title
    if (vm.title.toLowerCase().contains(query)) return true;
    // Check status
    if (vm.reqStatus.toLowerCase().contains(query)) return true;
    // Check all location, date, time, handyman
    if (vm.details.any((entry) => entry.value.toLowerCase().contains(query))) {
      return true;
    }
    if (vm.amountToPay?.toLowerCase().contains(query) ?? false) return true;
    if (vm.payDueDate?.toLowerCase().contains(query) ?? false) return true;
    if (vm.paymentStatus?.toLowerCase().contains(query) ?? false) return true;
    return false;
  }

  void onSearchChanged(String query) {
    searchDebounce?.cancel();
    searchDebounce = Timer(const Duration(milliseconds: 300), () {
      searchQuery = query;
      applyFiltersAndNotify();
    });
  }

  Future<void> applyFilters({
    String? service,
    DateTime? date,
    String? status,
  }) async {
    selectedService = service;
    selectedDate = date;
    selectedStatus = status;
    await applyFiltersAndNotify();
  }

  Future<void> clearFilters() async {
    searchQuery = '';
    selectedService = null;
    selectedDate = null;
    selectedStatus = null;
    await applyFiltersAndNotify();
  }

  Future<void> applyFiltersAndNotify() async {
    if (isFiltering) return;
    isFiltering = true;
    notifyListeners();

    try {
      final input = FilterInput(
        allUpcoming: List.unmodifiable(allUpcomingRequests),
        allHistory: List.unmodifiable(allHistoryRequests),
        searchQuery: searchQuery,
        selectedService: selectedService,
        selectedDate: selectedDate,
        selectedStatus: selectedStatus,
      );

      final FilterOutput output = await compute(performFiltering, input);

      // Update lists back on the main thread
      filteredUpcomingRequests = output.filteredUpcoming;
      filteredHistoryRequests = output.filteredHistory;
    } catch (e) {
      print("Error during background filtering: $e");
      filteredUpcomingRequests = [];
      filteredHistoryRequests = [];
    } finally {
      isFiltering = false;
      notifyListeners();
    }
  }

  RequestViewModel? getRequestById(String reqID) {
    final allRequests = [...allUpcomingRequests, ...allHistoryRequests];
    try {
      final request = allRequests.firstWhere((vm) => vm.reqID == reqID);
      return request;
    } catch (e) {
      print("Error: Request $reqID not found.");
      return null;
    }
  }

  @override
  void dispose() {
    searchDebounce?.cancel();
    super.dispose();
  }

  Future<bool> addNewRequest({
    required String locationAddress,
    required DateTime scheduledDateTime,
    required String description,
    required String serviceID,
    required List<String> reqPicFileName,
    String? remark,
  }) async {
    if (currentCustomerID == null) {
      print("Error: User not logged in. Cannot submit request.");
      return false;
    }

    try {
      final String newReqID = await serviceRequest.generateNextID();
      final String hardcodedHandymanID = "H0001";

      final ServiceRequestModel newRequest = ServiceRequestModel(
        reqID: newReqID,
        reqDateTime: DateTime.now(),
        scheduledDateTime: scheduledDateTime,
        reqAddress: locationAddress,
        reqDesc: description,
        reqPicName: reqPicFileName,
        reqStatus: 'pending',
        reqRemark: remark,
        custID: currentCustomerID!,
        serviceID: serviceID,
        handymanID: hardcodedHandymanID,
      );

      await serviceRequest.addServiceRequest(newRequest);
      loadRequests();

      return true;
    } catch (e) {
      print("Error in controller while adding request: $e");
      return false;
    }
  }

  Future<void> cancelRequest(String reqID) async {
    try {
      await serviceRequest.cancelRequest(reqID);
      loadRequests();
    } catch (e) {
      print('Error cancelling request: $e');
    }
  }

  Future<void> rescheduleRequest(String reqID) async {
    await serviceRequest.rescheduleRequest(reqID);
  }
  
}
