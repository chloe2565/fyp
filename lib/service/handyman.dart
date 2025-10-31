import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/databaseModel.dart';
import '../service/firestore_service.dart';

class HandymanService {
  final FirebaseFirestore db = FirestoreService.instance.db;

  Future<Map<String, String>> fetchHandymanNames(
    List<String> handymanIds,
  ) async {
    if (handymanIds.isEmpty) return {};

    Map<String, String> handymanToEmployeeMap = {};
    for (var i = 0; i < handymanIds.length; i += 30) {
      final sublist = handymanIds.sublist(i, i + 30 > handymanIds.length ? handymanIds.length : i + 30);
      final handymanQuery = await db
        .collection('Handyman')
        .where(FieldPath.documentId, whereIn: sublist)
        .get();
      for (var doc in handymanQuery.docs) {
        handymanToEmployeeMap[doc.id] = doc.data()['empID'] as String? ?? '';
      }
    }

    final employeeIds = handymanToEmployeeMap.values.toSet().toList();
    if (employeeIds.isEmpty) return {};

    Map<String, String> employeeToUserMap = {};
    for (var i = 0; i < employeeIds.length; i += 30) {
        final sublist = employeeIds.sublist(i, i + 30 > employeeIds.length ? employeeIds.length : i + 30);
        final employeeQuery = await db
            .collection('Employee')
            .where(FieldPath.documentId, whereIn: sublist)
            .get();
        for (var doc in employeeQuery.docs) {
          employeeToUserMap[doc.id] = doc.data()['userID'] as String? ?? '';
        }
    }

    final userIds = employeeToUserMap.values.toSet().toList();
    if (userIds.isEmpty) return {};

    Map<String, String> userToNameMap = {};
    for (var i = 0; i < userIds.length; i += 30) {
        final sublist = userIds.sublist(i, i + 30 > userIds.length ? userIds.length : i + 30);
        final userQuery = await db
            .collection('User')
            .where(FieldPath.documentId, whereIn: sublist)
            .get();
        for (var doc in userQuery.docs) {
          userToNameMap[doc.id] = doc.data()['userName'] as String? ?? 'No Name';
        }
    }

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
