import 'dart:async';
import 'dart:io';
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
    if (vm.reqID.toLowerCase().contains(query)) return true;
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

  // Helper function to check if date is within range
  bool isDateInRange(
    DateTime scheduleDate,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (startDate == null && endDate == null) return true;

    final scheduleOnly = DateUtils.dateOnly(scheduleDate);

    if (startDate != null && endDate != null) {
      final start = DateUtils.dateOnly(startDate);
      final end = DateUtils.dateOnly(endDate);
      return (scheduleOnly.isAtSameMomentAs(start) ||
              scheduleOnly.isAfter(start)) &&
          (scheduleOnly.isAtSameMomentAs(end) || scheduleOnly.isBefore(end));
    } else if (startDate != null) {
      final start = DateUtils.dateOnly(startDate);
      return scheduleOnly.isAtSameMomentAs(start) ||
          scheduleOnly.isAfter(start);
    } else if (endDate != null) {
      final end = DateUtils.dateOnly(endDate);
      return scheduleOnly.isAtSameMomentAs(end) || scheduleOnly.isBefore(end);
    }

    return true;
  }

  // Filter Pending (for employee)
  final filteredPending = input.allPending.where((vm) {
    final searchMatch =
        input.searchQuery.isEmpty || matchesSearch(vm, lowerQuery);

    final serviceMatch =
        input.selectedServices.isEmpty ||
        input.selectedServices.values.any(
          (serviceName) => vm.title == serviceName,
        );

    final statusMatch =
        input.selectedStatuses.isEmpty ||
        input.selectedStatuses.keys.any(
          (status) => vm.reqStatus.toLowerCase() == status.toLowerCase(),
        );

    final dateMatch = isDateInRange(
      vm.scheduledDateTime,
      input.startDate,
      input.endDate,
    );

    return searchMatch && serviceMatch && statusMatch && dateMatch;
  }).toList();

  // Filter Upcoming
  final filteredUpcoming = input.allUpcoming.where((vm) {
    final searchMatch =
        input.searchQuery.isEmpty || matchesSearch(vm, lowerQuery);

    final serviceMatch =
        input.selectedServices.isEmpty ||
        input.selectedServices.values.any(
          (serviceName) => vm.title == serviceName,
        );

    final statusMatch =
        input.selectedStatuses.isEmpty ||
        input.selectedStatuses.keys.any(
          (status) => vm.reqStatus.toLowerCase() == status.toLowerCase(),
        );

    final dateMatch = isDateInRange(
      vm.scheduledDateTime,
      input.startDate,
      input.endDate,
    );

    return searchMatch && serviceMatch && statusMatch && dateMatch;
  }).toList();

  // Filter History
  final filteredHistory = input.allHistory.where((vm) {
    final searchMatch =
        input.searchQuery.isEmpty || matchesSearch(vm, lowerQuery);

    final serviceMatch =
        input.selectedServices.isEmpty ||
        input.selectedServices.values.any(
          (serviceName) => vm.title == serviceName,
        );

    final statusMatch =
        input.selectedStatuses.isEmpty ||
        input.selectedStatuses.keys.any(
          (status) => vm.reqStatus.toLowerCase() == status.toLowerCase(),
        );

    final dateMatch = isDateInRange(
      vm.scheduledDateTime,
      input.startDate,
      input.endDate,
    );

    return searchMatch && serviceMatch && statusMatch && dateMatch;
  }).toList();

  return FilterOutput(
    filteredPending: filteredPending,
    filteredUpcoming: filteredUpcoming,
    filteredHistory: filteredHistory,
  );
}

class ServiceRequestController extends ChangeNotifier {
  final ServiceRequestService serviceRequest = ServiceRequestService();
  final UserService user = UserService();
  final db = FirestoreService.instance.db;

  String? currentCustomerID;
  String? currentEmployeeID;
  String? currentEmployeeType;
  bool isLoadingCustomer = false;
  bool isFiltering = false;

  // For employee
  List<RequestViewModel> allPendingRequests = [];
  List<RequestViewModel> filteredPendingRequests = [];

  // For both customer and employee
  List<RequestViewModel> allUpcomingRequests = [];
  List<RequestViewModel> allHistoryRequests = [];
  List<RequestViewModel> filteredUpcomingRequests = [];
  List<RequestViewModel> filteredHistoryRequests = [];

  List<String> allServiceNames = [];
  String searchQuery = '';
  Map<String, String> selectedServices = {};
  Map<String, String> selectedStatuses = {};
  DateTime? startDate;
  DateTime? endDate;

  Timer? searchDebounce;

  Future<void> initialize() async {
    if (isLoadingCustomer) return;
    isLoadingCustomer = true;
    notifyListeners();
    currentCustomerID = await user.getCurrentCustomerID();

    if (currentCustomerID == null) {
      print("Error: Could not find customer ID for logged in user.");
      isLoadingCustomer = false;
      notifyListeners();
      return;
    }

    await loadRequests();
  }

