import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/service.dart';

class ServiceService {
  final CollectionReference _servicesCollection = FirebaseFirestore.instance.collection('Service');

  Future<List<ServiceModel>> getAllServices() async {
    try {
      QuerySnapshot querySnapshot = await _servicesCollection
          .where('serviceStatus', isEqualTo: 'active')
          .get();

      print('Firestore: Retrieved ${querySnapshot.docs.length} services');

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('Firestore: Processing document ${data['serviceID']}');
        return ServiceModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('Firestore Error: $e');
      rethrow;
    }
  }
}
