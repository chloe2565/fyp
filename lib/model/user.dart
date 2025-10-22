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
  final String? userPicName;

  UserModel({
    required this.userID,
    required this.userEmail,
    required this.userName,
    required this.userGender,
    required this.userContact,
    required this.userType,
    required this.userCreatedAt,
    required this.authID,
    this.userPicName,
  });

  // Convert Firestore data to Dart
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      userID: data['userID'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userName: data['userName'] ?? '',
      userGender: data['userGender'] ?? '',
      userContact: data['userContact'] ?? '',
      userType: data['userType'] ?? '',
      userCreatedAt: (data['userCreatedAt'] is Timestamp
          ? (data['userCreatedAt'] as Timestamp).toDate() 
          : DateTime.now()),  
      authID: data['authID'] ?? '',
      userPicName: data['userProfilePic'] ?? '',
    );
  }

  // Convert Dart to Firestore data
  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'userEmail': userEmail,
      'userName': userName,
      'userGender': userGender,
      'userContact': userContact,
      'userType': userType,
      'userCreatedAt': Timestamp.fromDate(userCreatedAt),
      'authID': authID,
      'userPicName': userPicName,
    };
  }
}