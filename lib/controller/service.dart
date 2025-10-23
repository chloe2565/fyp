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
  Future<void> loadServices({bool refresh = false}) async {
    if (_servicesLoaded && !refresh) return;

    try {
      _allServices = await _serviceService.getAllServices();
      _servicesLoaded = true;
    } catch (e) {
      print('ServiceController Error: $e');
      _allServices = [];
      _servicesLoaded = false;
      rethrow;
    }
  }

  List<ServiceModel> get allServices => _allServices;

  List<ServiceModel> get servicesForGrid {
    return _allServices.take(8).toList();
  }

  List<ServiceModel> get popularServicesForList {
    final popular = _allServices.length > 8
        ? _allServices.sublist(8)
        : <ServiceModel>[];

    return popular.take(3).toList();
  }

  bool get hasPopularServices => popularServicesForList.isNotEmpty;

  bool get showMoreIconInGrid {
    return servicesForGrid.length >= 7;
  }

  int get serviceIconCountInGrid {
    return servicesForGrid.length < 7 ? servicesForGrid.length : 7;
  }

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
    String serviceID,
  ) async {
    return await _pictureService.getPicturesForService(serviceID);
  }

  Future<List<ReviewDisplayData>> getReviewsForService(String serviceID) async {
    try {
      // 1. Find all ServiceRequest documents for this serviceID
      final requestSnap = await _firestore
          .collection('ServiceRequest')
          .where('serviceID', isEqualTo: serviceID)
          .get();

      if (requestSnap.docs.isEmpty) {
        return [];
      }

      // 2. Map reqIDs to userIDs
      final Map<String, String> reqIdToCustIdMap = {};
      for (var doc in requestSnap.docs) {
        final data = doc.data();
        final reqID = data['reqID'] as String?;
        final custID = data['custID'] as String?;
        if (reqID != null && custID != null) {
          reqIdToCustIdMap[reqID] = custID;
        }
      }

      final List<String> reqIDs = reqIdToCustIdMap.keys.toList();
      if (reqIDs.isEmpty) {
        return [];
      }

      // 3. Get all RatingReview documents using the modified service
      final List<RatingReviewModel> reviews = await _ratingReviewService
          .getReviewsForServiceRequests(reqIDs);

      if (reviews.isEmpty) {
        return [];
      }

      // 4. Get unique user IDs from the reviews we found
      final Set<String> custIDs = reviews
          .map((review) => reqIdToCustIdMap[review.reqID])
          .where((custIDs) => custIDs != null)
          .cast<String>()
          .toSet();

      if (custIDs.isEmpty) {
        return [];
      }

      // 5. Fetch Customer documents to get userIDs
      final Map<String, String> custIdToUserIdMap = {};
      final customerSnap = await _firestore
          .collection('Customer')
          .where(FieldPath.documentId, whereIn: custIDs.toList())
          .get();

      for (var doc in customerSnap.docs) {
        final data = doc.data();
        final userID = data['userID'] as String?; 
        if (userID != null) {
          custIdToUserIdMap[doc.id] = userID;
        }
      }

      final Set<String> userIDs = custIdToUserIdMap.values.toSet();
      if (userIDs.isEmpty) {
        return [];
      }

      // 6. Fetch user details from User table
      final Map<String, Map<String, dynamic>> userDataMap = {};
      final userSnap = await _firestore
          .collection('User')
          .where(FieldPath.documentId, whereIn: userIDs.toList())
          .get();

      for (var doc in userSnap.docs) {
        userDataMap[doc.id] = doc.data(); 
      }

      // 7. Combine all data into the final display list
      final List<ReviewDisplayData> displayDataList = [];
      for (final review in reviews) {
        // Get custID from review
        final custID = reqIdToCustIdMap[review.reqID];
        if (custID == null) continue;

        // Get userID from custID
        final userID = custIdToUserIdMap[custID];
        if (userID == null) continue;

        // Get user data from userID
        final userData = userDataMap[userID];
        if (userData == null) continue;

        displayDataList.add(
          ReviewDisplayData(
            review: review,
            authorName: userData['userName'] as String? ?? 'User',
            avatarPath: userData['userPicName'] as String? ?? '',
          ),
        );
      }

      displayDataList.sort(
        (a, b) => b.review.ratingCreatedAt.compareTo(a.review.ratingCreatedAt),
      );

      return displayDataList;
    } catch (e) {
      print('Error in getReviewsForService: $e');
      return [];
    }
  }
}
