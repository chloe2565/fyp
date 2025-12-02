import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/databaseModel.dart';
import '../model/rateReviewHistoryDetailViewModel.dart';
import '../shared/helper.dart';
import 'employee.dart';
import 'image_service.dart';
import 'reviewReply.dart';
import 'user.dart';
import 'serviceRequest.dart';

class RatingReviewService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final CollectionReference ratingReviewCollection = FirebaseFirestore.instance
      .collection('RatingReview');
  final UserService userService = UserService();
  final ServiceRequestService serviceRequestService = ServiceRequestService();
  final EmployeeService employeeService = EmployeeService();
  final ReviewReplyService replyService = ReviewReplyService();
  final FirebaseImageService imageService = FirebaseImageService();

  // Customer side
  Future<Map<String, List<Map<String, dynamic>>>>
  getRatingReviewPageData() async {
    final String? custID = await userService.getCurrentCustomerID();
    if (custID == null) throw Exception("User not logged in.");

    List<Map<String, dynamic>> pendingList = [];
    List<Map<String, dynamic>> historyList = [];

    try {
      final requests = await serviceRequestService
          .getCompletedRequestsForCustomer(custID);
      if (requests.isEmpty) {
        return {'pending': [], 'history': []};
      }
      final reqIDs = requests.map((r) => r.reqID).toList();
      final serviceIDs = requests.map((r) => r.serviceID).toSet().toList();
      final handymanIDs = requests
          .map((r) => r.handymanID)
          .whereType<String>()
          .where((id) => id.trim().isNotEmpty)
          .toSet()
          .toList();
      final reviewData = getReviewsForServiceRequests(reqIDs);
      final serviceData = batchFetch<ServiceModel>(
        ids: serviceIDs,
        collection: 'Service',
        fromMap: (data) => ServiceModel.fromMap(data),
      );
      final handymanData = fetchHandymanUserModels(handymanIDs);
      final results = await Future.wait([
        reviewData,
        serviceData,
        handymanData,
      ]);

      final reviewMap = {
        for (var r in results[0] as List<RatingReviewModel>) r.reqID: r,
      };
      final serviceMap = results[1] as Map<String, ServiceModel>;
      final handymanUserMap = results[2] as Map<String, UserModel>;

      for (final req in requests) {
        final review = reviewMap[req.reqID];
        final service = serviceMap[req.serviceID];
        final user = handymanUserMap[req.handymanID];

        final itemData = {
          'request': req,
          'service': service,
          'handymanUser': user,
          'review': review,
        };

        if (review == null) {
          pendingList.add(itemData);
        } else {
          historyList.add(itemData);
        }
      }

      pendingList.sort(
        (a, b) => (b['request'] as ServiceRequestModel).scheduledDateTime
            .compareTo((a['request'] as ServiceRequestModel).scheduledDateTime),
      );
      historyList.sort(
        (a, b) => (b['request'] as ServiceRequestModel).scheduledDateTime
            .compareTo((a['request'] as ServiceRequestModel).scheduledDateTime),
      );

      return {'pending': pendingList, 'history': historyList};
    } catch (e) {
      print("Error in getRatingReviewPageData: $e");
      rethrow;
    }
  }

  Future<Map<String, UserModel>> fetchHandymanUserModels(
    List<String> handymanIDs,
  ) async {
    if (handymanIDs.isEmpty) return {};

    try {
      // Get Handymen
      final handymanMap = await batchFetch<HandymanModel>(
        ids: handymanIDs,
        collection: 'Handyman',
        fromMap: (data) => HandymanModel.fromMap(data),
      );

      // Get Employees
      final empIDs = handymanMap.values
          .map((h) => h.empID)
          .whereType<String>()
          .where((id) => id.trim().isNotEmpty)
          .toSet()
          .toList();
      final employeeMap = await batchFetch<EmployeeModel>(
        ids: empIDs,
        collection: 'Employee',
        fromMap: (data) => EmployeeModel.fromMap(data),
      );

      // Get Users
      final userIDs = employeeMap.values
          .map((e) => e.userID)
          .whereType<String>()
          .where((id) => id.trim().isNotEmpty)
          .toSet()
          .toList();
      final userMap = await batchFetch<UserModel>(
        ids: userIDs,
        collection: 'User',
        fromMap: (data) => UserModel.fromMap(data),
      );

      // Map handymanID to final UserModel
      final Map<String, UserModel> result = {};
      for (final handymanID in handymanIDs) {
        final handyman = handymanMap[handymanID];
        final employee = employeeMap[handyman?.empID];
        final user = userMap[employee?.userID];
        if (user != null) {
          result[handymanID] = user;
        }
      }
      return result;
    } catch (e) {
      print("Error in fetchHandymanUserModels: $e");
      rethrow;
    }
  }

  // NEW METHOD: Fetch customer user model by custID
  Future<UserModel?> fetchCustomerUserModel(String custID) async {
    try {
      // Get Customer document
      final customerDoc = await db.collection('Customer').doc(custID).get();
      if (!customerDoc.exists) {
        print('Customer document not found for custID: $custID');
        return null;
      }

      final customerData = customerDoc.data() as Map<String, dynamic>;
      final customer = CustomerModel.fromMap(customerData);

      // Get User document using userID from customer
      final userDoc = await db.collection('User').doc(customer.userID).get();
      if (!userDoc.exists) {
        print('User document not found for userID: ${customer.userID}');
        return null;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      return UserModel.fromMap(userData);
    } catch (e) {
      print('Error in fetchCustomerUserModel: $e');
      return null;
    }
  }

  // NEW METHOD: Batch fetch customer user models
  Future<Map<String, UserModel>> fetchCustomerUserModels(
    List<String> custIDs,
  ) async {
    if (custIDs.isEmpty) return {};

    try {
      // Get Customers
      final customerMap = await batchFetch<CustomerModel>(
        ids: custIDs,
        collection: 'Customer',
        fromMap: (data) => CustomerModel.fromMap(data),
      );

      // Get Users
      final userIDs = customerMap.values
          .map((c) => c.userID)
          .whereType<String>()
          .where((id) => id.trim().isNotEmpty)
          .toSet()
          .toList();
      final userMap = await batchFetch<UserModel>(
        ids: userIDs,
        collection: 'User',
        fromMap: (data) => UserModel.fromMap(data),
      );

      // Map custID to final UserModel
      final Map<String, UserModel> result = {};
      for (final custID in custIDs) {
        final customer = customerMap[custID];
        final user = userMap[customer?.userID];
        if (user != null) {
          result[custID] = user;
        }
      }
      return result;
    } catch (e) {
      print("Error in fetchCustomerUserModels: $e");
      rethrow;
    }
  }

  Future<Map<String, T>> batchFetch<T>({
    required List<String> ids,
    required String collection,
    required T Function(Map<String, dynamic>) fromMap,
  }) async {
    final idSet = ids.where((id) => id.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) return {};

    final Map<String, T> resultMap = {};

    for (var i = 0; i < idSet.length; i += 30) {
      final sublist = idSet.sublist(
        i,
        i + 30 > idSet.length ? idSet.length : i + 30,
      );

      final querySnap = await db
          .collection(collection)
          .where(FieldPath.documentId, whereIn: sublist)
          .get();

      for (var doc in querySnap.docs) {
        resultMap[doc.id] = fromMap(doc.data());
      }
    }
    return resultMap;
  }

  Future<List<RatingReviewModel>> getReviewsForServiceRequests(
    List<String> reqIDs,
  ) async {
    if (reqIDs.isEmpty) {
      return [];
    }

    try {
      List<RatingReviewModel> allReviews = [];
      for (var i = 0; i < reqIDs.length; i += 30) {
        final sublist = reqIDs.sublist(
          i,
          i + 30 > reqIDs.length ? reqIDs.length : i + 30,
        );

        final querySnapshot = await ratingReviewCollection
            .where('reqID', whereIn: sublist)
            .get();

        final reviews = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return RatingReviewModel.fromMap(data);
        }).toList();
        allReviews.addAll(reviews);
      }
      return allReviews;
    } catch (e) {
      print('Error in getReviewsForServiceRequests: $e');
      return [];
    }
  }

  Future<RatingReviewDetailViewModel> getReviewDetails(String reqID) async {
    try {
      final reqFuture = db.collection('ServiceRequest').doc(reqID).get();
      final reviewFuture = ratingReviewCollection
          .where('reqID', isEqualTo: reqID)
          .limit(1)
          .get();

      final results = await Future.wait([reqFuture, reviewFuture]);

      final reqDoc = results[0] as DocumentSnapshot;
      if (!reqDoc.exists) throw Exception('Service Request not found');
      final request = ServiceRequestModel.fromMap(
        reqDoc.data() as Map<String, dynamic>,
      );

      final reviewQuery = results[1] as QuerySnapshot;
      if (reviewQuery.docs.isEmpty) throw Exception('Review not found');
      final review = RatingReviewModel.fromMap(
        reviewQuery.docs.first.data() as Map<String, dynamic>,
      );

      final replyFuture = replyService.getReplyForReview(review.rateID);

      final serviceFuture = db
          .collection('Service')
          .doc(request.serviceID)
          .get();
      final handymanUserFuture = fetchHandymanUserModels(
        request.handymanID != null && request.handymanID!.trim().isNotEmpty
            ? [request.handymanID!]
            : [],
      );

      final results2 = await Future.wait([
        serviceFuture,
        handymanUserFuture,
        replyFuture,
      ]);

      final serviceDoc = results2[0] as DocumentSnapshot;
      final service = serviceDoc.exists
          ? ServiceModel.fromMap(serviceDoc.data() as Map<String, dynamic>)
          : null;

      final handymanUserMap = results2[1] as Map<String, UserModel>;
      final handymanUser = handymanUserMap[request.handymanID];

      final reply = results2[2] as ReviewReplyModel?;

      final serviceName = service?.serviceName ?? 'Unknown Service';
      return RatingReviewDetailViewModel(
        reqID: reqID,
        serviceName: serviceName,
        serviceDate: request.scheduledDateTime,
        serviceIcon: ServiceHelper.getIconForService(serviceName),
        serviceIconBg: ServiceHelper.getColorForService(serviceName),
        handymanName: handymanUser?.userName ?? 'Unknown Handyman',
        ratingNum: review.ratingNum,
        photos: review.ratingPicName ?? [],
        reviewText: review.ratingText,
        reviewCreatedAt: review.ratingCreatedAt,
        updatedAt: review.updatedAt,
        reply: reply,
      );
    } catch (e) {
      print('Error in getReviewDetails: $e');
      rethrow;
    }
  }

  Future<String> generateNextID() async {
    const String prefix = 'RA';
    const int padding = 4;
    final query = await ratingReviewCollection
        .orderBy('rateID', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return '$prefix${'1'.padLeft(padding, '0')}';
    }
    final lastID = query.docs.first.id;
    final numericPart = int.tryParse(lastID.substring(prefix.length)) ?? 0;
    final nextNumber = numericPart + 1;
    return '$prefix${nextNumber.toString().padLeft(padding, '0')}';
  }

  Future<Map<String, dynamic>> getRateFormHeaderData(String reqID) async {
    try {
      final reqDoc = await db.collection('ServiceRequest').doc(reqID).get();
      if (!reqDoc.exists) throw Exception('ServiceRequest not found');
      final request = ServiceRequestModel.fromMap(
        reqDoc.data() as Map<String, dynamic>,
      );

      final serviceFuture = db
          .collection('Service')
          .doc(request.serviceID)
          .get();
      final handymanUserFuture = fetchHandymanUserModels(
        request.handymanID != null && request.handymanID!.trim().isNotEmpty
            ? [request.handymanID!]
            : [],
      );

      final results = await Future.wait([serviceFuture, handymanUserFuture]);

      final serviceDoc = results[0] as DocumentSnapshot;
      final service = serviceDoc.exists
          ? ServiceModel.fromMap(serviceDoc.data() as Map<String, dynamic>)
          : null;

      final handymanUserMap = results[1] as Map<String, UserModel>;
      final handymanUser = handymanUserMap[request.handymanID];

      return {
        'request': request,
        'service': service,
        'handymanUser': handymanUser,
      };
    } catch (e) {
      print('Error getting form data: $e');
      rethrow;
    }
  }

  Future<void> addNewRateReview({
    required String reqID,
    required double rating,
    required String text,
    required List<File> newImages,
  }) async {
    List<String> photoUrls = [];

    if (newImages.isNotEmpty) {
      final uploadedUrls = await imageService.uploadMultipleImages(
        imageFiles: newImages,
        category: ImageCategory.reviews,
        uniqueId: reqID,
      );
      photoUrls = uploadedUrls.whereType<String>().toList();
    }

    final newRateID = await generateNextID();
    final newReview = RatingReviewModel(
      rateID: newRateID,
      ratingCreatedAt: DateTime.now(),
      ratingNum: rating,
      ratingText: text,
      ratingPicName: photoUrls,
      reqID: reqID,
      updatedAt: null,
    );

    await ratingReviewCollection.doc(newRateID).set(newReview.toMap());
  }

  Future<void> updateRateReview({
    required String rateID,
    required double rating,
    required String text,
    required List<String> existingPhotoUrls,
    required List<File> newImages,
    required List<String> deletedPhotoUrls,
  }) async {
    if (deletedPhotoUrls.isNotEmpty) {
      await imageService.deleteMultipleImages(deletedPhotoUrls);
    }

    // Upload new images to Firebase Storage
    List<String> newPhotoUrls = [];
    if (newImages.isNotEmpty) {
      final uploadedUrls = await imageService.uploadMultipleImages(
        imageFiles: newImages,
        category: ImageCategory.reviews,
        uniqueId: rateID,
      );

      newPhotoUrls = uploadedUrls.whereType<String>().toList();
    }

    final allPhotoUrls = [...existingPhotoUrls, ...newPhotoUrls];

    await ratingReviewCollection.doc(rateID).update({
      'ratingNum': rating,
      'ratingText': text,
      'ratingPicName': allPhotoUrls,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteRateReview(String reqID) async {
    final query = await ratingReviewCollection
        .where('reqID', isEqualTo: reqID)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception("Review not found for deletion.");
    }

    final docData = query.docs.first.data() as Map<String, dynamic>;
    final review = RatingReviewModel.fromMap(docData);

    // Delete all photos from Firebase Storage
    if (review.ratingPicName != null && review.ratingPicName!.isNotEmpty) {
      await imageService.deleteMultipleImages(review.ratingPicName!);
    }

    final docId = query.docs.first.id;
    await ratingReviewCollection.doc(docId).delete();
  }

  // Employee side
  Future<Map<String, dynamic>> getRatingReviewPageDataForEmployee() async {
    final empInfo = await userService.getCurrentEmployeeInfo();
    if (empInfo == null) throw Exception("Employee not logged in.");

    final String empID = empInfo['empID']!;
    final String empType = empInfo['empType']!;

    List<Map<String, dynamic>> allReviewsList = [];

    try {
      List<ServiceRequestModel> requests;

      if (empType == 'admin') {
        // Admin
        requests = await serviceRequestService.getAllRequests();
      } else {
        // Handyman
        final handyman = await employeeService.getHandymanByEmpID(empID);
        if (handyman == null) {
          throw Exception("Handyman profile not found.");
        }
        requests = await serviceRequestService.getRequestsForHandyman(
          handyman.handymanID,
        );
      }

      if (requests.isEmpty) {
        return {'allReviews': []};
      }

      final reqIDs = requests.map((r) => r.reqID).toSet().toList();
      final serviceIDs = requests.map((r) => r.serviceID).toSet().toList();
      final handymanIDs = requests
          .map((r) => r.handymanID)
          .whereType<String>()
          .where((id) => id.trim().isNotEmpty)
          .toSet()
          .toList();
      final custIDs = requests.map((r) => r.custID).toSet().toList();

      final reviewData = getAllReviewsAndFilter(reqIDs);
      final serviceData = fetchAllServicesAndFilter(serviceIDs);
      final handymanData = fetchHandymanUserModels(handymanIDs);
      final customerData = fetchCustomerUserModels(custIDs);

      final results = await Future.wait([
        reviewData,
        serviceData,
        handymanData,
        customerData,
      ]);

      final reviewMap = {
        for (var r in results[0] as List<RatingReviewModel>) r.reqID: r,
      };
      final serviceMap = results[1] as Map<String, ServiceModel>;
      final handymanUserMap = results[2] as Map<String, UserModel>;
      final customerUserMap = results[3] as Map<String, UserModel>;

      // Only include requests that have reviews
      for (final req in requests) {
        final review = reviewMap[req.reqID];
        if (review != null) {
          final service = serviceMap[req.serviceID];
          final handymanUser = handymanUserMap[req.handymanID];
          final customerUser = customerUserMap[req.custID];

          allReviewsList.add({
            'request': req,
            'service': service,
            'handymanUser': handymanUser,
            'customerUser': customerUser,
            'review': review,
          });
        }
      }

      // Sort by newest date
      allReviewsList.sort(
        (a, b) => (b['request'] as ServiceRequestModel).scheduledDateTime
            .compareTo((a['request'] as ServiceRequestModel).scheduledDateTime),
      );

      return {'allReviews': allReviewsList, 'empType': empType};
    } catch (e) {
      print("Error in getRatingReviewPageDataForEmployee: $e");
      rethrow;
    }
  }

  // Fetch all reviews and filter by reqID
  Future<List<RatingReviewModel>> getAllReviewsAndFilter(
    List<String> reqIDs,
  ) async {
    if (reqIDs.isEmpty) return [];

    try {
      final reqIDSet = reqIDs.toSet();
      final querySnapshot = await ratingReviewCollection.get();

      final reviews = querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return RatingReviewModel.fromMap(data);
          })
          .where((review) => reqIDSet.contains(review.reqID))
          .toList();

      return reviews;
    } catch (e) {
      print('Error in getAllReviewsAndFilter: $e');
      return [];
    }
  }

  // Fetch all services and filter by serviceID
  Future<Map<String, ServiceModel>> fetchAllServicesAndFilter(
    List<String> serviceIDs,
  ) async {
    if (serviceIDs.isEmpty) return {};

    try {
      final serviceIDSet = serviceIDs.toSet();
      final querySnapshot = await db.collection('Service').get();

      final Map<String, ServiceModel> resultMap = {};
      for (var doc in querySnapshot.docs) {
        if (serviceIDSet.contains(doc.id)) {
          resultMap[doc.id] = ServiceModel.fromMap(doc.data());
        }
      }
      return resultMap;
    } catch (e) {
      print("Error in fetchAllServicesAndFilter: $e");
      return {};
    }
  }
}
