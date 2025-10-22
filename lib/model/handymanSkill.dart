import 'package:cloud_firestore/cloud_firestore.dart';

class HandymanSkillModel {
  String skillID;
  String handymanID;
  DateTime skillAssignCreatedAt;

  HandymanSkillModel({
    required this.skillID,
    required this.handymanID,
    required this.skillAssignCreatedAt,
  });

  // Convert Firestore data to Dart
  factory HandymanSkillModel.fromMap(Map<String, dynamic> data) {
    return HandymanSkillModel(
      skillID: data['skillID'],
      handymanID: data['handymanID'],
      skillAssignCreatedAt: (data['skillAssignCreatedAt'] is Timestamp
          ? (data['skillAssignCreatedAt'] as Timestamp).toDate() 
          : DateTime.now()),
    );
  }

  // Convert Dart to Firestore data
  Map<String, dynamic> toMap() {
    return {
      'skillID': skillID,
      'handymanID': handymanID,
      'skillAssignCreatedAt': Timestamp.fromDate(skillAssignCreatedAt),
    };
  }
}