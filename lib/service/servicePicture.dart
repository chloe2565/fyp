import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/databaseModel.dart';

class ServicePictureService {
  final CollectionReference picturesCollection =
      FirebaseFirestore.instance.collection('ServicePicture');

  Future<List<ServicePictureModel>> getPicturesForService(String serviceID) async {
    QuerySnapshot query = await picturesCollection
        .where('serviceID', isEqualTo: serviceID)
        .get();

    List<ServicePictureModel> pictures = query.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return ServicePictureModel.fromMap(data);
    }).toList();

    pictures.sort((a, b) => (b.isPrimary ? 1 : 0) - (a.isPrimary ? 1 : 0));
    return pictures;
  }

  Future<String> generateNextID() async {
    const String prefix = 'SP';
    const int padding = 4;
    final query = await picturesCollection
        .orderBy('picID', descending: true)
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

  Future<void> addNewPicture(
      String serviceID, String picName, bool isPrimary) async {
    try {
      final String newPicID = await generateNextID();
      final docRef = picturesCollection.doc(newPicID);

      final newPic = ServicePictureModel(
        picID: newPicID, 
        serviceID: serviceID,
        picName: picName, 
        isPrimary: isPrimary,
      );

      await docRef.set(newPic.toMap());
    } catch (e) {
      print('Error in addNewPicture: $e');
      rethrow;
    }
  }
}
