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

  factory HandymanSkillModel.fromFirestore(Map<String, dynamic> data) {
    return HandymanSkillModel(
      skillID: data['skillID'],
      handymanID: data['handymanID'],
      skillAssignCreatedAt: (data['skillAssignCreatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'skillID': skillID,
      'handymanID': handymanID,
      'skillAssignCreatedAt': Timestamp.fromDate(skillAssignCreatedAt),
    };
  }
}