  Future<void> initializeForEmployee() async {
    if (isLoadingCustomer) return;
    isLoadingCustomer = true;
    notifyListeners();

    final empInfo = await user.getCurrentEmployeeInfo();

    if (empInfo == null) {
      print("Error: Could not find employee info for logged in user.");
      isLoadingCustomer = false;
      notifyListeners();
      return;
    }

    currentEmployeeID = empInfo['empID'];
    currentEmployeeType = empInfo['empType']; // 'admin' or 'handyman'

    await loadRequestsForEmployee();
  }

  // Customer side
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

  // Employee side
  Future<void> loadRequestsForEmployee() async {
    if (currentEmployeeID == null || currentEmployeeType == null) {
      return;
    }
    isLoadingCustomer = true;
    notifyListeners();

    final rawPendingData = serviceRequest.getPendingRequestsForEmployee(
      currentEmployeeID!,
      currentEmployeeType!,
    );
    final rawUpcomingData = serviceRequest.getUpcomingRequestsForEmployee(
      currentEmployeeID!,
      currentEmployeeType!,
    );
    final rawHistoryData = serviceRequest.getHistoryRequestsForEmployee(
      currentEmployeeID!,
      currentEmployeeType!,
    );
    final allServices = await serviceRequest.getAllServices();

    allPendingRequests = transformData(await rawPendingData);
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
        formattedDueDate = DateFormat(
          'MMMM dd, yyyy',
        ).format(billing.billDueDate);
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
    if (vm.reqID.toLowerCase().contains(query)) return true;
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

  void onSearchChanged(String query) {
    searchDebounce?.cancel();
    searchDebounce = Timer(const Duration(milliseconds: 300), () {
      searchQuery = query;
      applyFiltersAndNotify();
    });
  }

  Future<void> applyMultiFilters({
    Map<String, String>? services,
    Map<String, String>? statuses,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    selectedServices = services ?? {};
    selectedStatuses = statuses ?? {};
    this.startDate = startDate;
    this.endDate = endDate;
    await applyFiltersAndNotify();
  }

  Future<void> applyFilters({
    String? service,
    DateTime? date,
    String? status,
  }) async {
    selectedServices = service != null ? {service: service} : {};
    selectedStatuses = status != null ? {status: status} : {};
    startDate = date;
    endDate = date;
    await applyFiltersAndNotify();
  }

  Future<void> clearFilters() async {
    searchQuery = '';
    selectedServices = {};
    selectedStatuses = {};
    startDate = null;
    endDate = null;
    await applyFiltersAndNotify();
  }

  Future<void> applyFiltersAndNotify() async {
    if (isFiltering) return;
    isFiltering = true;
    notifyListeners();

    try {
      final input = FilterInput(
        allPending: List.unmodifiable(allPendingRequests),
        allUpcoming: List.unmodifiable(allUpcomingRequests),
        allHistory: List.unmodifiable(allHistoryRequests),
        searchQuery: searchQuery,
        selectedServices: selectedServices,
        selectedStatuses: selectedStatuses,
        startDate: startDate,
        endDate: endDate,
      );

      final FilterOutput output = await compute(performFiltering, input);

      filteredPendingRequests = output.filteredPending;
      filteredUpcomingRequests = output.filteredUpcoming;
      filteredHistoryRequests = output.filteredHistory;
    } catch (e) {
      print("Error during background filtering: $e");
      filteredPendingRequests = [];
      filteredUpcomingRequests = [];
      filteredHistoryRequests = [];
    } finally {
      isFiltering = false;
      notifyListeners();
    }
  }

  RequestViewModel? getRequestById(String reqID) {
    final allRequests = [
      ...allPendingRequests,
      ...allUpcomingRequests,
      ...allHistoryRequests,
    ];
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
    required List<File> imageFiles,
    String? remark,
  }) async {
    if (currentCustomerID == null) {
      print("Error: User not logged in. Cannot submit request.");
      return false;
    }

    try {
      final String newReqID = await serviceRequest.generateNextID();
      final String hardcodedHandymanID = "H0001";
      final uploadedUrls = await serviceRequest.uploadRequestImages(
        imageFiles: imageFiles,
        reqID: newReqID,
      );

      final photoUrls = uploadedUrls.whereType<String>().toList();

      if (photoUrls.isEmpty && imageFiles.isNotEmpty) {
        throw Exception('Failed to upload images');
      }

      final ServiceRequestModel newRequest = ServiceRequestModel(
        reqID: newReqID,
        reqDateTime: DateTime.now(),
        scheduledDateTime: scheduledDateTime,
        reqAddress: locationAddress,
        reqDesc: description,
        reqPicName: photoUrls,
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
      if (currentEmployeeID != null) {
        loadRequestsForEmployee();
      } else {
        loadRequests();
      }
    } catch (e) {
      print('Error cancelling request: $e');
    }
  }

  Future<void> rescheduleRequest(String reqID) async {
    await serviceRequest.rescheduleRequest(reqID);
  }
}
