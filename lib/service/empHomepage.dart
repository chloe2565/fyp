import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/databaseModel.dart';
import 'firestore_service.dart';

class DashboardService {
  final FirebaseFirestore db = FirestoreService.instance.db;

  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // Get request status counts for today
      final requestStatusCounts = await getRequestStatusCounts(
        startOfDay,
        endOfDay,
      );

      // Get handyman availability for today
      final handymanAvailability = await getHandymanAvailability(
        startOfDay,
        endOfDay,
      );

      // Get top 3 services for today
      final topServices = await getTopServices(startOfDay, endOfDay);

      return {
        'requestStatusCounts': requestStatusCounts,
        'handymanAvailability': handymanAvailability,
        'topServices': topServices,
      };
    } catch (e) {
      print('Error in getDashboardData: $e');
      rethrow;
    }
  }

  Future<Map<String, int>> getRequestStatusCounts(
    DateTime startOfDay,
    DateTime endOfDay,
  ) async {
    try {
      final requestsSnapshot = await db
          .collection('ServiceRequest')
          .where('scheduledDateTime', isGreaterThanOrEqualTo: startOfDay)
          .where('scheduledDateTime', isLessThanOrEqualTo: endOfDay)
          .get();

      final requests = requestsSnapshot.docs
          .map((doc) => ServiceRequestModel.fromMap(doc.data()))
          .toList();

      final statusCounts = <String, int>{
        'completed': 0,
        'on leave': 0,
        'late': 0,
        'absent': 0,
      };

      for (var request in requests) {
        final status = request.reqStatus.toLowerCase();
        if (statusCounts.containsKey(status)) {
          statusCounts[status] = statusCounts[status]! + 1;
        }
      }

      return statusCounts;
    } catch (e) {
      print('Error in getRequestStatusCounts: $e');
      return {};
    }
  }

  Future<Map<String, int>> getHandymanAvailability(
    DateTime startOfDay,
    DateTime endOfDay,
  ) async {
    try {
      // Get all handymen with availability records for today
      final availabilitySnapshot = await db
          .collection('HandymanAvailability')
          .where('availabilityStartDateTime', isLessThanOrEqualTo: endOfDay)
          .where('availabilityEndDateTime', isGreaterThanOrEqualTo: startOfDay)
          .get();

      final availableHandymanIds = availabilitySnapshot.docs
          .map((doc) => HandymanAvailabilityModel.fromMap(doc.data()))
          .where((availability) =>
              availability.availabilityStartDateTime.isBefore(endOfDay) &&
              availability.availabilityEndDateTime.isAfter(startOfDay))
          .map((availability) => availability.handymanID)
          .toSet();

      // Get total count of all handymen
      final handymanSnapshot = await db.collection('Handyman').get();
      final totalHandymen = handymanSnapshot.docs.length;
      final availableCount = availableHandymanIds.length;
      final unavailableCount = totalHandymen - availableCount;

      return {
        'available': availableCount,
        'unavailable': unavailableCount,
      };
    } catch (e) {
      print('Error in getHandymanAvailability: $e');
      return {'available': 0, 'unavailable': 0};
    }
  }

  Future<Map<String, int>> getTopServices(
    DateTime startOfDay,
    DateTime endOfDay,
  ) async {
    try {
      // Get all service requests for today
      final requestsSnapshot = await db
          .collection('ServiceRequest')
          .where('scheduledDateTime', isGreaterThanOrEqualTo: startOfDay)
          .where('scheduledDateTime', isLessThanOrEqualTo: endOfDay)
          .get();

      final requests = requestsSnapshot.docs
          .map((doc) => ServiceRequestModel.fromMap(doc.data()))
          .toList();

      if (requests.isEmpty) {
        return {};
      }

      // Get unique service IDs
      final serviceIds = requests.map((r) => r.serviceID).toSet().toList();
      final serviceCounts = <String, int>{};

      // Fetch service names in batches (Firestore whereIn limit is 30)
      for (var i = 0; i < serviceIds.length; i += 30) {
        final sublist = serviceIds.sublist(
          i,
          i + 30 > serviceIds.length ? serviceIds.length : i + 30,
        );
        
        final servicesSnapshot = await db
            .collection('Service')
            .where(FieldPath.documentId, whereIn: sublist)
            .get();

        for (var doc in servicesSnapshot.docs) {
          final serviceData = doc.data();
          final serviceName = serviceData['serviceName'] as String? ?? 'Unknown';
          final serviceId = doc.id;
          final count = requests.where((r) => r.serviceID == serviceId).length;
          
          if (count > 0) {
            serviceCounts[serviceName] = count;
          }
        }
      }

      // Sort by count and get top 3
      final sortedServices = serviceCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final top3Services = sortedServices.take(3).toList();

      return Map.fromEntries(top3Services);
    } catch (e) {
      print('Error in getTopServices: $e');
      return {};
    }
  }
}