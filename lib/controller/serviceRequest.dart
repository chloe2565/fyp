import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as l;
import '../model/filterViewModel.dart';
import '../service/fcm_service.dart';
import '../service/firestore_service.dart';
import '../service/rf_handyman_service.dart';
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
  final HandymanMatchingService matchingService = HandymanMatchingService(
    apiBaseUrl:
        'https://fyp-randomforest.onrender.com', // Replace with your server IP
  );

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

  Future<String?> addNewRequestWithAsyncMatching({
    required String locationAddress,
    required l.LatLng locationCoordinates,
    required DateTime scheduledDateTime,
    required String description,
    required String serviceID,
    required List<File> imageFiles,
    String? remark,
  }) async {
    if (currentCustomerID == null) {
      print("Error: User not logged in. Cannot submit request.");
      return null;
    }

    try {
      final String newReqID = await serviceRequest.generateNextID();
      final uploadedUrls = await serviceRequest.uploadRequestImages(
        imageFiles: imageFiles,
        reqID: newReqID,
      );
      final photoUrls = uploadedUrls.whereType<String>().toList();

      if (photoUrls.isEmpty && imageFiles.isNotEmpty) {
        throw Exception('Failed to upload images');
      }

      // Create service request with "pending" status
      final ServiceRequestModel newRequest = ServiceRequestModel(
        reqID: newReqID,
        reqDateTime: DateTime.now(),
        scheduledDateTime: scheduledDateTime,
        reqAddress: locationAddress,
        reqDesc: description,
        reqPicName: photoUrls,
        reqStatus: 'pending',
        reqCustomCancel: remark,
        custID: currentCustomerID!,
        serviceID: serviceID,
        handymanID: null,
      );
      await serviceRequest.addServiceRequest(newRequest);

      print('Service request created with ID: $newReqID, status: pending');

      // Handyman matching in background
      findAndAssignHandyman(
        reqID: newReqID,
        serviceID: serviceID,
        scheduledDateTime: scheduledDateTime,
        locationCoordinates: locationCoordinates,
        customerID: currentCustomerID!,
      );

      return newReqID;
    } catch (e) {
      print("Error creating service request: $e");
      return null;
    }
  }

  // Manual matching
  Future<String?> addNewRequestWithManualMatching({
    required String locationAddress,
    required l.LatLng locationCoordinates,
    required DateTime scheduledDateTime,
    required String description,
    required String serviceID,
    required List<File> imageFiles,
    String? remark,
  }) async {
    if (currentCustomerID == null) {
      print("Error: User not logged in. Cannot submit request.");
      return null;
    }

    try {
      final String newReqID = await serviceRequest.generateNextID();

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
        reqCustomCancel: remark,
        custID: currentCustomerID!,
        serviceID: serviceID,
        handymanID: null,
      );

      await serviceRequest.addServiceRequest(newRequest);

      print(
        'Service request created with ID: $newReqID (manual assignment mode)',
      );

      // Send notification to admin
      final fcmService = FCMService();
      final adminSnapshot = await db
          .collection('Employee')
          .where('empType', isEqualTo: 'admin')
          .where('empStatus', isEqualTo: 'active')
          .get();

      for (var adminDoc in adminSnapshot.docs) {
        final userID = adminDoc.data()['userID']?.toString();
        if (userID != null) {
          await fcmService.sendNotificationToUser(
            userID: userID,
            title: 'New Service Request',
            body: 'A new service request requires handyman assignment.',
            data: {'type': 'new_service_request_pending', 'reqID': newReqID},
          );
        }
      }

      await loadRequests();

      return newReqID;
    } catch (e) {
      print("Error creating service request (manual mode): $e");
      return null;
    }
  }

  // Background process to find and assign handyman
  Future<void> findAndAssignHandyman({
    required String reqID,
    required String serviceID,
    required DateTime scheduledDateTime,
    required l.LatLng locationCoordinates,
    required String customerID,
  }) async {
    try {
      print('Starting background handyman matching for request: $reqID');

      // Get service duration
      final serviceDoc = await db.collection('Service').doc(serviceID).get();

      if (!serviceDoc.exists) {
        throw Exception('Service not found: $serviceID');
      }

      final serviceData = serviceDoc.data();
      final serviceDuration = serviceData?['serviceDuration'] ?? '3 hours';
      final durationHours = parseDuration(serviceDuration.toString());

      // Find best matching handyman
      final bestMatch = await matchingService.findBestHandyman(
        serviceID: serviceID,
        scheduledDateTime: scheduledDateTime,
        customerLocation: {
          'latitude': locationCoordinates.latitude,
          'longitude': locationCoordinates.longitude,
        },
        serviceDurationHours: durationHours,
      );

      if (bestMatch == null) {
        // No handyman found - cancel request and notify customer
        await handleNoHandymanFound(reqID, customerID, serviceID);
        return;
      }

      final matchedHandymanID = bestMatch['handyman_id'] as String;
      final matchScore = bestMatch['match_score'] as double;
      final handymanName = bestMatch['handyman_name'] as String;

      print(
        'Best match found: $handymanName (Score: ${(matchScore * 100).toStringAsFixed(1)}%)',
      );

      // Update request with handyman and change status to confirmed
      await db.collection('ServiceRequest').doc(reqID).update({
        'handymanID': matchedHandymanID,
        'reqStatus': 'confirmed',
      });

      print(
        'Service request $reqID confirmed with handyman: $matchedHandymanID',
      );

      final customerQuery = await db
          .collection('Customer')
          .where('custID', isEqualTo: customerID)
          .limit(1)
          .get();

      if (customerQuery.docs.isNotEmpty) {
        final customerUserID = customerQuery.docs.first
            .data()['userID']
            ?.toString();

        if (customerUserID != null && customerUserID.isNotEmpty) {
          // Send notification to customer
          final fcmService = FCMService();
          await fcmService.sendNotificationToUser(
            userID: customerUserID,
            title: 'Handyman Found!',
            body: 'Your service request has been confirmed with $handymanName.',
            data: {
              'type': 'service_request_confirmed',
              'reqID': reqID,
              'handymanID': matchedHandymanID,
            },
          );
        } else {
          print('No userID found for customer: $customerID');
        }
      } else {
        print('Customer not found with custID: $customerID');
      }

      // Send notification to handyman
      final handymanDoc = await db
          .collection('Handyman')
          .doc(matchedHandymanID)
          .get();

      if (handymanDoc.exists) {
        final empID = handymanDoc.data()?['empID']?.toString();

        if (empID != null && empID.isNotEmpty) {
          final empQuery = await db
              .collection('Employee')
              .where('empID', isEqualTo: empID)
              .limit(1)
              .get();

          if (empQuery.docs.isNotEmpty) {
            final handymanUserID = empQuery.docs.first
                .data()['userID']
                ?.toString();

            if (handymanUserID != null && handymanUserID.isNotEmpty) {
              final fcmService = FCMService();
              await fcmService.sendNotificationToUser(
                userID: handymanUserID,
                title: 'New Service Request',
                body: 'You have been assigned to a new service request.',
                data: {'type': 'new_service_request', 'reqID': reqID},
              );
            }
          }
        }
      }
      await loadRequests();
    } catch (e) {
      print("Error in background handyman matching: $e");
      // Handle error - cancel request and notify customer
      await handleNoHandymanFound(reqID, customerID, serviceID);
    }
  }

  Future<void> handleNoHandymanFound(
    String reqID,
    String customerID,
    String serviceID,
  ) async {
    try {
      print('No handyman available for request: $reqID');
      await db.collection('ServiceRequest').doc(reqID).update({
        'reqStatus': 'cancelled',
        'reqCustomCancel': 'No available handyman found for the requested time',
        'reqCancelDateTime': FieldValue.serverTimestamp(),
      });

      final customerQuery = await db
          .collection('Customer')
          .where('custID', isEqualTo: customerID)
          .limit(1)
          .get();

      String? userID;
      if (customerQuery.docs.isNotEmpty) {
        userID = customerQuery.docs.first.data()['userID']?.toString();
      }

      if (userID != null && userID.isNotEmpty) {
        print('Sending cancellation notification to userID: $userID');

        final fcmService = FCMService();
        final notificationSent = await fcmService.sendNotificationToUser(
          userID: userID,
          title: 'Service Request Cancelled',
          body:
              'Sorry, no handyman is available for your requested time. Please try another time slot.',
          data: {'type': 'service_request_cancelled', 'reqID': reqID},
        );

        if (!notificationSent) {
          print('FCM notification failed, will rely on app UI refresh');
        }
      } else {
        print('Could not find userID for customer: $customerID');
      }

      showLocalCancellationNotification(reqID);
      await loadRequests();
    } catch (e) {
      print('Error handling no handyman found: $e');

      try {
        showLocalCancellationNotification(reqID);
        await loadRequests();
      } catch (reloadError) {
        print('Error reloading requests: $reloadError');
      }
    }
  }

  void showLocalCancellationNotification(String reqID) {
    try {
      final FlutterLocalNotificationsPlugin localNotifications =
          FlutterLocalNotificationsPlugin();

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'service_request_channel',
            'Service Requests',
            channelDescription: 'Notifications for service request updates',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      localNotifications.show(
        reqID.hashCode,
        'Service Request Cancelled',
        'Sorry, no handyman is available for your requested time. Please try another time slot.',
        notificationDetails,
      );

      print('Local notification shown for cancelled request: $reqID');
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  double parseDuration(String duration) {
    if (duration.isEmpty) return 3.0;

    final cleaned = duration
        .toLowerCase()
        .replaceAll('hours', '')
        .replaceAll('hour', '')
        .replaceAll('h', '')
        .trim();

    final rangePattern = RegExp(r'(\d+\.?\d*)\s*(?:to|-)\s*(\d+\.?\d*)');
    final rangeMatch = rangePattern.firstMatch(cleaned);

    if (rangeMatch != null) {
      final min = double.parse(rangeMatch.group(1)!);
      final max = double.parse(rangeMatch.group(2)!);
      return max;
    }

    final singlePattern = RegExp(r'(\d+\.?\d*)');
    final singleMatch = singlePattern.firstMatch(cleaned);

    if (singleMatch != null) {
      return double.parse(singleMatch.group(1)!);
    }

    print(
      'Warning: Could not parse duration "$duration", using default 3.0 hours',
    );
    return 3.0;
  }

  // Check if AI matching service is available
  Future<bool> isAIMatchingAvailable() async {
    return await matchingService.checkAPIHealth();
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
