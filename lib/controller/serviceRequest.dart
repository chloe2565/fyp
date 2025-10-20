// repositories/service_request_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/serviceRequest.dart';
import '../model/service.dart';
import '../model/handyman.dart';
import '../model/user.dart';
import '../model/serviceRequestInfo.dart';

class ServiceRequestController {
  final _db = FirebaseFirestore.instance;

  // Fetches requests and combines them with service, handyman, and user data
  Future<List<ServiceRequestInfo>> fetchRequestsByStatus(
      List<String> statuses) async {
    // 1. Get all requests with the given statuses
    final requestQuery = await _db
        .collection('serviceRequests')
        .where('reqStatus', whereIn: statuses)
        .get();

    final serviceRequests = requestQuery.docs
        .map((doc) => ServiceRequestModel.fromFirestore(doc))
        .toList();

    // 2. Create a list of futures to fetch all related data in parallel
    List<Future<ServiceRequestInfo>> infoFutures = [];
    for (var request in serviceRequests) {
      infoFutures.add(_getCombinedInfo(request));
    }

    // 3. Wait for all data to be fetched and return the combined list
    return await Future.wait(infoFutures);
  }

  // Helper function to get all related data for a SINGLE request
  Future<ServiceRequestInfo> _getCombinedInfo(
      ServiceRequestModel request) async {
    // Use .get() for one-time reads. Use .snapshots() if you want real-time updates.
    
    // Get Service
    final serviceDoc =
        await _db.collection('Service').doc(request.serviceID).get();
    final service = ServiceModel.fromFirestore(serviceDoc);

    // Get Handyman
    final handymanDoc =
        await _db.collection('Handyman').doc(request.handymanID).get();
    final handyman = HandymanModel.fromFirestore(handymanDoc);

    // Get Handyman's User Info (for the name)
    // !! I AM ASSUMING you look up the name from a 'users' collection using the 'empID' !!
    final userDoc = await _db.collection('User').doc(handyman.empID).get();
    // final handymanUser = UserModel.fromFirestore(userDoc);

    return ServiceRequestInfo(
      request: request,
      service: service,
      handyman: handyman,
      // handymanUser: handymanUser,
    );
  }
}