import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/databaseModel.dart';
import '../../model/reviewDisplayViewModel.dart';
import '../service/ratingReview.dart';
import '../service/firestore_service.dart';

class ServiceAggregates {
  final double averageRating;
  final int completedOrders;
  ServiceAggregates({this.averageRating = 0.0, this.completedOrders = 0});
}

class ServiceService {
  final FirebaseFirestore db = FirestoreService.instance.db;
  late final CollectionReference servicesCollection;
  final RatingReviewService ratingReviewService;

  ServiceService({required this.ratingReviewService}) {
    servicesCollection = db.collection('Service');
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

  Future<ServiceAggregates> getServiceAggregates(String serviceID) async {
    try {
      // 1. Get completed service requests
      final requestSnap = await db
          .collection('ServiceRequest')
          .where('serviceID', isEqualTo: serviceID)
          .where('reqStatus', isEqualTo: 'completed')
          .get();

      int completedOrders = requestSnap.docs.length;

      if (completedOrders == 0) {
        return ServiceAggregates(averageRating: 0.0, completedOrders: 0);
      }

      // 2. Get reqIDs from those completed requests
      final List<String> reqIDs = requestSnap.docs
          .map((doc) => doc.data()['reqID'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toList();

      if (reqIDs.isEmpty) {
        return ServiceAggregates(
          averageRating: 0.0,
          completedOrders: completedOrders,
        );
      }

      // 3. Get reviews for reqID
      final List<RatingReviewModel> reviews = await ratingReviewService
          .getReviewsForServiceRequests(reqIDs);

      if (reviews.isEmpty) {
        return ServiceAggregates(
          averageRating: 0.0,
          completedOrders: completedOrders,
        );
      }

      // 4. Calculate average rating
      double sum = reviews.fold(0.0, (prev, e) => prev + e.ratingNum);
      double averageRating = sum / reviews.length;

      return ServiceAggregates(
        averageRating: averageRating,
        completedOrders: completedOrders,
      );
    } catch (e) {
      print('Error in getServiceAggregates: $e');
      return ServiceAggregates();
    }
  }

  Future<Map<String, String>> fetchServiceNames(List<String> serviceIds) async {
    if (serviceIds.isEmpty) return {};

    final Map<String, String> serviceNameMap = {};

    for (var i = 0; i < serviceIds.length; i += 30) {
      final sublist = serviceIds.sublist(
        i,
        i + 30 > serviceIds.length ? serviceIds.length : i + 30,
      );
      final querySnapshot = await db
          .collection('Service')
          .where(FieldPath.documentId, whereIn: sublist)
          .get();
      for (var doc in querySnapshot.docs) {
        serviceNameMap[doc.id] = doc.data()['serviceName'] as String? ?? 'N/A';
      }
    }
    return serviceNameMap;
  }

  Future<List<ReviewDisplayData>> getReviewsForService(String serviceID) async {
    try {
      // 1. Find all ServiceRequest documents
      final requestSnap = await db
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

      // 3. Get all RatingReview documents
      final List<RatingReviewModel> reviews = await ratingReviewService
          .getReviewsForServiceRequests(reqIDs);

      if (reviews.isEmpty) {
        return [];
      }

      // 4. Get unique user IDs
      final Set<String> custIDs = reviews
          .map((review) => reqIdToCustIdMap[review.reqID])
          .where((custIDs) => custIDs != null)
          .cast<String>()
          .toSet();

      if (custIDs.isEmpty) {
        return [];
      }

      // 5. Fetch Customer documents
      final Map<String, String> custIdToUserIdMap = {};
      final customerSnap = await db
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

      // 6. Fetch user details
      final Map<String, Map<String, dynamic>> userDataMap = {};
      final userSnap = await db
          .collection('User')
          .where(FieldPath.documentId, whereIn: userIDs.toList())
          .get();

      for (var doc in userSnap.docs) {
        userDataMap[doc.id] = doc.data();
      }

      // 7. Combine all data
      final List<ReviewDisplayData> displayDataList = [];
      for (final review in reviews) {
        final custID = reqIdToCustIdMap[review.reqID];
        if (custID == null) continue;

        final userID = custIdToUserIdMap[custID];
        if (userID == null) continue;

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
