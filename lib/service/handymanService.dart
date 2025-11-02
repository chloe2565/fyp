import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/databaseModel.dart';
import '../service/firestore_service.dart';

class HandymanServiceService {
  final FirebaseFirestore db = FirestoreService.instance.db;
  final CollectionReference handymanServiceCollection = FirestoreService
      .instance
      .db
      .collection('HandymanService');

  Future<void> addHandymanToService(
    String serviceID,
    List<String> handymanIDs,
  ) async {
    final WriteBatch batch = db.batch();
    for (final handymanID in handymanIDs) {
      final docRef = handymanServiceCollection.doc();
      final record = HandymanServiceModel(
        handymanID: handymanID,
        serviceID: serviceID,
        yearExperience: 0.0,
      );
      batch.set(docRef, record.toMap());
    }
    await batch.commit();
  }

  Future<void> removeHandymenFromService(String serviceID) async {
    final snapshot = await handymanServiceCollection
        .where('serviceID', isEqualTo: serviceID)
        .get();
    final WriteBatch batch = db.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<List<String>> getHandymanIDsByService(String serviceID) async {
    final snapshot = await handymanServiceCollection
        .where('serviceID', isEqualTo: serviceID)
        .get();
    return snapshot.docs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return (data?['handymanID'] as String?) ?? '';
        })
        .where((id) => id.isNotEmpty)
        .toList();
  }
}
