import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/databaseModel.dart';
import '../service/firestore_service.dart';

class HandymanService {
  final FirebaseFirestore db = FirestoreService.instance.db;

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

  // Real time location for handyman
  Stream<HandymanModel> getHandymanStream(String handymanID) {
    return db.collection('Handyman').doc(handymanID).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        return HandymanModel.fromMap(snapshot.data()!);
      } else {
        throw Exception("Handyman not found");
      }
    });
  }
}
