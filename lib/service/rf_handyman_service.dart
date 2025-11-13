import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

class HandymanMatchingService {
  final String apiBaseUrl;
  final db = FirestoreService.instance.db;

  HandymanMatchingService({required this.apiBaseUrl});

  // Check if the API is healthy
  Future<bool> checkAPIHealth() async {
    try {
      print('Checking API health at: $apiBaseUrl/health');

      final response = await http
          .get(Uri.parse('$apiBaseUrl/health'))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('Health check timed out after 10 seconds');
              throw TimeoutException('API health check timed out');
            },
          );

      if (response.statusCode == 200) {
        print('API health check successful');
        return true;
      } else {
        print('API health check failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  // Find the best matching handyman
  Future<Map<String, dynamic>?> findBestHandyman({
    required String serviceID,
    required DateTime scheduledDateTime,
    required Map<String, double> customerLocation,
    required double serviceDurationHours,
  }) async {
    try {
      print('Starting handyman search for service: $serviceID');

      // Fetch all handymen
      final handymenData = await fetchHandymenForService(serviceID);

      if (handymenData.isEmpty) {
        print('No handymen available for service: $serviceID');
        return null;
      }

      print('Found ${handymenData.length} handymen for service');

      // Fetch availability data
      final availabilityData = await fetchAvailability();
      print('Fetched ${availabilityData.length} availability records');

      // Fetch active requests
      final activeRequests = await fetchActiveRequests(scheduledDateTime);
      print('Fetched ${activeRequests.length} active requests');

      final requestBody = {
        'service_id': serviceID,
        'scheduled_datetime': scheduledDateTime.toIso8601String(),
        'customer_location': customerLocation,
        'service_duration_hours': serviceDurationHours,
        'handymen': handymenData,
        'availability': availabilityData,
        'active_requests': activeRequests,
      };

      print('Sending request to RF API...');

      // Call Random Forest
      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/match'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      print('RF API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          print('Match found: ${result['best_match']['handyman_name']}');
          return result['best_match'];
        } else {
          print('API returned success=false: ${result['message']}');
          return null;
        }
      } else {
        print('API request failed with status: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error in findBestHandyman: $e');
      return null;
    }
  }

  // Fetch handymen who offer the specific service
  Future<List<Map<String, dynamic>>> fetchHandymenForService(
    String serviceID,
  ) async {
    try {
      print('Searching HandymanService table for serviceID: $serviceID');

      final handymanServiceQuery = await db
          .collection('HandymanService')
          .where('serviceID', isEqualTo: serviceID)
          .get();

      print(
        'Found ${handymanServiceQuery.docs.length} HandymanService records',
      );

      if (handymanServiceQuery.docs.isEmpty) {
        print(
          'No handymen found offering service $serviceID in HandymanService table',
        );
        return [];
      }

      final Map<String, double> handymanExperience = {};
      final List<String> handymanIDs = [];

      for (var doc in handymanServiceQuery.docs) {
        final data = doc.data();
        final handymanID = data['handymanID']?.toString();
        final yearsExp = parseYearsExperience(
          data['yearExperience']?.toString() ?? '0',
        );

        if (handymanID != null) {
          handymanIDs.add(handymanID);
          handymanExperience[handymanID] = yearsExp;
          print('  - Handyman $handymanID: $yearsExp years experience');
        }
      }

      print('Processing ${handymanIDs.length} handymen');

      final List<Map<String, dynamic>> result = [];

      for (String handymanID in handymanIDs) {
        try {
          final handymanDoc = await db
              .collection('Handyman')
              .doc(handymanID)
              .get();

          if (!handymanDoc.exists) {
            print('Handyman document not found: $handymanID');
            continue;
          }

          final handymanData = handymanDoc.data()!;
          final empID = handymanData['empID']?.toString();

          if (empID == null) {
            print('No empID found for handyman: $handymanID');
            continue;
          }

          final employeeQuery = await db
              .collection('Employee')
              .where('empID', isEqualTo: empID)
              .limit(1)
              .get();

          if (employeeQuery.docs.isEmpty) {
            print('Employee not found for empID: $empID');
            continue;
          }

          final employeeData = employeeQuery.docs.first.data();
          final empStatus = employeeData['empStatus']?.toString();

          if (empStatus != 'active') {
            print('Skipping inactive employee: $empID (status: $empStatus)');
            continue;
          }

          final userID = employeeData['userID']?.toString();

          String userName = 'Unknown';
          if (userID != null) {
            final userDoc = await db.collection('User').doc(userID).get();
            if (userDoc.exists) {
              userName = userDoc.data()?['userName']?.toString() ?? 'Unknown';
            }
          }

          final allServicesQuery = await db
              .collection('HandymanService')
              .where('handymanID', isEqualTo: handymanID)
              .get();

          final serviceIDs = allServicesQuery.docs
              .map((doc) => doc.data()['serviceID']?.toString())
              .where((id) => id != null)
              .cast<String>()
              .toList();

          final servicesWithExperience = allServicesQuery.docs.map((doc) {
            final data = doc.data();
            return {
              'service_id': data['serviceID']?.toString() ?? '',
              'years_experience': parseYearsExperience(
                data['yearExperience']?.toString() ?? '0',
              ),
            };
          }).toList();

          final GeoPoint? location =
              handymanData['currentLocation'] as GeoPoint?;
          Map<String, double> locationMap = {'latitude': 0.0, 'longitude': 0.0};

          if (location != null) {
            locationMap = {
              'latitude': location.latitude,
              'longitude': location.longitude,
            };
          }

          final completionRate = await calculateCompletionRate(handymanID);
          final avgCompletionTime = await calculateAvgCompletionTime(
            handymanID,
          );

          final handymanRecord = {
            'handyman_id': handymanID,
            'name': userName,
            'rating': parseDouble(handymanData['handymanRating'] ?? 4.0),
            'service_ids': serviceIDs,
            'services': servicesWithExperience,
            'current_location': locationMap,
            'completion_rate': completionRate,
            'avg_completion_time_hours': avgCompletionTime,
          };

          result.add(handymanRecord);
          print('Added handyman: $userName ($handymanID)');
        } catch (e) {
          print('Error processing handyman $handymanID: $e');
          continue;
        }
      }

      print('Final result: ${result.length} qualified handymen');
      return result;
    } catch (e) {
      print('Error in _fetchHandymenForService: $e');
      return [];
    }
  }

  // Calculate handyman's completion rate
  Future<double> calculateCompletionRate(String handymanID) async {
    try {
      final allRequestsQuery = await db
          .collection('ServiceRequest')
          .where('handymanID', isEqualTo: handymanID)
          .where('reqStatus', whereIn: ['completed', 'cancelled'])
          .get();

      if (allRequestsQuery.docs.isEmpty) return 0.9;

      final completedCount = allRequestsQuery.docs
          .where((doc) => doc.data()['reqStatus'] == 'completed')
          .length;

      return completedCount / allRequestsQuery.docs.length;
    } catch (e) {
      print('Error calculating completion rate: $e');
      return 0.9;
    }
  }

  Future<double> calculateAvgCompletionTime(String handymanID) async {
    try {
      final completedQuery = await db
          .collection('ServiceRequest')
          .where('handymanID', isEqualTo: handymanID)
          .where('reqStatus', isEqualTo: 'completed')
          .limit(10)
          .get();

      if (completedQuery.docs.isEmpty) return 4.0;

      double totalHours = 0;
      int count = 0;

      for (var doc in completedQuery.docs) {
        final data = doc.data();
        final scheduledTimestamp = data['scheduledDateTime'] as Timestamp?;
        final completedTimestamp = data['reqCompleteTime'] as Timestamp?;

        if (scheduledTimestamp != null && completedTimestamp != null) {
          final scheduled = scheduledTimestamp.toDate();
          final completed = completedTimestamp.toDate();
          final duration = completed.difference(scheduled).inHours.toDouble();

          if (duration > 0 && duration < 24) {
            totalHours += duration;
            count++;
          }
        }
      }

      return count > 0 ? totalHours / count : 4.0;
    } catch (e) {
      print('Error calculating avg completion time: $e');
      return 4.0;
    }
  }

  double parseYearsExperience(String exp) {
    if (exp.isEmpty) return 0.0;

    final directNumber = double.tryParse(exp);
    if (directNumber != null) return directNumber;

    final cleaned = exp
        .toLowerCase()
        .replaceAll('years', '')
        .replaceAll('year', '')
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

    return 0.0;
  }

  double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Fetch availability periods
  Future<List<Map<String, dynamic>>> fetchAvailability() async {
    try {
      final now = DateTime.now();

      final snapshot = await db
          .collection('HandymanAvailability')
          .where(
            'availabilityEndDateTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(now),
          )
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'handyman_id': data['handymanID']?.toString() ?? '',
          'start':
              (data['availabilityStartDateTime'] as Timestamp?)
                  ?.toDate()
                  .toIso8601String() ??
              '',
          'end':
              (data['availabilityEndDateTime'] as Timestamp?)
                  ?.toDate()
                  .toIso8601String() ??
              '',
        };
      }).toList();
    } catch (e) {
      print('Error fetching availability (this is OK if table is empty): $e');
      return [];
    }
  }

  // Fetch active service requests
  Future<List<Map<String, dynamic>>> fetchActiveRequests(
    DateTime scheduledDateTime,
  ) async {
    try {
      final startDate = scheduledDateTime.subtract(const Duration(days: 1));
      final endDate = scheduledDateTime.add(const Duration(days: 1));

      // Status 'confirmed' or 'departed'
      final snapshot = await db
          .collection('ServiceRequest')
          .where(
            'scheduledDateTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where(
            'scheduledDateTime',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          )
          .get();

      // Filter for confirmed or departed status
      final activeRequests = snapshot.docs.where((doc) {
        final status = doc.data()['reqStatus']?.toString().toLowerCase();
        return status == 'confirmed' || status == 'departed';
      }).toList();

      final List<Map<String, dynamic>> result = [];

      for (var doc in activeRequests) {
        final data = doc.data();
        final serviceID = data['serviceID']?.toString();
        final handymanID = data['handymanID']?.toString();
        final scheduledTimestamp = data['scheduledDateTime'] as Timestamp?;

        if (handymanID == null ||
            handymanID.isEmpty ||
            scheduledTimestamp == null) {
          continue;
        }

        double serviceDuration = 3.0;

        if (serviceID != null && serviceID.isNotEmpty) {
          try {
            final serviceDoc = await db
                .collection('Service')
                .doc(serviceID)
                .get();
            if (serviceDoc.exists) {
              final serviceDurationStr =
                  serviceDoc.data()?['serviceDuration']?.toString() ??
                  '3 hours';
              serviceDuration = parseDurationHelper(serviceDurationStr);
            }
          } catch (e) {
            print('Error fetching service duration for $serviceID: $e');
          }
        }

        result.add({
          'handyman_id': handymanID,
          'scheduled_datetime': scheduledTimestamp.toDate().toIso8601String(),
          'service_duration': serviceDuration,
        });
      }

      print('Fetched ${result.length} active requests (confirmed/departed)');
      return result;
    } catch (e) {
      print('Error fetching active requests: $e');
      return [];
    }
  }

  double parseDurationHelper(String duration) {
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

    return 3.0;
  }
}
