import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:osm_nominatim/osm_nominatim.dart';
import '../model/filterViewModel.dart';
import '../service/bill.dart';
import '../service/fcm_service.dart';
import '../service/firestore_service.dart';
import '../service/payment.dart';
import '../service/rf_handyman_service.dart';
import '../service/user.dart';
import '../service/serviceRequest.dart';
import '../service/nlp_service.dart';
import '../model/databaseModel.dart';
import '../../model/serviceRequestViewModel.dart';
import '../../shared/helper.dart';
import 'handyman.dart';

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
    apiBaseUrl: 'https://fyp-randomforest.onrender.com',
  );

  String? currentCustomerID;
  String? currentEmployeeID;
  String? currentEmployeeType;
  bool isLoadingCustomer = false;
  bool isFiltering = false;

  // For employee
  List<RequestViewModel> allPendingRequests = [];
  List<RequestViewModel> filteredPendingRequests = [];
  Map<String, String> requestUrgencyMap = {};
  bool isLoadingUrgency = false;

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

  String? _currentRescheduleReqID;
  String? _currentHandymanID;
  String? _currentServiceID;

  String? get currentRescheduleReqID => _currentRescheduleReqID;
  String? get currentHandymanID => _currentHandymanID;
  String? get currentServiceID => _currentServiceID;

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

    // Load urgency levels for upcoming requests before applying filters
    await loadUrgencyLevels(allUpcomingRequests);

    await applyFiltersAndNotify();
    isLoadingCustomer = false;
  }

  List<RequestViewModel> transformData(List<Map<String, dynamic>> rawList) {
    final viewModels = rawList.map((map) {
      final req = map['request'] as ServiceRequestModel;
      final service = map['service'] as ServiceModel;
      final billing = map['billing'] as BillingModel?;
      final paymentCreatedAt = map['paymentCreatedAt'] as DateTime?;
      final String locationData = req.reqAddress;
      final handymanName = map['handymanName'] as String;
      final handymanContact = map['handymanContact'] as String;
      final customerName = map['customerName'] as String? ?? 'Unknown';
      final customerContact = map['customerContact'] as String? ?? 'N/A';
      final reqDateTime = Formatter.formatDateTime(req.reqDateTime);
      final bookingDateTime = Formatter.formatDateTime(req.scheduledDateTime);
      String? formattedAmount;
      String? formattedDueDate;
      DateTime? rawDueDate;
      String? formattedBillStatus;

      if (billing != null) {
        formattedAmount = 'RM ${billing.billAmt.toStringAsFixed(2)}';
        rawDueDate = billing.billDueDate;
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
        reqDateTime: req.reqDateTime,
        scheduledDateTime: req.scheduledDateTime,
        details: [
          MapEntry('Created At', reqDateTime),
          MapEntry('Booking Date & Time', bookingDateTime),
          MapEntry('Location', locationData),
          MapEntry('Handyman Assigned', handymanName),
        ],
        amountToPay: formattedAmount,
        payDueDate: formattedDueDate,
        payDueDateRaw: rawDueDate,
        paymentStatus: formattedBillStatus,
        paymentCreatedAt: paymentCreatedAt,
        requestModel: req,
        handymanName: handymanName,
        handymanContact: handymanContact,
        customerName: customerName,
        customerContact: customerContact,
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

      if (currentEmployeeType == 'handyman' || currentEmployeeType == 'admin') {
        filteredUpcomingRequests = await sortRequestsByUrgencyAndLocation(
          output.filteredUpcoming,
        );
      } else {
        // Sort newest date first for customers
        filteredUpcomingRequests = List.from(output.filteredUpcoming);
        filteredUpcomingRequests.sort(
          (a, b) =>
              b.requestModel.reqDateTime.compareTo(a.requestModel.reqDateTime),
        );
      }

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
    required LatLng locationCoordinates,
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
        reqCompleteTime: null,
        scheduledDateTime: scheduledDateTime,
        reqAddress: locationAddress,
        reqDesc: description,
        reqPicName: photoUrls,
        reqStatus: 'pending',
        reqRemark: '',
        reqCustomCancel: null,
        custID: currentCustomerID!,
        serviceID: serviceID,
        handymanID: null,
        cancelID: null,
        reqCancelDateTime: null,
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
    required LatLng locationCoordinates,
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
        reqCompleteTime: null,
        scheduledDateTime: scheduledDateTime,
        reqAddress: locationAddress,
        reqDesc: description,
        reqPicName: photoUrls,
        reqStatus: 'pending',
        reqRemark: '',
        reqCustomCancel: null,
        custID: currentCustomerID!,
        serviceID: serviceID,
        handymanID: null,
        cancelID: null,
        reqCancelDateTime: null,
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
    required LatLng locationCoordinates,
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

      final fcmService = FCMService();

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
              final serviceName = serviceData?['serviceName'] ?? 'service';
              await fcmService.sendNotificationToUser(
                userID: handymanUserID,
                title: 'New Service Request',
                body:
                    'You have been assigned to a new $serviceName service request.',
                data: {'type': 'new_service_request', 'reqID': reqID},
              );
              print('Notification sent to handyman: $handymanUserID');
            } else {
              print('No userID found for handyman employee: $empID');
            }
          } else {
            print('Employee not found with empID: $empID');
          }
        } else {
          print('No empID found for handyman: $matchedHandymanID');
        }
      } else {
        print('Handyman document not found: $matchedHandymanID');
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

  Future<void> cancelRequest(String reqID, String cancellationReason) async {
    try {
      await serviceRequest.cancelRequest(reqID, cancellationReason);
    } catch (e) {
      print('Error cancelling request: $e');
      rethrow; // Rethrow to handle in UI
    }
  }

  Future<void> rescheduleRequest(String reqID) async {
    try {
      final requestViewModel = getRequestById(reqID);
      if (requestViewModel == null) {
        throw Exception('Service request not found');
      }

      final request = requestViewModel.requestModel;

      // Check if reschedule is allowed (2+ days before scheduled date)
      final now = DateTime.now();
      final scheduledDate = request.scheduledDateTime;
      final today = DateUtils.dateOnly(now);
      final scheduleDay = DateUtils.dateOnly(scheduledDate);
      final daysUntilScheduled = scheduleDay.difference(today).inDays;

      if (daysUntilScheduled < 2) {
        throw Exception(
          'Rescheduling is only allowed 2 or more days before the scheduled date',
        );
      }

      if (request.handymanID == null || request.handymanID!.isEmpty) {
        throw Exception('No handyman assigned to this request');
      }

      _currentRescheduleReqID = reqID;
      _currentHandymanID = request.handymanID!;
      _currentServiceID = request.serviceID;

      notifyListeners();
    } catch (e) {
      print('Error in rescheduleRequest controller: $e');
      rethrow;
    }
  }

  void clearRescheduleData() {
    _currentRescheduleReqID = null;
    _currentHandymanID = null;
    _currentServiceID = null;
    notifyListeners();
  }

  Future<void> confirmReschedule(DateTime newScheduledDateTime) async {
    if (_currentRescheduleReqID == null ||
        _currentHandymanID == null ||
        _currentServiceID == null) {
      throw Exception('Reschedule data not initialized');
    }

    // Check for conflicts
    final conflictCheck = await serviceRequest.checkRescheduleConflicts(
      reqID: _currentRescheduleReqID!,
      handymanID: _currentHandymanID!,
      serviceID: _currentServiceID!,
      newScheduledDateTime: newScheduledDateTime,
    );

    if (conflictCheck['hasConflict'] == true) {
      throw Exception(conflictCheck['message'] ?? 'Scheduling conflict');
    }

    // Update the scheduled date/time
    await serviceRequest.updateScheduledDateTime(
      reqID: _currentRescheduleReqID!,
      newScheduledDateTime: newScheduledDateTime,
    );

    // Clear reschedule data
    clearRescheduleData();

    // Reload requests
    if (currentCustomerID != null) {
      await loadRequests();
    } else if (currentEmployeeID != null) {
      await loadRequestsForEmployee();
    }
  }

  Future<void> confirmRescheduleWithConflictCheck(
    DateTime newScheduledDateTime,
  ) async {
    if (_currentRescheduleReqID == null ||
        _currentHandymanID == null ||
        _currentServiceID == null) {
      throw Exception('Reschedule data not initialized');
    }

    try {
      // Get request details for location
      final reqDoc = await db
          .collection('ServiceRequest')
          .doc(_currentRescheduleReqID!)
          .get();

      if (!reqDoc.exists) {
        throw Exception('Service request not found');
      }

      final reqData = reqDoc.data()!;
      final oldDateTime = (reqData['scheduledDateTime'] as Timestamp).toDate();
      final reqAddress = reqData['reqAddress'] as String;

      // Check if current handyman has conflicts with new datetime
      final conflictCheck = await serviceRequest.checkRescheduleConflicts(
        reqID: _currentRescheduleReqID!,
        handymanID: _currentHandymanID!,
        serviceID: _currentServiceID!,
        newScheduledDateTime: newScheduledDateTime,
      );

      String? assignedHandymanID = _currentHandymanID;

      // If current handyman has conflicts, find a new handyman
      if (conflictCheck['hasConflict'] == true) {
        print('Current handyman has conflict, finding new handyman...');

        // Parse location coordinates from address
        final locationCoords = await _parseLocationFromAddress(reqAddress);

        // Get service duration
        final serviceDoc = await db
            .collection('Service')
            .doc(_currentServiceID!)
            .get();

        if (!serviceDoc.exists) {
          throw Exception('Service not found');
        }

        final serviceData = serviceDoc.data()!;
        final serviceDuration = serviceData['serviceDuration'] ?? '3 hours';
        final durationHours = parseDuration(serviceDuration.toString());

        // Find best matching handyman for the new datetime
        final bestMatch = await matchingService.findBestHandyman(
          serviceID: _currentServiceID!,
          scheduledDateTime: newScheduledDateTime,
          customerLocation: {
            'latitude': locationCoords['latitude']!,
            'longitude': locationCoords['longitude']!,
          },
          serviceDurationHours: durationHours,
        );

        if (bestMatch == null) {
          throw Exception(
            'No available handyman found for the selected date and time. Please try a different time slot.',
          );
        }

        assignedHandymanID = bestMatch['handyman_id'] as String;
        print('New handyman assigned: $assignedHandymanID');
      }

      // Update the scheduled datetime and handyman (if changed)
      final Map<String, dynamic> updateData = {
        'scheduledDateTime': Timestamp.fromDate(newScheduledDateTime),
      };

      // Only update handymanID if it changed
      if (assignedHandymanID != _currentHandymanID) {
        updateData['handymanID'] = assignedHandymanID;
      }

      await db
          .collection('ServiceRequest')
          .doc(_currentRescheduleReqID!)
          .update(updateData);

      print(
        'Request ${_currentRescheduleReqID!} rescheduled to: $newScheduledDateTime',
      );
      if (assignedHandymanID != _currentHandymanID) {
        print(
          'Handyman changed from $_currentHandymanID to $assignedHandymanID',
        );
      }

      // Send notifications
      await _sendRescheduleNotifications(
        reqID: _currentRescheduleReqID!,
        newDateTime: newScheduledDateTime,
        oldDateTime: oldDateTime,
        oldHandymanID: _currentHandymanID!,
        newHandymanID: assignedHandymanID!,
      );

      // Clear reschedule data
      clearRescheduleData();

      // Reload requests
      if (currentCustomerID != null) {
        await loadRequests();
      } else if (currentEmployeeID != null) {
        await loadRequestsForEmployee();
      }
    } catch (e) {
      print('Error in confirmRescheduleWithConflictCheck: $e');
      rethrow;
    }
  }

  // Parse location coordinates from address string or geocode it
  Future<Map<String, double>> _parseLocationFromAddress(String address) async {
    try {
      final parts = address.split(',');
      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0].trim());
        final lon = double.tryParse(parts[1].trim());
        if (lat != null &&
            lon != null &&
            lat >= -90 &&
            lat <= 90 &&
            lon >= -180 &&
            lon <= 180) {
          return {'latitude': lat, 'longitude': lon};
        }
      }

      final coords = await geocodeAddress(address);
      if (coords != null) {
        return {'latitude': coords['lat']!, 'longitude': coords['lon']!};
      }

      throw Exception('Could not parse location from address');
    } catch (e) {
      print('Error parsing location: $e');
      rethrow;
    }
  }

  // Send notifications for reschedule
  Future<void> _sendRescheduleNotifications({
    required String reqID,
    required DateTime newDateTime,
    required DateTime oldDateTime,
    required String oldHandymanID,
    required String newHandymanID,
  }) async {
    try {
      final fcmService = FCMService();

      // Get request details
      final reqDoc = await db.collection('ServiceRequest').doc(reqID).get();
      if (!reqDoc.exists) return;

      final reqData = reqDoc.data()!;
      final custID = reqData['custID'] as String?;
      final serviceID = reqData['serviceID'] as String;

      // Get service name
      final serviceDoc = await db.collection('Service').doc(serviceID).get();
      final serviceName = serviceDoc.exists
          ? (serviceDoc.data()?['serviceName'] ?? 'service')
          : 'service';

      final formattedNewTime = Formatter.formatDateTime(newDateTime);
      final formattedOldTime = Formatter.formatDateTime(oldDateTime);
      final String custMsgStandard =
          'Your service request $serviceName has been rescheduled from $formattedOldTime to $formattedNewTime with a different handyman.';
      final String custMsgHandymanChanged =
          'Your service request $serviceName has been rescheduled from $formattedOldTime to $formattedNewTime.';
      final String baseMessage =
          'Service request $serviceName has been rescheduled from $formattedOldTime to $formattedNewTime.';
      final handymanChanged = oldHandymanID != newHandymanID;

      // Notify Customer
      if (custID != null) {
        final customerQuery = await db
            .collection('Customer')
            .where('custID', isEqualTo: custID)
            .limit(1)
            .get();
        if (customerQuery.docs.isNotEmpty) {
          final customerUserID = customerQuery.docs.first
              .data()['userID']
              ?.toString();
          if (customerUserID != null) {
            final String bodyToSend = handymanChanged
                ? custMsgHandymanChanged
                : custMsgStandard;

            await fcmService.sendNotificationToUser(
              userID: customerUserID,
              title: 'Service Request Rescheduled',
              body: bodyToSend,
              data: {'type': 'service_request_rescheduled', 'reqID': reqID},
            );
          }
        }
      }

      // Notify Handyman
      if (handymanChanged) {
        // Handyman Changed, Notify new Handyman
        await _notifyHandymanUser(
          fcmService,
          newHandymanID,
          'New Service Assignment',
          'You have been assigned to $serviceName. $baseMessage',
          reqID,
        );

        // Notify old Handyman they were removed
        await _notifyHandymanUser(
          fcmService,
          oldHandymanID,
          'Service Assignment Update',
          'You have been removed from Request $reqID due to rescheduling.',
          reqID,
        );
      } else {
        // Same Handyman, Notify time change
        await _notifyHandymanUser(
          fcmService,
          newHandymanID,
          'Service Rescheduled',
          baseMessage,
          reqID,
        );
      }

      // Notify Admins
      final adminSnapshot = await db
          .collection('Employee')
          .where('empType', isEqualTo: 'admin')
          .where('empStatus', isEqualTo: 'active')
          .get();

      for (var adminDoc in adminSnapshot.docs) {
        final adminUserID = adminDoc.data()['userID']?.toString();
        if (adminUserID != null) {
          await fcmService.sendNotificationToUser(
            userID: adminUserID,
            title: 'Service Request Rescheduled',
            body: baseMessage,
            data: {'type': 'service_request_rescheduled', 'reqID': reqID},
          );
        }
      }
    } catch (e) {
      print('Error sending reschedule notifications: $e');
    }
  }

  // Notifying handyman
  Future<void> _notifyHandymanUser(
    FCMService fcm,
    String handymanID,
    String title,
    String body,
    String reqID,
  ) async {
    final handymanDoc = await db.collection('Handyman').doc(handymanID).get();
    if (handymanDoc.exists) {
      final empID = handymanDoc.data()?['empID']?.toString();
      if (empID != null) {
        final empQuery = await db
            .collection('Employee')
            .where('empID', isEqualTo: empID)
            .limit(1)
            .get();
        if (empQuery.docs.isNotEmpty) {
          final userID = empQuery.docs.first.data()['userID']?.toString();
          if (userID != null) {
            await fcm.sendNotificationToUser(
              userID: userID,
              title: title,
              body: body,
              data: {'type': 'new_service_request', 'reqID': reqID},
            );
          }
        }
      }
    }
  }

  Future<void> updateRequestStatus(String reqID, String newStatus) async {
    try {
      await serviceRequest.updateRequestStatus(reqID, newStatus);

      // Send notifications for departed and completed status
      if (newStatus.toLowerCase() == 'departed' ||
          newStatus.toLowerCase() == 'completed') {
        await sendStatusUpdateNotifications(reqID, newStatus);
      }

      // Auto-create billing when status changes to completed
      if (newStatus.toLowerCase() == 'completed') {
        final billService = BillService();
        await billService.createBillingForCompletedRequest(reqID);
        print('Billing auto-created for completed request: $reqID');
      }

      await loadRequestsForEmployee();
    } catch (e) {
      print('Error updating request status: $e');
      rethrow;
    }
  }

  Future<void> sendStatusUpdateNotifications(
    String reqID,
    String newStatus,
  ) async {
    try {
      final fcmService = FCMService();

      // Get service request details
      final reqDoc = await db.collection('ServiceRequest').doc(reqID).get();
      if (!reqDoc.exists) {
        print('Service request not found: $reqID');
        return;
      }

      final reqData = reqDoc.data()!;
      final custID = reqData['custID']?.toString();

      // Prepare notification content based on status
      String notificationTitle;
      String notificationBody;
      String notificationType;

      if (newStatus.toLowerCase() == 'departed') {
        notificationTitle = 'Handyman Departed';
        notificationBody =
            'The handyman has departed and is on the way to your location.';
        notificationType = 'service_request_departed';
      } else {
        // completed
        notificationTitle = 'Service Completed';
        notificationBody =
            'Your service request has been completed successfully!';
        notificationType = 'service_request_completed';
      }

      // Send notification to customer
      if (custID != null && custID.isNotEmpty) {
        final customerQuery = await db
            .collection('Customer')
            .where('custID', isEqualTo: custID)
            .limit(1)
            .get();

        if (customerQuery.docs.isNotEmpty) {
          final customerUserID = customerQuery.docs.first
              .data()['userID']
              ?.toString();

          if (customerUserID != null && customerUserID.isNotEmpty) {
            await fcmService.sendNotificationToUser(
              userID: customerUserID,
              title: notificationTitle,
              body: notificationBody,
              data: {'type': notificationType, 'reqID': reqID},
            );
            print('Notification sent to customer for status: $newStatus');
          }
        }
      }

      // Send notification to all active admins
      final adminSnapshot = await db
          .collection('Employee')
          .where('empType', isEqualTo: 'admin')
          .where('empStatus', isEqualTo: 'active')
          .get();

      for (var adminDoc in adminSnapshot.docs) {
        final adminUserID = adminDoc.data()['userID']?.toString();
        if (adminUserID != null && adminUserID.isNotEmpty) {
          await fcmService.sendNotificationToUser(
            userID: adminUserID,
            title: 'Service Request Update',
            body:
                'Service request $reqID has been updated to ${newStatus.toLowerCase()}.',
            data: {'type': notificationType, 'reqID': reqID},
          );
        }
      }
      print('Notifications sent to admins for status: $newStatus');
    } catch (e) {
      print('Error sending status update notifications: $e');
    }
  }

  Future<void> loadUrgencyLevels(List<RequestViewModel> requests) async {
    final requestsToAnalyze = requests.where((req) {
      return req.requestModel.reqDesc.isNotEmpty &&
          !requestUrgencyMap.containsKey(req.reqID);
    }).toList();

    if (requestsToAnalyze.isEmpty) return;

    isLoadingUrgency = true;
    notifyListeners();

    try {
      // Batch analyze descriptions
      final analyses = await Future.wait(
        requestsToAnalyze.map(
          (req) => NLPService.analyzeDescription(req.requestModel.reqDesc),
        ),
      );

      for (int i = 0; i < requestsToAnalyze.length; i++) {
        final analysis = analyses[i];
        if (analysis != null) {
          requestUrgencyMap[requestsToAnalyze[i].reqID] = analysis.urgency;
        } else {
          requestUrgencyMap[requestsToAnalyze[i].reqID] = 'normal';
        }
      }
    } catch (e) {
      print('Error loading urgency levels: $e');
      // Set default urgency for failed requests
      for (var req in requestsToAnalyze) {
        requestUrgencyMap[req.reqID] = 'normal';
      }
    } finally {
      isLoadingUrgency = false;
      notifyListeners();
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = toRadians(lat2 - lat1);
    final dLon = toRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(toRadians(lat1)) *
            cos(toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double toRadians(double degree) {
    return degree * pi / 180;
  }

  Future<List<RequestViewModel>> sortRequestsByUrgencyAndLocation(
    List<RequestViewModel> requests,
  ) async {
    if (requests.isEmpty) return requests;

    print('\n=== Starting Sort Process ===');
    print('Total requests to sort: ${requests.length}');

    // Load urgency levels if not already loaded
    await loadUrgencyLevels(requests);

    // Group requests by date
    final Map<DateTime, List<RequestViewModel>> requestsByDate = {};

    for (var request in requests) {
      final dateOnly = DateUtils.dateOnly(request.scheduledDateTime);
      if (!requestsByDate.containsKey(dateOnly)) {
        requestsByDate[dateOnly] = [];
      }
      requestsByDate[dateOnly]!.add(request);
    }

    // Sort dates (earliest first)
    final sortedDates = requestsByDate.keys.toList()..sort();

    print('\nGrouped by dates:');
    for (var date in sortedDates) {
      print(
        '  ${DateFormat('yyyy-MM-dd').format(date)}: ${requestsByDate[date]!.length} requests',
      );
    }

    // Process each date group
    List<RequestViewModel> sortedRequests = [];

    for (var date in sortedDates) {
      final dateRequests = requestsByDate[date]!;
      print(
        '\n--- Processing date: ${DateFormat('yyyy-MM-dd').format(date)} ---',
      );

      // For each date, sort by urgency and distance
      final sortedDateRequests = await sortByUrgencyAndDistance(
        dateRequests,
        date,
      );
      sortedRequests.addAll(sortedDateRequests);
    }

    print('\n=== Sort Complete ===\n');
    return sortedRequests;
  }

  // Sort requests by urgency level and then by distance
  Future<List<RequestViewModel>> sortByUrgencyAndDistance(
    List<RequestViewModel> requests,
    DateTime date,
  ) async {
    if (requests.isEmpty) return requests;

    print(
      '  Sorting ${requests.length} requests for ${DateFormat('yyyy-MM-dd').format(date)}',
    );

    // Get handyman locations for all unique handymen in these requests
    final Map<String, GeoPoint?> handymanLocations = {};

    for (var request in requests) {
      final handymanID = request.requestModel.handymanID;
      if (handymanID != null &&
          handymanID.isNotEmpty &&
          !handymanLocations.containsKey(handymanID)) {
        final location = await HandymanController.getHandymanLocationById(
          handymanID,
        );
        handymanLocations[handymanID] = location;

        if (location != null) {
          print(
            '  Handyman $handymanID location: (${location.latitude}, ${location.longitude})',
          );
        } else {
          print('  Handyman $handymanID: No valid location found');
        }
      }
    }

    // Geocode request addresses to get coordinates
    final Map<String, Map<String, double>?> requestCoordinates = {};

    for (var request in requests) {
      final address = request.requestModel.reqAddress;
      if (!requestCoordinates.containsKey(address)) {
        final coords = await geocodeAddress(address);
        requestCoordinates[address] = coords;

        if (coords != null) {
          print(
            '  Request ${request.reqID} location: (${coords['lat']}, ${coords['lon']})',
          );
        } else {
          print('  Request ${request.reqID}: Failed to geocode address');
        }
      }
    }

    // Create list with calculated distances for debugging
    final List<Map<String, dynamic>> requestsWithData = [];

    for (var request in requests) {
      final urgency = requestUrgencyMap[request.reqID] ?? 'normal';
      final handymanID = request.requestModel.handymanID;
      double? distance;

      if (handymanID != null) {
        final handymanLoc = handymanLocations[handymanID];
        final coords = requestCoordinates[request.requestModel.reqAddress];

        if (handymanLoc != null && coords != null) {
          distance = await getRoadDistance(
            handymanLoc.latitude,
            handymanLoc.longitude,
            coords['lat']!,
            coords['lon']!,
          );

          // Fallback to Haversine (straight line) if API fails
          if (distance == null) {
            print("OSRM failed, using Haversine fallback for ${request.reqID}");
            distance = calculateDistance(
              handymanLoc.latitude,
              handymanLoc.longitude,
              coords['lat']!,
              coords['lon']!,
            );
          }
        }
      }

      requestsWithData.add({
        'request': request,
        'urgency': urgency,
        'distance': distance,
        'handymanID': handymanID,
      });
    }

    // Sort by urgency first, then by distance
    requestsWithData.sort((a, b) {
      final requestA = a['request'] as RequestViewModel;
      final requestB = b['request'] as RequestViewModel;
      final urgencyA = a['urgency'] as String;
      final urgencyB = b['urgency'] as String;
      final distanceA = a['distance'] as double?;
      final distanceB = b['distance'] as double?;

      //Sort by urgency (highest priority first)
      final urgencyPriorityA = getUrgencyPriority(urgencyA);
      final urgencyPriorityB = getUrgencyPriority(urgencyB);
      final urgencyComparison = urgencyPriorityB.compareTo(urgencyPriorityA);

      if (urgencyComparison != 0) {
        return urgencyComparison;
      }

      // If same urgency, sort by distance (nearest first)
      if (distanceA == null && distanceB == null) {
        return 0;
      } else if (distanceA == null) {
        return 1; // b comes first
      } else if (distanceB == null) {
        return -1; // a comes first
      }

      return distanceA.compareTo(distanceB);
    });

    // Print sorted order for debugging
    print('\n  Sorted order:');
    for (int i = 0; i < requestsWithData.length; i++) {
      final data = requestsWithData[i];
      final request = data['request'] as RequestViewModel;
      final urgency = data['urgency'] as String;
      final distance = data['distance'] as double?;
      final distanceStr = distance != null
          ? '${distance.toStringAsFixed(2)} km'
          : 'N/A';

      print('  ${i + 1}. ReqID: ${request.reqID}');
      print(
        '     Urgency: $urgency (priority: ${getUrgencyPriority(urgency)})',
      );
      print('     Distance: $distanceStr');
      print('     Handyman: ${data['handymanID'] ?? 'N/A'}');
      print(
        '     Time: ${DateFormat('HH:mm').format(request.scheduledDateTime)}',
      );
    }

    return requestsWithData
        .map((data) => data['request'] as RequestViewModel)
        .toList();
  }

  // Geocode address to get coordinates
  Future<Map<String, double>?> geocodeAddress(String address) async {
    try {
      // Check if address already contains coordinates in "lat,lon" format
      final parts = address.split(',');
      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0].trim());
        final lon = double.tryParse(parts[1].trim());
        if (lat != null &&
            lon != null &&
            lat >= -90 &&
            lat <= 90 &&
            lon >= -180 &&
            lon <= 180) {
          return {'lat': lat, 'lon': lon};
        }
      }

      // Otherwise, geocode the address using Nominatim
      final nominatim = Nominatim(userAgent: 'com.example.fyp');
      final results = await nominatim.searchByName(query: address, limit: 1);

      if (results.isNotEmpty) {
        return {'lat': results.first.lat, 'lon': results.first.lon};
      }

      return null;
    } catch (e) {
      print('Error geocoding address "$address": $e');
      return null;
    }
  }

  // Calculates driving distance using OSRM API
  Future<double?> getRoadDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$lon1,$lat1;$lon2,$lat2?overview=false',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          // OSRM returns distance in meters, convert to km
          final distanceInMeters = data['routes'][0]['distance'] as num;
          return distanceInMeters / 1000.0;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching road distance: $e');
      return null;
    }
  }

  String getUrgencyLevel(String reqID) {
    return requestUrgencyMap[reqID] ?? 'normal';
  }

  Future<PaymentModel?> getPaymentForRequest(String reqID) async {
    try {
      // First get the billing info
      final billingMap = await serviceRequest.fetchBillingInfo([reqID]);
      final billing = billingMap[reqID];

      if (billing == null) {
        print('No billing found for request: $reqID');
        return null;
      }

      final paymentService = PaymentService();
      final payment = await paymentService.getPaymentForBill(billing.billingID);

      return payment;
    } catch (e) {
      print('Error fetching payment for request: $e');
      return null;
    }
  }
}
