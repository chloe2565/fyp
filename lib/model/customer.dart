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
