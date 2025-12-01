import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp/service/servicePicture.dart';
import 'package:flutter/foundation.dart';
import '../model/databaseModel.dart';
import '../../model/reviewDisplayViewModel.dart';
import '../service/ratingReview.dart';
import '../service/firestore_service.dart';
import 'handymanService.dart';

class ServiceAggregates {
  final double averageRating;
  final int completedOrders;
  ServiceAggregates({this.averageRating = 0.0, this.completedOrders = 0});
}

class HandymanDataBundle {
  final List<Map<String, dynamic>> handymanData;
  final List<String> handymanIDs;
  final List<Map<String, dynamic>> empData;
  final List<String> empIDs;
  final List<Map<String, dynamic>> userData;
  final List<String> userIDs;

  HandymanDataBundle({
    required this.handymanData,
    required this.handymanIDs,
    required this.empData,
    required this.empIDs,
    required this.userData,
    required this.userIDs,
  });
}

class ServicePopularity {
  final ServiceModel service;
  final int completedCount;

  ServicePopularity({required this.service, required this.completedCount});
}

Map<String, String> processHandymanMaps(HandymanDataBundle bundle) {
  final Map<String, String> handymanIdToEmpIdMap = {};
  for (int i = 0; i < bundle.handymanIDs.length; i++) {
    final empID = bundle.handymanData[i]['empID'] as String?;
    if (empID != null) {
      handymanIdToEmpIdMap[bundle.handymanIDs[i]] = empID;
    }
  }
  if (handymanIdToEmpIdMap.isEmpty) return {};

  final Map<String, String> empIdToUserIdMap = {};
  for (int i = 0; i < bundle.empIDs.length; i++) {
    final userID = bundle.empData[i]['userID'] as String?;
    if (userID != null) {
      empIdToUserIdMap[bundle.empIDs[i]] = userID;
    }
  }
  if (empIdToUserIdMap.isEmpty) return {};

  final Map<String, String> userIdToNameMap = {};
  for (int i = 0; i < bundle.userIDs.length; i++) {
    final userName = bundle.userData[i]['userName'] as String?;
    if (userName != null) {
      userIdToNameMap[bundle.userIDs[i]] = userName;
    }
  }

  final Map<String, String> finalHandymanMap = {};
  handymanIdToEmpIdMap.forEach((handymanID, empID) {
    final userID = empIdToUserIdMap[empID];
    if (userID != null) {
      final userName = userIdToNameMap[userID];
      if (userName != null) {
        finalHandymanMap[handymanID] = userName;
      }
    }
  });

  final sortedEntries = finalHandymanMap.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));

  return Map<String, String>.fromEntries(sortedEntries);
}

class ServiceService {
  final FirebaseFirestore db = FirestoreService.instance.db;
  late final CollectionReference servicesCollection;
  final RatingReviewService ratingReviewService;
  final ServicePictureService servicePictureService;
  final handymanServiceService = HandymanServiceService();

  ServiceService({
    required this.ratingReviewService,
    required this.servicePictureService,
  }) {
    servicesCollection = db.collection('Service');
  }

  Future<List<ServiceModel>> getTopServicesByCompletedRequests(
    int limit,
  ) async {
    try {
      // Get all active services
      final servicesSnap = await servicesCollection
          .where('serviceStatus', isEqualTo: 'active')
          .get();

      if (servicesSnap.docs.isEmpty) return [];

      final allServices = servicesSnap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ServiceModel.fromMap(data);
      }).toList();

      final serviceIds = allServices.map((s) => s.serviceID).toList();

      // Fetch all completed requests for these services
      final requestsSnap = await db
          .collection('ServiceRequest')
          .where('serviceID', whereIn: serviceIds)
          .where('reqStatus', isEqualTo: 'completed')
          .get();

      // Count completed requests per service
      final Map<String, int> completedCounts = {};
      for (var reqDoc in requestsSnap.docs) {
        final serviceID = reqDoc.data()['serviceID'] as String;
        completedCounts[serviceID] = (completedCounts[serviceID] ?? 0) + 1;
      }

