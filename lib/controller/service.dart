// controller/service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/ratingReview.dart';
import '../service/service.dart';
import '../model/service.dart';
import '../model/servicePicture.dart';
import '../service/ratingReview.dart';
import '../service/servicePicture.dart';

class ReviewDisplayData {
  final RatingReviewModel review;
  final String authorName;
  final String avatarPath; // e.g., "profile_pic.png"

  ReviewDisplayData({
    required this.review,
    required this.authorName,
    required this.avatarPath,
  });
}

class ServiceController {
  final ServiceService _serviceService = ServiceService();
  final ServicePictureService _pictureService = ServicePictureService();
  final RatingReviewService _ratingReviewService = RatingReviewService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- State ---
  List<ServiceModel> _allServices = [];
  bool _servicesLoaded = false;

  // --- Data Loading ---
  /// Fetches services from the database and stores them in the controller.
  Future<void> loadServices({bool refresh = false}) async {
    // Only fetch if not already loaded, unless a refresh is forced
    if (_servicesLoaded && !refresh) return;

    try {
      _allServices = await _serviceService.getAllServices();
      _servicesLoaded = true;
    } catch (e) {
      print('ServiceController Error: $e');
      _allServices = []; // Ensure list is empty on error
      _servicesLoaded = false; // Allow retry
      rethrow; // Re-throw for the FutureBuilder to catch
    }
  }

  // --- Getters for UI ---
  /// Returns all services (e.g., for "View All" pages).
  List<ServiceModel> get allServices => _allServices;

  /// Returns the list of services for the top grid (first 8).
  List<ServiceModel> get servicesForGrid {
    return _allServices.take(8).toList();
  }

  /// Returns the list of "popular" services for the bottom list.
  List<ServiceModel> get popularServicesForList {
    // FIX: Explicitly type the empty list as <ServiceModel>[]
    final popular = _allServices.length > 8
        ? _allServices.sublist(8)
        : <ServiceModel>[];
        
    return popular.take(3).toList(); // Show max 3 popular
  }

  /// Checks if the "popular" list has any services.
  bool get hasPopularServices => popularServicesForList.isNotEmpty;

  /// Logic to determine if the 'More' icon should show in the grid.
  bool get showMoreIconInGrid {
    // Original logic: Show 'More' if 7 or more services exist in the grid list
    return servicesForGrid.length >= 7;
  }

  // Get the count of service icons exclude More 
  int get serviceIconCountInGrid {
    return servicesForGrid.length < 7 ? servicesForGrid.length : 7;
  }

  // Get the total number of items to build in the grid
  int get gridItemCount {
    return serviceIconCountInGrid + (showMoreIconInGrid ? 1 : 0);
  }

  Future<List<ServiceModel>> getAllServices() async {
    if (!_servicesLoaded) {
      await loadServices();
    }
    return _allServices;
  }

  Future<List<ServicePictureModel>> getPicturesForService(
      String serviceID) async {
    return await _pictureService.getPicturesForService(serviceID);
  }

  Future<List<ReviewDisplayData>> getReviewsForService(String serviceID) async {
    try {
      // 1. Find all ServiceRequest documents for this serviceID
      // !! ASSUMING collection name is 'ServiceRequest' and field is 'serviceID'
      final requestSnap = await _firestore
          .collection('ServiceRequest')
          .where('serviceID', isEqualTo: serviceID)
          .get();

      if (requestSnap.docs.isEmpty) {
        return []; // No requests, so no reviews
      }

      // 2. Map reqIDs to userIDs
      // We need this map to link reviews back to users
      final Map<String, String> reqIdToUserIdMap = {};
      for (var doc in requestSnap.docs) {
        final data = doc.data();
        // !! ASSUMING field names are 'reqID' and 'userID'
        final reqID = data['reqID'] as String?;
        final userID = data['userID'] as String?;
        if (reqID != null && userID != null) {
          reqIdToUserIdMap[reqID] = userID;
        }
      }

      final List<String> reqIDs = reqIdToUserIdMap.keys.toList();
      if (reqIDs.isEmpty) {
        return []; // No valid requests
      }

      // 3. Get all RatingReview documents using the modified service
      final List<RatingReviewModel> reviews =
          await _ratingReviewService.getReviewsForServiceRequests(reqIDs);

      if (reviews.isEmpty) {
        return [];
      }

      // 4. Get unique user IDs from the reviews we found
      final Set<String> userIDs = reviews
          .map((review) => reqIdToUserIdMap[review.reqID])
          .where((userID) => userID != null)
          .cast<String>()
          .toSet();

      if (userIDs.isEmpty) {
        return []; // No users to fetch
      }

      // 5. Fetch user details from 'User' collection
      // !! ASSUMING collection name is 'User'
      final Map<String, Map<String, dynamic>> userDataMap = {};
      final userSnap = await _firestore
          .collection('User')
          .where(FieldPath.documentId, whereIn: userIDs.toList())
          .get();

      for (var doc in userSnap.docs) {
        userDataMap[doc.id] = doc.data();
      }

      // 6. Combine all data into the final display list
      final List<ReviewDisplayData> displayDataList = [];
      for (final review in reviews) {
        final userID = reqIdToUserIdMap[review.reqID];
        if (userID == null) continue; // Skip review if user link is broken

        final userData = userDataMap[userID];
        if (userData == null) continue; // Skip review if user data not found

        displayDataList.add(
          ReviewDisplayData(
            review: review,
            // !! ASSUMING field names 'userName' and 'profilePicture'
            authorName: userData['userName'] as String? ?? 'User',
            avatarPath: userData['profilePicture'] as String? ?? '',
          ),
        );
      }

      // Sort by date, newest first
      displayDataList.sort((a, b) =>
          b.review.ratingCreatedAt.compareTo(a.review.ratingCreatedAt));

      return displayDataList;
    } catch (e) {
      print('Error in getReviewsForService: $e');
      return []; // Return empty on error
    }
  }
}