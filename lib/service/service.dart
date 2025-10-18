import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/service.dart';
import '../model/servicePicture.dart';

class ServiceService {
  final CollectionReference _servicesCollection = FirebaseFirestore.instance.collection('Service');

  Future<List<ServiceModel>> getAllServices() async {
    QuerySnapshot querySnapshot = await _servicesCollection
        .where('serviceStatus', isEqualTo: 'active')
        .get();
    return querySnapshot.docs
        .map((doc) => ServiceModel.fromFirestore(doc))
        .toList();
  }
}

class ServicePictureService {
  final CollectionReference _picturesCollection =
      FirebaseFirestore.instance.collection('ServicePicture');

  Future<List<ServicePictureModel>> getPicturesForService(
      String serviceID) async {
    QuerySnapshot query = await _picturesCollection
        .where('serviceID', isEqualTo: serviceID)
        .get();
    List<ServicePictureModel> pictures = query.docs
        .map((doc) => ServicePictureModel.fromFirestore(doc))
        .toList();

    // Sort to have primary first
    pictures.sort((a, b) => (b.isPrimary ? 1 : 0) - (a.isPrimary ? 1 : 0));
    return pictures;
  }
}