import 'package:cloud_firestore/cloud_firestore.dart';

class RatingReviewModel {
  final String rateID;
  final DateTime ratingCreatedAt;
  final double ratingNum;
  final String ratingText;
  final List<String>? ratingPicName;
  final String reqID;

  RatingReviewModel({
    required this.rateID,
    required this.ratingCreatedAt,
    required this.ratingNum,
    required this.ratingText,
    this.ratingPicName,
    required this.reqID,
  });

  // Convert Firestore data to Dart
  factory RatingReviewModel.fromMap(Map<String, dynamic> data) {
    return RatingReviewModel(
      rateID: data['rateID'] ?? '',
      ratingCreatedAt: (data['ratingCreatedAt'] is Timestamp
          ? (data['ratingCreatedAt'] as Timestamp).toDate() 
          : DateTime.now()),  
      ratingNum: (data['ratingNum'] as num?)?.toDouble() ?? 0.0,
      ratingText: data['ratingText'] ?? '',
      ratingPicName: (data['ratingPicName'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      reqID: data['reqID'] ?? '',
    );
  }

  // Convert Dart to Firestore data
  Map<String, dynamic> toMap() {
    return {
      'rateID': rateID,
      'ratingCreatedAt': Timestamp.fromDate(ratingCreatedAt),
      'ratingNum': ratingNum,
      'ratingText': ratingText,
      'ratingPicName': ratingPicName,
      'reqID': reqID,
    };
  }
}