import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteHandymanModel {
  String customerID;
  String handymanID;
  DateTime favoriteCreatedAt;

  FavoriteHandymanModel({
    required this.customerID,
    required this.handymanID,
    required this.favoriteCreatedAt,
  });

  // Convert Firestore data to Dart
  factory FavoriteHandymanModel.fromMap(Map<String, dynamic> data) {
    return FavoriteHandymanModel(
      customerID: data['customerID'] ?? '',
      handymanID: data['handymanID'] ?? '',
      favoriteCreatedAt: (data['favoriteCreatedAt'] is Timestamp
          ? (data['favoriteCreatedAt'] as Timestamp).toDate() 
          : DateTime.now()),  
    );
  }

  // Convert Dart to Firestore data
  Map<String, dynamic> toMap() {
    return {
      'customerID': customerID,
      'handymanID': handymanID,
      'favoriteCreatedAt': Timestamp.fromDate(favoriteCreatedAt),
    };
  }
}