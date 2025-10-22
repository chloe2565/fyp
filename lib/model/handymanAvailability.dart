import 'package:cloud_firestore/cloud_firestore.dart';

class HandymanAvailabilityModel {
  String availabilityID;
  DateTime availabilityStartDateTime;
  DateTime availabilityEndDateTime;
  DateTime availabilityCreatedAt;
  String handymanID;

  HandymanAvailabilityModel({
    required this.availabilityID,
    required this.availabilityStartDateTime,
    required this.availabilityEndDateTime,
    required this.availabilityCreatedAt,
    required this.handymanID,
  });

  // Convert Firestore data to Dart
  factory HandymanAvailabilityModel.fromMap(Map<String, dynamic> data) {
    return HandymanAvailabilityModel(
      availabilityID: data['availabilityID'],
      availabilityStartDateTime: (data['availabilityStartDateTime'] is Timestamp
          ? (data['availabilityStartDateTime'] as Timestamp).toDate() 
          : DateTime.now()),  
      availabilityEndDateTime: (data['availabilityEndDateTime'] is Timestamp
          ? (data['availabilityEndDateTime'] as Timestamp).toDate() 
          : DateTime.now()),  
      availabilityCreatedAt: (data['availabilityCreatedAt'] is Timestamp
          ? (data['availabilityCreatedAt'] as Timestamp).toDate() 
          : DateTime.now()),  
      handymanID: data['handymanID'],
    );
  }

  // Convert Dart to Firestore data
  Map<String, dynamic> toMap() {
    return {
      'availabilityID': availabilityID,
      'availabilityStartDateTime': Timestamp.fromDate(availabilityStartDateTime),
      'availabilityEndDateTime': Timestamp.fromDate(availabilityEndDateTime),
      'availabilityCreatedAt': Timestamp.fromDate(availabilityCreatedAt),
      'handymanID': handymanID,
    };
  }
}