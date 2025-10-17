import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userID;
  final String userEmail;
  final String userName;
  final String userGender;
  final String userContact;
  final String userType;
  final DateTime userCreatedAt;
  final String authID;

  UserModel({
    required this.userID,
    required this.userEmail,
    required this.userName,
    required this.userGender,
    required this.userContact,
    required this.userType,
    required this.userCreatedAt,
    required this.authID,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String userID) {
    return UserModel(
      userID: userID,
      userEmail: data['userEmail'] ?? '',
      userName: data['userName'] ?? '',
      userGender: data['userGender'] ?? '',
      userContact: data['userContact'] ?? '',
      userType: data['userType'] ?? '',
      userCreatedAt: (data['userCreatedAt'] is Timestamp
          ? (data['userCreatedAt'] as Timestamp).toDate() // This will give full date and time
          : DateTime.now()),  // Default to current time if not found
      authID: data['authID'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userEmail': userEmail,
      'userName': userName,
      'userGender': userGender,
      'userContact': userContact,
      'userType': userType,
      'userCreatedAt': Timestamp.fromDate(userCreatedAt),  // Store as Timestamp
      'authID': authID,
    };
  }
}