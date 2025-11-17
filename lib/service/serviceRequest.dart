import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/databaseModel.dart';
import 'customer.dart';
import 'firestore_service.dart';
import 'handyman.dart';
import 'image_service.dart';

class ServiceRequestService {
  final FirebaseFirestore db = FirestoreService.instance.db;
  final CustomerService custService = CustomerService();
  final HandymanService handyman = HandymanService();
  final CollectionReference servicesCollection = FirebaseFirestore.instance
      .collection('Service');
  final FirebaseImageService imageService = FirebaseImageService();

  Future<String> generateNextID() async {
    const String prefix = 'SR';
    const int padding = 4;

    final query = await db
        .collection('ServiceRequest')
        .where('reqID', isGreaterThanOrEqualTo: prefix)
        .where('reqID', isLessThan: '${prefix}Z')
        .orderBy('reqID', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return '$prefix${'1'.padLeft(padding, '0')}';
    }

    final lastID = query.docs.first.id;

    try {
      final numericPart = lastID.substring(prefix.length);
      final lastNumber = int.parse(numericPart);
      final nextNumber = lastNumber + 1;

      return '$prefix${nextNumber.toString().padLeft(padding, '0')}';
    } catch (e) {
      print("Error parsing last request ID '$lastID': $e");
      return '$prefix${'1'.padLeft(padding, '0')}';
    }
  }

  Future<List<ServiceModel>> getAllServices() async {
    try {
      QuerySnapshot querySnapshot = await servicesCollection
          .where('serviceStatus', isEqualTo: 'active')
          .get();

      print('Firestore: Retrieved ${querySnapshot.docs.length} services');

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ServiceModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('Firestore Error: $e');
      rethrow;
    }
  }

