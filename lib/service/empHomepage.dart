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

      // Calculate start of this week (Monday)
      final weekday = now.weekday;
      final startOfWeek = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: weekday - 1));
      final endOfWeek = startOfWeek
          .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      // Get request status counts for this week
      final requestStatusCounts = await getRequestStatusCounts(
        startOfWeek,
        endOfWeek,
      );

      // Get handyman availability for today
      final handymanAvailability = await getHandymanAvailability(
        startOfDay,
        endOfDay,
      );

      // Get top 3 services for this week
      final topServices = await getTopServices(startOfWeek, endOfWeek);

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
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final requestsSnapshot = await db
          .collection('ServiceRequest')
          .where('scheduledDateTime', isGreaterThanOrEqualTo: startDate)
          .where('scheduledDateTime', isLessThanOrEqualTo: endDate)
          .get();

      final requests = requestsSnapshot.docs
          .map((doc) => ServiceRequestModel.fromMap(doc.data()))
          .toList();

      final statusCounts = <String, int>{
        'completed': 0,
        'confirmed': 0,
        'departed': 0,
        'pending': 0,
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
      // Get total count of all handymen first
      final handymanSnapshot = await db.collection('Handyman').get();
      final totalHandymen = handymanSnapshot.docs.length;

      if (totalHandymen == 0) {
        return {'available': 0, 'unavailable': 0};
      }

      // Get all handymen with availability records that overlap with today
      final availabilitySnapshot = await db
          .collection('HandymanAvailability')
          .get();

      final unavailableHandymanIds = <String>{};

      for (var doc in availabilitySnapshot.docs) {
        final availability = HandymanAvailabilityModel.fromMap(doc.data());
        
        // Check if the availability period overlaps with today
        final availStart = availability.availabilityStartDateTime;
        final availEnd = availability.availabilityEndDateTime;
        
        // Availability overlaps with today if:
        // - It starts before or during today AND
        // - It ends during or after today
        if (availStart.isBefore(endOfDay) || availStart.isAtSameMomentAs(endOfDay)) {
          if (availEnd.isAfter(startOfDay) || availEnd.isAtSameMomentAs(startOfDay)) {
            unavailableHandymanIds.add(availability.handymanID);
          }
        }
      }

      final unavailableCount = unavailableHandymanIds.length;
      final availableCount = totalHandymen - unavailableCount;

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
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Get all service requests for the date range
      final requestsSnapshot = await db
          .collection('ServiceRequest')
          .where('reqDateTime', isGreaterThanOrEqualTo: startDate)
          .where('reqDateTime', isLessThanOrEqualTo: endDate)
          .get();

      final requests = requestsSnapshot.docs
          .map((doc) => ServiceRequestModel.fromMap(doc.data()))
          .toList();

      if (requests.isEmpty) {
        return {};
      }

      // Get service IDs
      final serviceIds = requests.map((r) => r.serviceID).toSet().toList();
      final serviceCounts = <String, int>{};

      // Fetch service names
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