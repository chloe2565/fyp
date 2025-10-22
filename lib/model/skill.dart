class SkillModel {
  String skillID;
  String skillDesc;

  SkillModel({
    required this.skillID,
    required this.skillDesc,
  });
  
  // Convert Firestore data to Dart
  factory SkillModel.fromMap(Map<String, dynamic> data) {
    return SkillModel(
      skillID: data['skillID'],
      skillDesc: data['skillDesc'] ?? '',
    );
  }

  // Convert Dart to Firestore data
  Map<String, dynamic> toMap() {
    return {
      'skillID': skillID,
      'skillDesc': skillDesc,
    };
  }
}