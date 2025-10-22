import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/service.dart';

class ServiceService {
  final CollectionReference _servicesCollection = FirebaseFirestore.instance.collection('Service');

  Future<List<ServiceModel>> getAllServices() async {
    QuerySnapshot querySnapshot = await _servicesCollection
        .where('serviceStatus', isEqualTo: 'active')
        .get();

    // Convert docs → model using fromMap()
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return ServiceModel.fromMap(data);
    }).toList();
  }
}
