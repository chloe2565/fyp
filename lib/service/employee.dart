import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/databaseModel.dart';

class EmployeeService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // Get Employee by userID
  Future<EmployeeModel?> getEmployeeByUserID(String userID) async {
    final snap = await db
        .collection('Employee')
        .where('userID', isEqualTo: userID)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return EmployeeModel.fromMap(snap.docs.first.data());
  }

  // Get Handyman profile
  Future<HandymanModel?> getHandymanByEmpID(String empID) async {
    final snap = await db
        .collection('Handyman')
        .where('empID', isEqualTo: empID)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return HandymanModel.fromMap(snap.docs.first.data());
  }

  // Get ServiceProvider profile
  Future<ServiceProviderModel?> getServiceProviderByEmpID(String empID) async {
    final snap = await db
        .collection('ServiceProvider')
        .where('empID', isEqualTo: empID)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return ServiceProviderModel.fromMap(snap.docs.first.data());
  }

  Future<List<String>> getAssignedServicesByHandymanID(
    String handymanID,
  ) async {
    final db = FirebaseFirestore.instance;

    try {
      final handymanServiceSnap = await db
          .collection('HandymanService')
          .where('handymanID', isEqualTo: handymanID)
          .get();

      if (handymanServiceSnap.docs.isEmpty) return [];

      final serviceIDs = handymanServiceSnap.docs
          .map((doc) => doc.data()['serviceID'] as String?)
          .whereType<String>()
          .toList();

      if (serviceIDs.isEmpty) return [];

      final serviceSnap = await db
          .collection('Service')
          .where(FieldPath.documentId, whereIn: serviceIDs)
          .get();

      final serviceNames = serviceSnap.docs
          .map((doc) => doc.data()['serviceName'] as String? ?? 'N/A')
          .toList();

      return serviceNames;
    } catch (e) {
      print('Error in getAssignedServicesByHandymanID: $e');
      return [];
    }
  }
}