      // Combine ServiceModel with count
      final List<ServicePopularity> rankedServices = allServices.map((service) {
        return ServicePopularity(
          service: service,
          completedCount: completedCounts[service.serviceID] ?? 0,
        );
      }).toList();

      // Sort by count (Descending)
      rankedServices.sort(
        (a, b) => b.completedCount.compareTo(a.completedCount),
      );

      // Return the top N models
      return rankedServices.take(limit).map((item) => item.service).toList();
    } catch (e) {
      print('Firestore Error in getTopServicesByCompletedRequests: $e');
      return [];
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

  Future<ServiceAggregates> getServiceAggregates(String serviceID) async {
    try {
      final requestSnap = await db
          .collection('ServiceRequest')
          .where('serviceID', isEqualTo: serviceID)
          .where('reqStatus', isEqualTo: 'completed')
          .get();

      int completedOrders = requestSnap.docs.length;

      if (completedOrders == 0) {
        return ServiceAggregates(averageRating: 0.0, completedOrders: 0);
      }

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

      final List<RatingReviewModel> reviews = await ratingReviewService
          .getReviewsForServiceRequests(reqIDs);

      if (reviews.isEmpty) {
        return ServiceAggregates(
          averageRating: 0.0,
          completedOrders: completedOrders,
        );
      }

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
      final requestSnap = await db
          .collection('ServiceRequest')
          .where('serviceID', isEqualTo: serviceID)
          .get();

      if (requestSnap.docs.isEmpty) {
        return [];
      }

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

      final List<RatingReviewModel> reviews = await ratingReviewService
          .getReviewsForServiceRequests(reqIDs);

      if (reviews.isEmpty) {
        return [];
      }

      final Set<String> custIDs = reviews
          .map((review) => reqIdToCustIdMap[review.reqID])
          .where((custIDs) => custIDs != null)
          .cast<String>()
          .toSet();

      if (custIDs.isEmpty) {
        return [];
      }

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

      final Map<String, Map<String, dynamic>> userDataMap = {};
      final userSnap = await db
          .collection('User')
          .where(FieldPath.documentId, whereIn: userIDs.toList())
          .get();

      for (var doc in userSnap.docs) {
        userDataMap[doc.id] = doc.data();
      }

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

  // Employee side
  Future<String> generateNextID() async {
    const String prefix = 'S';
    const int padding = 4;
    final query = await servicesCollection
        .orderBy('serviceID', descending: true)
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

  Future<List<ServiceModel>> empGetAllServices() async {
    try {
      QuerySnapshot querySnapshot = await servicesCollection
          .orderBy('serviceID', descending: false)
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

  Future<Map<String, String>> getAllHandymenMap() async {
    try {
      final handymanSnap = await db.collection('Handyman').get();
      if (handymanSnap.docs.isEmpty) return {};

      final List<Map<String, dynamic>> handymanData = [];
      final List<String> handymanIDs = [];
      final Set<String> empIdSet = {};

      for (var doc in handymanSnap.docs) {
        final data = doc.data();
        final empID = data['empID'] as String?;
        if (empID != null) {
          handymanData.add(data);
          handymanIDs.add(doc.id);
          empIdSet.add(empID);
        }
      }
      if (empIdSet.isEmpty) return {};

      final empSnap = await db
          .collection('Employee')
          .where('empStatus', isEqualTo: 'active')
          .where(FieldPath.documentId, whereIn: empIdSet.toList())
          .get();

      final List<Map<String, dynamic>> empData = [];
      final List<String> empIDs = [];
      final Set<String> userIdSet = {};

      for (var doc in empSnap.docs) {
        final data = doc.data();
        final userID = data['userID'] as String?;
        if (userID != null) {
          empData.add(data);
          empIDs.add(doc.id);
          userIdSet.add(userID);
        }
      }
      if (userIdSet.isEmpty) return {};

      final userSnap = await db
          .collection('User')
          .where(FieldPath.documentId, whereIn: userIdSet.toList())
          .get();

      final List<Map<String, dynamic>> userData = [];
      final List<String> userIDs = [];
      for (var doc in userSnap.docs) {
        userData.add(doc.data());
        userIDs.add(doc.id);
      }

      final bundle = HandymanDataBundle(
        handymanData: handymanData,
        handymanIDs: handymanIDs,
        empData: empData,
        empIDs: empIDs,
        userData: userData,
        userIDs: userIDs,
      );

      return await compute(processHandymanMaps, bundle);
    } catch (e) {
      print('Error in getAllHandymenMap: $e');
      rethrow;
    }
  }

  Future<void> addNewService(
    ServiceModel service,
    List<String> handymanIDs,
    List<String> imageUrls, // Changed from photoFileNames to imageUrls
  ) async {
    final WriteBatch batch = db.batch();
    final serviceRef = servicesCollection.doc(service.serviceID);
    batch.set(serviceRef, service.toMap());

    await handymanServiceService.addHandymanToService(
      service.serviceID,
      handymanIDs,
    );

    await batch.commit();

    // Store Firebase Storage URLs in ServicePicture collection
    if (imageUrls.isNotEmpty) {
      await Future.wait(
        imageUrls.asMap().entries.map((entry) {
          final index = entry.key;
          final url = entry.value;
          return servicePictureService.addNewPicture(
            service.serviceID,
            url, // This is now a Firebase Storage URL
            index == 0,
          );
        }),
      );
    }
  }

  Future<List<String>> getAssignedHandymanNames(String serviceID) async {
    try {
      final handymanServiceSnap = await db
          .collection('HandymanService')
          .where('serviceID', isEqualTo: serviceID)
          .get();

      if (handymanServiceSnap.docs.isEmpty) return [];

      final List<String> handymanIDs = handymanServiceSnap.docs
          .map((doc) => doc.data()['handymanID'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toList();

      if (handymanIDs.isEmpty) return [];

      final Set<String> empIDs = {};
      for (var i = 0; i < handymanIDs.length; i += 30) {
        final sublist = handymanIDs.sublist(
          i,
          i + 30 > handymanIDs.length ? handymanIDs.length : i + 30,
        );
        final handymanSnap = await db
            .collection('Handyman')
            .where(FieldPath.documentId, whereIn: sublist)
            .get();
        for (var doc in handymanSnap.docs) {
          final empID = doc.data()['empID'] as String?;
          if (empID != null) {
            empIDs.add(empID);
          }
        }
      }

      if (empIDs.isEmpty) return [];

      final Set<String> userIDs = {};
      for (var i = 0; i < empIDs.length; i += 30) {
        final sublist = empIDs.toList().sublist(
          i,
          i + 30 > empIDs.length ? empIDs.length : i + 30,
        );
        final empSnap = await db
            .collection('Employee')
            .where(FieldPath.documentId, whereIn: sublist)
            .get();
        for (var doc in empSnap.docs) {
          final userID = doc.data()['userID'] as String?;
          if (userID != null) {
            userIDs.add(userID);
          }
        }
      }

      if (userIDs.isEmpty) return [];

      final List<String> userNames = [];
      for (var i = 0; i < userIDs.length; i += 30) {
        final sublist = userIDs.toList().sublist(
          i,
          i + 30 > userIDs.length ? userIDs.length : i + 30,
        );
        final userSnap = await db
            .collection('User')
            .where(FieldPath.documentId, whereIn: sublist)
            .get();
        for (var doc in userSnap.docs) {
          final userName = doc.data()['userName'] as String?;
          if (userName != null) {
            userNames.add(userName);
          }
        }
      }

      return userNames;
    } catch (e) {
      print('Error in getAssignedHandymanNames: $e');
      return [];
    }
  }

  Future<Map<String, String>> getAssignedHandymenMap(String serviceID) async {
    try {
      final handymanServiceSnap = await db
          .collection('HandymanService')
          .where('serviceID', isEqualTo: serviceID)
          .get();

      if (handymanServiceSnap.docs.isEmpty) return {};

      final List<String> handymanIDs = handymanServiceSnap.docs
          .map((doc) => doc.data()['handymanID'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toList();

      if (handymanIDs.isEmpty) return {};

      final Map<String, String> handymanIdToEmpIdMap = {};
      for (var i = 0; i < handymanIDs.length; i += 30) {
        final sublist = handymanIDs.sublist(
          i,
          i + 30 > handymanIDs.length ? handymanIDs.length : i + 30,
        );
        final handymanSnap = await db
            .collection('Handyman')
            .where(FieldPath.documentId, whereIn: sublist)
            .get();
        for (var doc in handymanSnap.docs) {
          final empID = doc.data()['empID'] as String?;
          if (empID != null) {
            handymanIdToEmpIdMap[doc.id] = empID;
          }
        }
      }
      if (handymanIdToEmpIdMap.isEmpty) return {};

      final Map<String, String> empIdToUserIdMap = {};
      final empIds = handymanIdToEmpIdMap.values.toSet().toList();
      for (var i = 0; i < empIds.length; i += 30) {
        final sublist = empIds.sublist(
          i,
          i + 30 > empIds.length ? empIds.length : i + 30,
        );
        final empSnap = await db
            .collection('Employee')
            .where(FieldPath.documentId, whereIn: sublist)
            .get();
        for (var doc in empSnap.docs) {
          final userID = doc.data()['userID'] as String?;
          if (userID != null) {
            empIdToUserIdMap[doc.id] = userID;
          }
        }
      }
      if (empIdToUserIdMap.isEmpty) return {};

      final Map<String, String> userIdToNameMap = {};
      final userIds = empIdToUserIdMap.values.toSet().toList();
      for (var i = 0; i < userIds.length; i += 30) {
        final sublist = userIds.sublist(
          i,
          i + 30 > userIds.length ? userIds.length : i + 30,
        );
        final userSnap = await db
            .collection('User')
            .where(FieldPath.documentId, whereIn: sublist)
            .get();
        for (var doc in userSnap.docs) {
          final userName = doc.data()['userName'] as String?;
          if (userName != null) {
            userIdToNameMap[doc.id] = userName;
          }
        }
      }

      final Map<String, String> finalHandymanMap = {};
      handymanIdToEmpIdMap.forEach((handymanID, empID) {
        final userID = empIdToUserIdMap[empID];
        if (userID != null) {
          final userName = userIdToNameMap[userID];
          if (userName != null) {
            finalHandymanMap[handymanID] = userName;
          }
        }
      });

      return finalHandymanMap;
    } catch (e) {
      print('Error in getAssignedHandymenMap: $e');
      rethrow;
    }
  }

  Future<void> updateService(
    ServiceModel service,
    List<String> handymanIDs,
    List<String> newImageUrls, {
    List<String> removedPicUrls = const [],
  }) async {
    final WriteBatch batch = db.batch();

    final serviceRef = servicesCollection.doc(service.serviceID);
    batch.update(serviceRef, service.toMap());

    final oldHandymanLinks = await db
        .collection('HandymanService')
        .where('serviceID', isEqualTo: service.serviceID)
        .get();
    for (var doc in oldHandymanLinks.docs) {
      batch.delete(doc.reference);
    }

    for (var handymanID in handymanIDs) {
      final linkRef = db.collection('HandymanService').doc();
      batch.set(linkRef, {
        'handymanID': handymanID,
        'serviceID': service.serviceID,
        'yearExperience': 0.0,
      });
    }

    await batch.commit();

    // Delete removed images
    if (removedPicUrls.isNotEmpty) {
      await Future.wait(
        removedPicUrls.map((picUrl) async {
          final picQuery = await db
              .collection('ServicePicture')
              .where('serviceID', isEqualTo: service.serviceID)
              .where('picName', isEqualTo: picUrl)
              .get();
          for (var doc in picQuery.docs) {
            await doc.reference.delete();
          }
        }),
      );
    }

    // Add new images
    if (newImageUrls.isNotEmpty) {
      await Future.wait(
        newImageUrls.asMap().entries.map((entry) {
          final index = entry.key;
          final url = entry.value;
          return servicePictureService.addNewPicture(
            service.serviceID,
            url,
            index == 0,
          );
        }),
      );
    }
  }

  Future<void> deleteService(String serviceID) async {
    try {
      await servicesCollection.doc(serviceID).update({
        'serviceStatus': 'inactive',
      });
    } catch (e) {
      print('Error in deleteService: $e');
      rethrow;
    }
  }
}
