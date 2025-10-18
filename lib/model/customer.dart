import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String custID;
  final String custAddress;
  final String custState;
  final String custStatus;
  final String userID;

  CustomerModel({
    required this.custID,
    required this.custAddress,
    required this.custState,
    required this.custStatus,
    required this.userID,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> data, String custID) {
    return CustomerModel(
      custID: custID,
      custAddress: data['custAddress'] ?? '',
      custState: data['custState'] ?? '',
      custStatus: data['custStatus'] ?? '',
      userID: data['userID'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "custID": custID,
      "custAddress": custAddress,
      "custState": custState,
      "custStatus": custStatus,
      "userID": userID,
    };
  }
}