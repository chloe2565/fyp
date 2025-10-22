import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String serviceID;
  final String serviceName;
  final String serviceDesc;
  final double? servicePrice;
  final String serviceDuration;
  final String serviceStatus;
  final DateTime serviceCreatedAt;

  ServiceModel({
    required this.serviceID,
    required this.serviceName,
    required this.serviceDesc,
    this.servicePrice,
    required this.serviceDuration,
    required this.serviceStatus,
    required this.serviceCreatedAt,
  });

  // Convert Firestore data to Dart
  factory ServiceModel.fromMap(Map<String, dynamic> data) {
    return ServiceModel(
      serviceID: data['serviceID'] ?? '',
      serviceName: data['serviceName'] ?? '',
      serviceDesc: data['serviceDesc'] ?? '',
      servicePrice: (data['servicePrice'] as num?)?.toDouble(),
      serviceDuration: data['serviceDuration'] ?? '',
      serviceStatus: data['serviceStatus'] ?? '',
      serviceCreatedAt: (data['serviceCreatedAt'] is Timestamp
          ? (data['serviceCreatedAt'] as Timestamp).toDate() 
          : DateTime.now()),
    );
  }

  // Convert Dart to Firestore data
  Map<String, dynamic> toMap() {
    return {
      'serviceID': serviceID,
      'serviceName': serviceName,
      'serviceDesc': serviceDesc,
      'servicePrice': servicePrice,
      'serviceDuration': serviceDuration,
      'serviceStatus': serviceStatus,
      'serviceCreatedAt': Timestamp.fromDate(serviceCreatedAt),
    };
  }

}