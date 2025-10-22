import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/servicePicture.dart';

class ServicePictureService {
  final CollectionReference _picturesCollection =
      FirebaseFirestore.instance.collection('ServicePicture');

  Future<List<ServicePictureModel>> getPicturesForService(String serviceID) async {
    QuerySnapshot query = await _picturesCollection
        .where('serviceID', isEqualTo: serviceID)
        .get();

    // Convert docs → model using fromMap()
    List<ServicePictureModel> pictures = query.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return ServicePictureModel.fromMap(data);
    }).toList();

    // Sort to have primary first
    pictures.sort((a, b) => (b.isPrimary ? 1 : 0) - (a.isPrimary ? 1 : 0));
    return pictures;
  }
}
