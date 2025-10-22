import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceRequestModel {
  final String reqID;
  final DateTime reqDateTime;
  final DateTime scheduledDateTime;
  final String reqAddress;
  final String reqState;
  final String reqDesc;
  final String reqStatus; // "pending", "confirmed", "completed", "cancelled"
  final String? reqRemark;
  final DateTime? reqCancelDateTime;
  final String? reqCustomCancel;
  final String custID;
  final String serviceID; 
  final String handymanID;
  final String? cancelID; 

  ServiceRequestModel({
    required this.reqID,
    required this.reqDateTime,
    required this.scheduledDateTime,
    required this.reqAddress,
    required this.reqState,
    required this.reqDesc,
    required this.reqStatus,
    this.reqRemark,
    this.reqCancelDateTime,
    this.reqCustomCancel,
    required this.custID,
    required this.serviceID,
    required this.handymanID,
    this.cancelID,
  });

  // Convert Firestore data to Dart
  factory ServiceRequestModel.fromMap(Map<String, dynamic> data) {
    return ServiceRequestModel(
      reqID: data['reqID'] ?? '',
      reqDateTime: (data['reqDateTime'] as Timestamp).toDate(),
      scheduledDateTime: (data['scheduledDateTime'] is Timestamp
          ? (data['scheduledDateTime'] as Timestamp).toDate() 
          : DateTime.now()),  
      reqAddress: data['reqAddress'] ?? '',
      reqState: data['reqState'] ?? '',
      reqDesc: data['reqDesc'],
      reqStatus: data['reqStatus'] ?? 'pending',
      reqRemark: data['reqRemark'],
      custID: data['custID'] ?? '',
      serviceID: data['serviceID'] ?? '',
      handymanID: data['handymanID'] ?? '',
      cancelID: data['cancelID'],
    );
  }

  // Convert Dart to Firestore data
  Map<String, dynamic> toMap() {
    return {
      'reqID': reqID,
      'reqDateTime': Timestamp.fromDate(reqDateTime),
      'scheduledDateTime': Timestamp.fromDate(scheduledDateTime),
      'reqAddress': reqAddress,
      'reqState': reqState,
      'reqDesc': reqDesc,
      'reqRemark': reqRemark,
      'custID': custID,
      'serviceID': serviceID,
      'handymanID': handymanID,
      'cancelID': cancelID,
    };
  }
}