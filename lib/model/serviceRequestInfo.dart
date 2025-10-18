import 'serviceRequest.dart';
import 'service.dart';
import 'handyman.dart';
// import 'employee.dart';

class ServiceRequestInfo {
  final ServiceRequestModel request;
  final ServiceModel service;
  final HandymanModel handyman;
  // final Employee handymanUser; 

  ServiceRequestInfo({
    required this.request,
    required this.service,
    required this.handyman,
    // required this.handymanUser,
  });
}