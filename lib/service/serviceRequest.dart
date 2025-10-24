import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/database_model.dart';
import 'firestore_service.dart';

class ServiceRequestService {
  final FirebaseFirestore db = FirestoreService.instance.db;
  final CollectionReference servicesCollection = FirebaseFirestore.instance
      .collection('Service');

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

  Future<List<Map<String, dynamic>>> getUpcomingRequests(String custID) async {
    return fetchRequests(custID, ['pending', 'confirmed']);
  }

  Future<List<Map<String, dynamic>>> getHistoryRequests(String custID) async {
    return fetchRequests(custID, ['completed', 'cancelled']);
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

  Future<void> cancelRequest(String reqID) async {
    // Finds the request by reqID to update
    final query = await db
        .collection('ServiceRequest')
        .where('reqID', isEqualTo: reqID)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update({
        'reqStatus': 'cancelled',
        'reqCancelDateTime': Timestamp.now(),
      });
      print('Request $reqID cancelled');
    }
  }

  Future<void> rescheduleRequest(String reqID) async {
    // TODO: Implement reschedule logic
    print('Reschedule requested for $reqID');
  }

  Future<List<Map<String, dynamic>>> fetchRequests(
    String custID,
    List<String> statuses,
  ) async {
    try {
      // 1. Fetch all service requests
      final requestQuery = await db
          .collection('ServiceRequest')
          .where('custID', isEqualTo: custID)
          .where('reqStatus', whereIn: statuses)
          .get();

      if (requestQuery.docs.isEmpty) {
        return [];
      }

      final requests = requestQuery.docs
          .map((doc) => ServiceRequestModel.fromMap(doc.data()))
          .toList();

      // 2. Get unique IDs to fetch
      final serviceIds = requests.map((req) => req.serviceID).toSet().toList();
      final handymanIds = requests
          .map((req) => req.handymanID)
          .toSet()
          .toList();

      // 3. Fetch related services and handymen
      final serviceMap = await batchFetchServices(serviceIds);
      final handymanNameMap = await fetchHandymanNames(
        requests.map((req) => req.handymanID).toSet().toList(),
      );

      // 4. Combine all the data into a List of Maps
      final List<Map<String, dynamic>> detailsList = [];
      for (final req in requests) {
        final service = serviceMap[req.serviceID];
        final handymanName = handymanNameMap[req.handymanID];

        // Only add if all data exists
        if (service != null && handymanName != null) {
          detailsList.add({
            'request': req,
            'service': service,
            'handymanName': handymanName,
          });
        }
      }
      return detailsList;
    } catch (e) {
      print('Error fetching request details: $e');
      rethrow;
    }
  }

  Future<Map<String, ServiceModel>> batchFetchServices(List<String> ids) async {
    if (ids.isEmpty) return {};
    final query = await db
        .collection('Service')
        .where(FieldPath.documentId, whereIn: ids)
        .get();
    return {
      for (var doc in query.docs) doc.id: ServiceModel.fromMap(doc.data()),
    };
  }

  // Fetches Handyman docs by their document ID
  Future<Map<String, String>> fetchHandymanNames(
    List<String> handymanIds,
  ) async {
    if (handymanIds.isEmpty) return {};

    // 1. Handyman IDs -> Employee IDs
    final handymanQuery = await db
        .collection('Handyman')
        .where(FieldPath.documentId, whereIn: handymanIds)
        .get();

    // Map<HandymanID, EmployeeID>
    final Map<String, String> handymanToEmployeeMap = {};
    for (var doc in handymanQuery.docs) {
      handymanToEmployeeMap[doc.id] = doc.data()['empID'] as String? ?? '';
    }

    final employeeIds = handymanToEmployeeMap.values.toSet().toList();
    if (employeeIds.isEmpty) return {};

    // 2. Employee IDs -> User IDs
    final employeeQuery = await db
        .collection('Employee')
        .where(FieldPath.documentId, whereIn: employeeIds)
        .get();

    // Map<EmployeeID, UserID>
    final Map<String, String> employeeToUserMap = {};
    for (var doc in employeeQuery.docs) {
      employeeToUserMap[doc.id] = doc.data()['userID'] as String? ?? '';
    }

    final userIds = employeeToUserMap.values.toSet().toList();
    if (userIds.isEmpty) return {};

    // 3. User IDs -> User Names
    final userQuery = await db
        .collection('User')
        .where(FieldPath.documentId, whereIn: userIds)
        .get();

    // Map<UserID, UserName>
    final Map<String, String> userToNameMap = {};
    for (var doc in userQuery.docs) {
      userToNameMap[doc.id] = doc.data()['userName'] as String? ?? 'No Name';
    }

    // Map<HandymanID, UserName>
    final Map<String, String> finalHandymanNameMap = {};
    handymanToEmployeeMap.forEach((handymanId, employeeId) {
      final userId = employeeToUserMap[employeeId];
      final userName = userToNameMap[userId];
      if (userName != null) {
        finalHandymanNameMap[handymanId] = userName;
      }
    });

    return finalHandymanNameMap;
  }
}