  Future<List<ServiceRequestModel>> getCompletedRequestsForCustomer(
    String custID,
  ) async {
    try {
      final querySnapshot = await db
          .collection('ServiceRequest')
          .where('custID', isEqualTo: custID)
          .where('reqStatus', isEqualTo: 'completed')
          .get();

      return querySnapshot.docs
          .map((doc) => ServiceRequestModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error in getCompletedRequestsForCustomer: $e');
      return [];
    }
  }

  // Employee admin side
  Future<List<ServiceRequestModel>> getAllRequests() async {
    try {
      final querySnapshot = await db.collection('ServiceRequest').get();
      return querySnapshot.docs
          .map((doc) => ServiceRequestModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error in getAllRequests: $e');
      return [];
    }
  }

  // Employee handyman side
  Future<List<ServiceRequestModel>> getRequestsForHandyman(
    String handymanID,
  ) async {
    try {
      final querySnapshot = await db
          .collection('ServiceRequest')
          .where('handymanID', isEqualTo: handymanID)
          .get();

      return querySnapshot.docs
          .map((doc) => ServiceRequestModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error in getRequestsForHandyman: $e');
      return [];
    }
  }

  // Customer side
  Future<List<Map<String, dynamic>>> getUpcomingRequests(String custID) async {
    return fetchRequests(custID, ['pending', 'confirmed', 'departed']);
  }

  Future<List<Map<String, dynamic>>> getHistoryRequests(String custID) async {
    return fetchRequests(custID, ['completed', 'cancelled']);
  }

  // Employee side
  Future<List<Map<String, dynamic>>> getPendingRequestsForEmployee(
    String empID,
    String empType,
  ) async {
    return fetchRequestsForEmployee(empID, empType, ['pending']);
  }

  Future<List<Map<String, dynamic>>> getUpcomingRequestsForEmployee(
    String empID,
    String empType,
  ) async {
    return fetchRequestsForEmployee(empID, empType, ['confirmed', 'departed']);
  }

  Future<List<Map<String, dynamic>>> getHistoryRequestsForEmployee(
    String empID,
    String empType,
  ) async {
    return fetchRequestsForEmployee(empID, empType, ['completed', 'cancelled']);
  }

  Future<void> addServiceRequest(ServiceRequestModel request) async {
    try {
      await db
          .collection('ServiceRequest')
          .doc(request.reqID)
          .set(request.toMap());
      print('Service Request ${request.reqID} added successfully.');
    } catch (e) {
      print('Error adding service request: $e');
      rethrow;
    }
  }

  Future<List<String?>> uploadRequestImages({
    required List<File> imageFiles,
    required String reqID,
  }) async {
    if (imageFiles.isEmpty) return [];

    try {
      final uploadedUrls = await imageService.uploadMultipleImages(
        imageFiles: imageFiles,
        category: ImageCategory.requests,
        uniqueId: reqID,
      );

      return uploadedUrls;
    } catch (e) {
      print('Error uploading request images: $e');
      return [];
    }
  }

  Future<Map<String, BillingModel>> fetchBillingInfo(
    List<String> reqIds,
  ) async {
    final validIds = reqIds.where((id) => id.isNotEmpty).toList();

    if (validIds.isEmpty) {
      print('No valid request IDs for billing');
      return {};
    }

    try {
      final query = await db
          .collection('Billing')
          .where('reqID', whereIn: validIds)
          .get();

      final Map<String, BillingModel> billingMap = {};
      for (var doc in query.docs) {
        final billing = BillingModel.fromMap(doc.data());
        billingMap[billing.reqID] = billing;
      }
      return billingMap;
    } catch (e) {
      print('Error fetching billing info: $e');
      return {};
    }
  }

  Future<Map<String, DateTime>> fetchPaymentCreatedDates(
    Map<String, BillingModel> billingMap,
  ) async {
    final paidBillIds = billingMap.entries
        .where((entry) => entry.value.billStatus.toLowerCase() == 'paid')
        .map((entry) => entry.value.billingID)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (paidBillIds.isEmpty) {
      print('No paid billings to fetch payment dates for');
      return {};
    }

    try {
      final query = await db
          .collection('Payment')
          .where('billingID', whereIn: paidBillIds)
          .where('payStatus', isEqualTo: 'paid')
          .get();

      final Map<String, DateTime> paymentMap = {};
      for (var doc in query.docs) {
        final data = doc.data();
        final billingID = data['billingID'] as String?;
        final payCreatedAt = data['payCreatedAt'] as Timestamp?;

        if (billingID != null && payCreatedAt != null) {
          paymentMap[billingID] = payCreatedAt.toDate();
        }
      }

      print('Fetched ${paymentMap.length} payment dates for paid billings');
      return paymentMap;
    } catch (e) {
      print('Error fetching payment info: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> fetchRequests(
    String custID,
    List<String> statuses,
  ) async {
    try {
      final requestQuery = await db
          .collection('ServiceRequest')
          .where('custID', isEqualTo: custID)
          .where('reqStatus', whereIn: statuses)
          .orderBy('reqDateTime', descending: true)
          .get();

      if (requestQuery.docs.isEmpty) {
        return [];
      }

      final requests = requestQuery.docs
          .map((doc) => ServiceRequestModel.fromMap(doc.data()))
          .toList();

      final serviceIds = requests
          .map((req) => req.serviceID)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final handymanIds = requests
          .map((req) => req.handymanID)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final reqIds = requests
          .map((req) => req.reqID)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final serviceMap = await batchFetchServices(serviceIds);
      final handymanNameMap = await handyman.fetchHandymanNames(handymanIds);
      final billingMap = await fetchBillingInfo(reqIds);
      final paymentCreatedMap = await fetchPaymentCreatedDates(billingMap);

      final List<Map<String, dynamic>> detailsList = [];
      for (final req in requests) {
        final service = serviceMap[req.serviceID];

        final handymanName =
            req.handymanID != null && req.handymanID!.isNotEmpty
            ? (handymanNameMap[req.handymanID] ?? 'Not Assigned')
            : 'Not Assigned';

        final billing = billingMap[req.reqID];

        DateTime? paymentCreatedAt;
        if (billing != null && billing.billStatus.toLowerCase() == 'paid') {
          paymentCreatedAt = paymentCreatedMap[billing.billingID];
        }

        if (service != null) {
          detailsList.add({
            'request': req,
            'service': service,
            'handymanName': handymanName,
            'billing': billing,
            'paymentCreatedAt': paymentCreatedAt,
          });
        } else {
          print('Warning: Service not found for request ${req.reqID}');
        }
      }
      return detailsList;
    } catch (e) {
      print('Error fetching request details: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchRequestsForEmployee(
    String empID,
    String empType,
    List<String> statuses,
  ) async {
    try {
      List<ServiceRequestModel> requests;

      if (empType.toLowerCase() == 'admin') {
        final requestQuery = await db
            .collection('ServiceRequest')
            .where('reqStatus', whereIn: statuses)
            .orderBy('reqDateTime', descending: true)
            .get();

        requests = requestQuery.docs
            .map((doc) => ServiceRequestModel.fromMap(doc.data()))
            .toList();
      } else {
        final handymanData = await db
            .collection('Handyman')
            .where('empID', isEqualTo: empID)
            .limit(1)
            .get();

        if (handymanData.docs.isEmpty) {
          print('No handyman found with empID: $empID');
          return [];
        }

        final handymanID = handymanData.docs.first.data()['handymanID'];

        final requestQuery = await db
            .collection('ServiceRequest')
            .where('handymanID', isEqualTo: handymanID)
            .where('reqStatus', whereIn: statuses)
            .orderBy('reqDateTime', descending: true)
            .get();

        requests = requestQuery.docs
            .map((doc) => ServiceRequestModel.fromMap(doc.data()))
            .toList();
      }

      if (requests.isEmpty) {
        return [];
      }

      final serviceIds = requests
          .map((req) => req.serviceID)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final handymanIds = requests
          .map((req) => req.handymanID)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final custIds = requests
          .map((req) => req.custID)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final reqIds = requests
          .map((req) => req.reqID)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final serviceMap = await batchFetchServices(serviceIds);
      final handymanNameMap = await handyman.fetchHandymanNames(handymanIds);
      final customerDetailsMap = await custService
          .fetchUserDetailsByCustomerIDs(custIds);
      final billingMap = await fetchBillingInfo(reqIds);
      final paymentCreatedMap = await fetchPaymentCreatedDates(billingMap);

      final List<Map<String, dynamic>> detailsList = [];
      for (final req in requests) {
        final service = serviceMap[req.serviceID];

        final handymanName =
            req.handymanID != null && req.handymanID!.isNotEmpty
            ? (handymanNameMap[req.handymanID] ?? 'Not Assigned')
            : 'Not Assigned';

        final customerDetails =
            customerDetailsMap[req.custID] ??
            {'name': 'Unknown', 'contact': 'N/A'};

        final billing = billingMap[req.reqID];

        DateTime? paymentCreatedAt;
        if (billing != null && billing.billStatus.toLowerCase() == 'paid') {
          paymentCreatedAt = paymentCreatedMap[billing.billingID];
        }

        if (service != null) {
          detailsList.add({
            'request': req,
            'service': service,
            'handymanName': handymanName,
            'customerName': customerDetails['name']!,
            'customerContact': customerDetails['contact']!,
            'billing': billing,
            'paymentCreatedAt': paymentCreatedAt,
          });
        } else {
          print('Warning: Service not found for request ${req.reqID}');
        }
      }
      return detailsList;
    } catch (e) {
      print('Error fetching request details for employee: $e');
      rethrow;
    }
  }

  Future<Map<String, ServiceModel>> batchFetchServices(List<String> ids) async {
    final validIds = ids.where((id) => id.isNotEmpty).toList();

    if (validIds.isEmpty) {
      print('No valid service IDs to fetch');
      return {};
    }

    try {
      final query = await db
          .collection('Service')
          .where(FieldPath.documentId, whereIn: validIds)
          .get();

      return {
        for (var doc in query.docs) doc.id: ServiceModel.fromMap(doc.data()),
      };
    } catch (e) {
      print('Error in batchFetchServices: $e');
      return {};
    }
  }

  Stream<ServiceRequestModel> getRequestStream(String reqID) {
    return db.collection('ServiceRequest').doc(reqID).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        return ServiceRequestModel.fromMap(snapshot.data()!);
      } else {
        throw Exception("Service request not found");
      }
    });
  }

  Future<void> cancelRequest(String reqID, String cancellationReason) async {
    final query = await db
        .collection('ServiceRequest')
        .where('reqID', isEqualTo: reqID)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update({
        'reqStatus': 'cancelled',
        'reqCancelDateTime': Timestamp.now(),
        'reqCustomCancel': cancellationReason,
      });
      print('Request $reqID cancelled with reason: $cancellationReason');
    }
  }

  Future<void> rescheduleRequest(String reqID) async {
    print('Reschedule requested for $reqID');
  }

  Future<void> updateRequestStatus(String reqID, String newStatus) async {
    try {
      Map<String, dynamic> updateData = {'reqStatus': newStatus};

      // Add completion timestamp if status is completed
      if (newStatus.toLowerCase() == 'completed') {
        updateData['reqCompleteTime'] = Timestamp.now();
      }

      await db.collection('ServiceRequest').doc(reqID).update(updateData);
      print('Request $reqID status updated to: $newStatus');
    } catch (e) {
      print('Error updating request status: $e');
      rethrow;
    }
  }
}
