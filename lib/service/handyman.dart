import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/databaseModel.dart';
import '../service/firestore_service.dart';

class HandymanService {
  final FirebaseFirestore db = FirestoreService.instance.db;

  /// In your HandymanService class, update fetchHandymanNames:

Future<Map<String, String>> fetchHandymanNames(List<String> handymanIds) async {
  // FIXED: Filter out null and empty strings
  final validIds = handymanIds.where((id) => id.isNotEmpty).toList();
  
  if (validIds.isEmpty) {
    print('No valid handyman IDs to fetch names for');
    return {};
  }

  try {
    final Map<String, String> nameMap = {};

    // Fetch in batches of 10 (Firestore limit for whereIn)
    for (int i = 0; i < validIds.length; i += 10) {
      final batch = validIds.skip(i).take(10).toList();
      
      final handymanQuery = await db
          .collection('Handyman')
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      final empIds = handymanQuery.docs
          .map((doc) => doc.data()['empID']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .toList();

      if (empIds.isEmpty) continue;

      // Fetch employee details in batches
      for (int j = 0; j < empIds.length; j += 10) {
        final empBatch = empIds.skip(j).take(10).toList();
        
        final empQuery = await db
            .collection('Employee')
            .where('empID', whereIn: empBatch)
            .get();

        for (var empDoc in empQuery.docs) {
          final empData = empDoc.data();
          final userID = empData['userID']?.toString();
          
          if (userID == null || userID.isEmpty) continue;

          try {
            final userDoc = await db.collection('User').doc(userID).get();
            
            if (userDoc.exists) {
              final userName = userDoc.data()?['userName']?.toString() ?? 'Unknown';
              
              // Find the corresponding handyman ID
              final handymanDoc = handymanQuery.docs.firstWhere(
                (doc) => doc.data()['empID'] == empData['empID'],
                orElse: () => throw Exception('Handyman not found'),
              );
              
              nameMap[handymanDoc.id] = userName;
            }
          } catch (e) {
            print('Error fetching user name for userID $userID: $e');
            continue;
          }
        }
      }
    }

    // Add "Not Assigned" for handymen without names
    for (final id in validIds) {
      if (!nameMap.containsKey(id)) {
        nameMap[id] = 'Not Assigned';
      }
    }

    return nameMap;
  } catch (e) {
    print('Error fetching handyman names: $e');
    // Return empty map with "Not Assigned" for all IDs
    return {for (var id in validIds) id: 'Not Assigned'};
  }
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

  Future<void> updateHandymanLocation(String handymanID, GeoPoint location) async {
    try {
      await db.collection('Handyman').doc(handymanID).update({
        'currentLocation': location,
      });
    } catch (e) {
      print("Error updating handyman location: $e");
    }
  }
}
