import 'package:cloud_firestore/cloud_firestore.dart';

class ServicePictureModel {
  final String picID;
  final String serviceID;
  final String picName; // This is the image URL or path
  final bool isPrimary;

  ServicePictureModel({
    required this.picID,
    required this.serviceID,
    required this.picName,
    required this.isPrimary,
  });

  factory ServicePictureModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ServicePictureModel(
      picID: data['picID'] ?? '',
      serviceID: data['serviceID'] ?? '',
      picName: data['picName'] ?? '',
      isPrimary: data['isPrimary'] ?? false,
    );
  }
}