import 'package:cloud_firestore/cloud_firestore.dart';

class HandymanModel {
  final String handymanID;
  final double handymanRating;
  final String handymanBio;
  final double? currentLocationLat;
  final double? currentLocationLon;
  final String empID;

  HandymanModel({
    required this.handymanID,
    required this.handymanRating,
    required this.handymanBio,
    this.currentLocationLat,
    this.currentLocationLon,
    required this.empID,
  });

  factory HandymanModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return HandymanModel(
      handymanID: doc.id,
      handymanRating: (data['handymanRating'] ?? 0).toDouble(),
      handymanBio: data['handymanBio'] ?? '',
      empID: data['empID'] ?? '', // Crucial link
      currentLocationLat: (data['currentLocationLat'] ?? 0.0).toDouble(),
      currentLocationLon: (data['currentLocationLon'] ?? 0.0).toDouble(),
    );
  }
}