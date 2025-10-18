import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String serviceID;
  final String serviceName;
  final String serviceDesc;
  final double servicePrice;
  final String serviceDuration;
  final String serviceStatus;
  final Timestamp serviceCreatedAt;

  ServiceModel({
    required this.serviceID,
    required this.serviceName,
    required this.serviceDesc,
    required this.servicePrice,
    required this.serviceDuration,
    required this.serviceStatus,
    required this.serviceCreatedAt,
  });

  // Factory constructor to create a ServiceModel from a Firestore document
  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ServiceModel(
      serviceID: data['serviceID'] ?? '',
      serviceName: data['serviceName'] ?? '',
      serviceDesc: data['serviceDesc'] ?? '',
      // Handle both int and double for price
      servicePrice: (data['servicePrice'] ?? 0).toDouble(),
      serviceDuration: data['serviceDuration'] ?? '',
      serviceStatus: data['serviceStatus'] ?? '',
      serviceCreatedAt: data['serviceCreatedAt'] ?? Timestamp.now(),
    );
  }
}