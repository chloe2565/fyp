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

  factory FavoriteHandymanModel.fromFirestore(Map<String, dynamic> data) {
    return FavoriteHandymanModel(
      customerID: data['customerID'],
      handymanID: data['handymanID'],
      favoriteCreatedAt: (data['favoriteCreatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerID': customerID,
      'handymanID': handymanID,
      'favoriteCreatedAt': Timestamp.fromDate(favoriteCreatedAt),
    };
  }
}