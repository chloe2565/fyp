import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../service/firestore_service.dart';
import '../service/user.dart';
import '../service/serviceRequest.dart';
import '../../model/database_model.dart';
import '../../model/serviceRequestViewModel.dart';
import '../../shared/helper.dart';

class ServiceRequestController extends ChangeNotifier {
  final ServiceRequestService serviceRequest = ServiceRequestService();
  final UserService user = UserService();
  final db = FirestoreService.instance.db;

  String? currentCustomerID;

  late Future<List<RequestViewModel>> upcomingRequestsFuture;
  late Future<List<RequestViewModel>> historyRequestsFuture;

  ServiceRequestController() {
    loadRequests();
  }

  void loadRequests() async {
    upcomingRequestsFuture = Future.value([]);
    historyRequestsFuture = Future.value([]);
    notifyListeners();

    currentCustomerID = await user.getCurrentCustomerID();

    if (currentCustomerID == null) {
      print("Error: Could not find customer ID for logged in user.");
      upcomingRequestsFuture = Future.error("Not logged in");
      historyRequestsFuture = Future.error("Not logged in");
      notifyListeners();
      return;
    }

    final rawUpcomingData = serviceRequest.getUpcomingRequests(
      currentCustomerID!,
    );
    final rawHistoryData = serviceRequest.getHistoryRequests(
      currentCustomerID!,
    );

    upcomingRequestsFuture = rawUpcomingData.then(
      (list) => transformData(list),
    );
    historyRequestsFuture = rawHistoryData.then((list) => transformData(list));

    notifyListeners();
  }

  List<RequestViewModel> transformData(List<Map<String, dynamic>> rawList) {
    return rawList.map((map) {
      final req = map['request'] as ServiceRequestModel;
      final service = map['service'] as ServiceModel;
      final handymanName = map['handymanName'] as String;
      final bookingDate = DateFormat(
        'MMMM dd, yyyy',
      ).format(req.scheduledDateTime);
      final startTime = DateFormat('hh:mm a').format(req.scheduledDateTime);

      return RequestViewModel(
        reqID: req.reqID,
        title: service.serviceName,
        icon: ServiceHelper.getIconForService(service.serviceName),
        reqStatus: capitalizeFirst(req.reqStatus),
        details: [
          MapEntry(
            'Location',
            '${capitalizeFirst(req.reqAddress)}, ${capitalizeFirst(req.reqState)}',
          ),
          MapEntry('Booking date', bookingDate),
          MapEntry('Start time', startTime),
          MapEntry('Handyman name', capitalizeFirst(handymanName)),
        ],
      );
    }).toList();
  }

Future<bool> addNewRequest({
    required String location,
    required DateTime scheduledDateTime,
    required String description,
    required String serviceID,
    required List<String> reqPicFileName,
    String? remark,
  }) async {
    if (currentCustomerID == null) {
      print("Error: User not logged in. Cannot submit request.");
      return false;
    }

    try {
      final newReqID = db.collection('ServiceRequest').doc().id;
      final String address = location;
      final String state = parseStateFromAddress(location);
      final String hardcodedHandymanID = "H0001";

      final ServiceRequestModel newRequest = ServiceRequestModel(
        reqID: newReqID,
        reqDateTime: DateTime.now(),
        scheduledDateTime: scheduledDateTime,
        reqAddress: address,
        reqState: state,
        reqDesc: description,
        reqPicName: reqPicFileName,
        reqStatus: 'pending',
        reqRemark: remark,
        custID: currentCustomerID!,
        serviceID: serviceID,
        handymanID: hardcodedHandymanID,
      );

      await serviceRequest.addServiceRequest(newRequest);
      loadRequests();

      return true;
    } catch (e) {
      print("Error in controller while adding request: $e");
      return false;
    }
  }

  Future<void> cancelRequest(String reqID) async {
    try {
      await serviceRequest.cancelRequest(reqID);
      loadRequests();
    } catch (e) {
      print('Error cancelling request: $e');
    }
  }

  Future<void> rescheduleRequest(String reqID) async {
    await serviceRequest.rescheduleRequest(reqID);
  }
}
