class SkillModel {
  String skillID;
  String skillDesc;

  SkillModel({
    required this.skillID,
    required this.skillDesc,
  });

  factory SkillModel.fromFirestore(Map<String, dynamic> data) {
    return SkillModel(
      skillID: data['skillID'],
      skillDesc: data['skillDesc'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'skillID': skillID,
      'skillDesc': skillDesc,
    };
  }
}