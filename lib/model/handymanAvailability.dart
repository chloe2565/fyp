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

  factory HandymanAvailabilityModel.fromFirestore(Map<String, dynamic> data) {
    return HandymanAvailabilityModel(
      availabilityID: data['availabilityID'],
      availabilityStartDateTime: (data['availabilityStartDateTime'] as Timestamp).toDate(),
      availabilityEndDateTime: (data['availabilityEndDateTime'] as Timestamp).toDate(),
      availabilityCreatedAt: (data['availabilityCreatedAt'] as Timestamp).toDate(),
      handymanID: data['handymanID'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'availabilityID': availabilityID,
      'availabilityStartDateTime': Timestamp.fromDate(availabilityStartDateTime),
      'availabilityEndDateTime': Timestamp.fromDate(availabilityEndDateTime),
      'availabilityCreatedAt': Timestamp.fromDate(availabilityCreatedAt),
      'handymanID': handymanID,
    };
  }
}