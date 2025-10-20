import 'package:cloud_firestore/cloud_firestore.dart';

class HandymanModel {
  String handymanID;
  String handymanName;
  double handymanRating;
  String handymanBio;
  double currentLocationLat;
  double currentLocationLon;
  String empID;

  HandymanModel({
    required this.handymanID,
    required this.handymanName,
    required this.handymanRating,
    required this.handymanBio,
    required this.currentLocationLat,
    required this.currentLocationLon,
    required this.empID,
  });

  factory HandymanModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return HandymanModel(
      handymanID: doc.id,
      handymanName: data['handymanName'] ?? '',
      handymanRating: (data['handymanRating'] ?? 0).toDouble(),
      handymanBio: data['handymanBio'] ?? '',
      empID: data['empID'] ?? '', 
      currentLocationLat: (data['currentLocationLat'] ?? 0.0).toDouble(),
      currentLocationLon: (data['currentLocationLon'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'handymanID': handymanID,
      'handymanName': handymanName,
      'handymanRating': handymanRating,
      'handymanBio': handymanBio,
      'currentLocationLat': currentLocationLat,
      'currentLocationLon': currentLocationLon,
      'employeeID': empID,
    };
  }
}