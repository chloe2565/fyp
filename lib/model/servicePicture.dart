import 'package:cloud_firestore/cloud_firestore.dart';

class ServicePictureModel {
  final String picID;
  final String serviceID;
  final String picName;
  final bool isPrimary;

  ServicePictureModel({
    required this.picID,
    required this.serviceID,
    required this.picName,
    required this.isPrimary,
  });  
  
  // Convert Firestore data to Dart
  factory ServicePictureModel.fromMap(Map<String, dynamic> data) {
    return ServicePictureModel(
      picID: data['picID'] ?? '',
      serviceID: data['serviceID'] ?? '',
      picName: data['picName'] ?? '',
      isPrimary: data['isPrimary'] ?? '',
    );
  }

  // Convert Dart to Firestore data
  Map<String, dynamic> toMap() {
    return {
      'picID': picID,
      'serviceID': serviceID,
      'picName': picName,
      'isPrimary': isPrimary,
    };
  }

}