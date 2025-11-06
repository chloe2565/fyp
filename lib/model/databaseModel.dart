import 'package:cloud_firestore/cloud_firestore.dart';

class BillingModel {
  final String billingID;
  final double billAmt;
  final DateTime billCreatedAt;
  final DateTime billDueDate;
  final String billStatus; // "cancelled", "paid", "pending"
  final String reqID;
  final String providerID;
  final String? adminRemark;

  BillingModel({
    required this.billingID,
    required this.billAmt,
    required this.billCreatedAt,
    required this.billDueDate,
    required this.billStatus,
    required this.reqID,
    required this.providerID,
    this.adminRemark,
  });

  // Convert Firestore data to Dart
  factory BillingModel.fromMap(Map<String, dynamic> data) {
    return BillingModel(
      billingID: data['billingID'] ?? '',
      billAmt: (data['billAmt'] as num? ?? 0.0).toDouble(),
      billCreatedAt: (data['billCreatedAt'] is Timestamp
          ? (data['billCreatedAt'] as Timestamp).toDate()
          : DateTime.now()),
      billDueDate: (data['billDueDate'] is Timestamp
          ? (data['billDueDate'] as Timestamp).toDate()
          : DateTime.now()),
      billStatus: data['billStatus'] ?? '',
      reqID: data['reqID'] ?? '',
      providerID: data['providerID'] ?? '',
      adminRemark: data['adminRemark'],
    );
  }

  // Convert Dart to Firestore data
  Map<String, dynamic> toMap() {
    return {
      'billingID': billingID,
      'billAmt': billAmt,
      'billCreatedAt': Timestamp.fromDate(billCreatedAt),
      'billDueDate': Timestamp.fromDate(billDueDate),
      'billStatus': billStatus,
      'reqID': reqID,
      'providerID': providerID,
      'adminRemark': adminRemark,
    };
  }
}

class CancelReasonModel {
  final String cancelID;
  final String cancelStatus;
  final String cancelText;

  CancelReasonModel({
    required this.cancelID,
    required this.cancelStatus,
    required this.cancelText,
  });

  // Convert Firestore data to Dart
  factory CancelReasonModel.fromMap(Map<String, dynamic> data) {
    return CancelReasonModel(
      cancelID: data['cancelID'] ?? '',
      cancelStatus: data['cancelStatus'] ?? '',
      cancelText: data['cancelText'] ?? '',
    );
  }

  // Convert Dart to Firestore data
  Map<String, dynamic> toMap() {
    return {
      'cancelID': cancelID,
      'cancelStatus': cancelStatus,
      'cancelText': cancelText,
    };
  }
}

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

  // Convert Firestore data to Dart
  factory CustomerModel.fromMap(Map<String, dynamic> data) {
    return CustomerModel(
      custID: data['custID'] ?? '',
      custAddress: data['custAddress'] ?? '',
      custState: data['custState'] ?? '',
      custStatus: data['custStatus'] ?? '',
      userID: data['userID'] ?? '',
    );
  }

  // Convert Dart to Firestore data
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

class EmployeeModel {
  final String empID;
  final String empStatus; // active, resigned, retired
  final double empSalary;
  final String empType;
  final DateTime empHireDate;
  final String userID;

  EmployeeModel({
    required this.empID,
    required this.empStatus,
    required this.empSalary,
    required this.empType,
    required this.empHireDate,
    required this.userID,
  });

  // Convert Firestore data to Dart
  factory EmployeeModel.fromMap(Map<String, dynamic> data) {
    return EmployeeModel(
      empID: data['empID'] ?? '',
      empStatus: data['empStatus'] ?? '',
      empSalary: (data['empSalary'] as num? ?? 0.0).toDouble(),
      empType: data['empType'] ?? '',
      empHireDate: (data['empHireDate'] is Timestamp
          ? (data['empHireDate'] as Timestamp).toDate()
          : DateTime.now()),
      userID: data['userID'] ?? '',
    );
  }

  // Convert Dart to Firestore data
  Map<String, dynamic> toMap() {
    return {
      "empID": empID,
      "empStatus": empStatus,
      "empSalary": empSalary,
      "empType": empType,
      "empHireDate": Timestamp.fromDate(empHireDate),
      "userID": userID,
    };
  }
}

class FavoriteHandymanModel {
  final String custID;
  final String handymanID;
  final DateTime favoriteCreatedAt;

  FavoriteHandymanModel({
    required this.custID,
    required this.handymanID,
    required this.favoriteCreatedAt,
  });

  // Convert Firestore data to Dart
  factory FavoriteHandymanModel.fromMap(Map<String, dynamic> data) {
    return FavoriteHandymanModel(
      custID: data['custID'] ?? '',
      handymanID: data['handymanID'] ?? '',
      favoriteCreatedAt: (data['favoriteCreatedAt'] is Timestamp
          ? (data['favoriteCreatedAt'] as Timestamp).toDate()
          : DateTime.now()),
    );
  }

  // Convert Dart to Firestore data
  Map<String, dynamic> toMap() {
    return {
      'custID': custID,
      'handymanID': handymanID,
      'favoriteCreatedAt': Timestamp.fromDate(favoriteCreatedAt),
    };
  }
}

class HandymanModel {
  final String handymanID;
  final double handymanRating;
  final String handymanBio;
  final GeoPoint currentLocation;
  final String empID;

  HandymanModel({
    required this.handymanID,
    required this.handymanRating,
    required this.handymanBio,
    required this.currentLocation,
    required this.empID,
  });

  // Convert Firestore data to Dart
  factory HandymanModel.fromMap(Map<String, dynamic> data) {
    return HandymanModel(
      handymanID: data['handymanID'] ?? '',
      handymanRating: (data['handymanRating'] ?? 0).toDouble(),
      handymanBio: data['handymanBio'] ?? '',
      empID: data['empID'] ?? '',
      currentLocation: data['currentLocation'] ?? const GeoPoint(0, 0),
    );
  }

  // Convert Dart to Firestore data
  Map<String, dynamic> toMap() {
    return {
      'handymanID': handymanID,
      'handymanRating': handymanRating,
      'handymanBio': handymanBio,
      'currentLocation': currentLocation,
      'employeeID': empID,
    };
  }
}

class HandymanServiceModel {
  final String handymanID;
  final String serviceID;
  final double yearExperience;

  HandymanServiceModel({
    required this.handymanID,
    required this.serviceID,
    required this.yearExperience,
  });

  // Convert Firestore data to Dart
  factory HandymanServiceModel.fromMap(Map<String, dynamic> data) {
    return HandymanServiceModel(
      handymanID: data['handymanID'] ?? '',
      serviceID: data['serviceID'] ?? '',
      yearExperience: data['yearExperience'] ?? '',
    );
  }

  // Convert Dart to Firestore data
  Map<String, dynamic> toMap() {
    return {
      'handymanID': handymanID,
      'serviceID': serviceID,
      'yearExperience': yearExperience,
    };
  }
}

class PaymentModel {
  final String payID;
  final String payStatus;
  final double payAmt;
  final String payMethod;
  final DateTime payCreatedAt;
  final String adminRemark;
  final String payMediaProof;
  final String providerID;
  final String billingID;

  PaymentModel({
    required this.payID,
    required this.payStatus,
    required this.payAmt,
    required this.payMethod,
    required this.payCreatedAt,
    required this.adminRemark,
    required this.payMediaProof,
    required this.providerID,
    required this.billingID,
  });

  // Convert Firestore data to Dart
  factory PaymentModel.fromMap(Map<String, dynamic> data) {
    return PaymentModel(
      payID: data['payID'] ?? '',
      payStatus: data['payStatus'] ?? '',
      payAmt: (data['payAmt'] as num? ?? 0.0).toDouble(),
      payMethod: data['payMethod'] ?? '',
      payCreatedAt: (data['payCreatedAt'] is Timestamp
          ? (data['payCreatedAt'] as Timestamp).toDate()
          : DateTime.now()),
      adminRemark: data['adminRemark'] ?? '',
      payMediaProof: data['payMediaProof'] ?? '',
      providerID: data['providerID'] ?? '',
      billingID: data['billingID'] ?? '',
    );
  }

  // Convert Dart to Firestore data
  Map<String, dynamic> toMap() {
    return {
      "payID": payID,
      "payStatus": payStatus, // "cancelled", "paid", "failed"
      "payAmt": payAmt,
      "payMethod": payMethod,
      "payCreatedAt": Timestamp.fromDate(payCreatedAt),
      "adminRemark": adminRemark,
      "payMediaProof": payMediaProof,
      "providerID": providerID,
      "billingID": billingID,
    };
  }
}

class RatingReviewModel {
  final String rateID;
  final DateTime ratingCreatedAt;
  final double ratingNum;
  final String ratingText;
  final List<String>? ratingPicName;
  final String reqID;
  final DateTime? updatedAt;

  RatingReviewModel({
    required this.rateID,
    required this.ratingCreatedAt,
    required this.ratingNum,
    required this.ratingText,
    this.ratingPicName,
    required this.reqID,
    this.updatedAt,
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
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
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
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}

class ReportModel {
  final String reportID;
  final String reportName;
  final String reportType;
  final DateTime reportStartDate;
  final DateTime reportEndDate;
  final DateTime reportCreatedAt;
  final String providerID;

  ReportModel({
    required this.reportID,
    required this.reportName,
    required this.reportType,
    required this.reportStartDate,
    required this.reportEndDate,
    required this.reportCreatedAt,
    required this.providerID,
  });

  // Convert Firestore data to Dart
  factory ReportModel.fromMap(Map<String, dynamic> data) {
    return ReportModel(
      reportID: data['reportID'] ?? '',
      reportName: data['reportName'] ?? '',
      reportType: data['reportType'] ?? '',
      reportStartDate: (data['reportStartDate'] is Timestamp
          ? (data['reportStartDate'] as Timestamp).toDate()
          : DateTime.now()),
      reportEndDate: (data['reportEndDate'] is Timestamp
          ? (data['reportEndDate'] as Timestamp).toDate()
          : DateTime.now()),
      reportCreatedAt: (data['reportCreatedAt'] is Timestamp
          ? (data['reportCreatedAt'] as Timestamp).toDate()
          : DateTime.now()),
      providerID: data['providerID'] ?? '',
    );
  }

  // Convert Dart to Firestore data
  Map<String, dynamic> toMap() {
    return {
      "reportID": reportID,
      "reportName": reportName,
      "reportType": reportType,
      "reportStartDate": Timestamp.fromDate(reportStartDate),
      "reportEndDate": Timestamp.fromDate(reportEndDate),
      "reportCreatedAt": Timestamp.fromDate(reportCreatedAt),
      "providerID": providerID,
    };
  }
}

class ReviewReplyModel {
  final String replyID;
  final String replyText;
  final DateTime replyCreatedAt;
  final String rateID;

  ReviewReplyModel({
    required this.replyID,
    required this.replyText,
    required this.replyCreatedAt,
    required this.rateID,
  });

  // Convert Firestore data to Dart
  factory ReviewReplyModel.fromMap(Map<String, dynamic> data) {
    return ReviewReplyModel(
      replyID: data['replyID'] ?? '',
      replyText: data['replyText'] ?? '',
      replyCreatedAt: (data['replyCreatedAt'] is Timestamp
          ? (data['replyCreatedAt'] as Timestamp).toDate()
          : DateTime.now()),
      rateID: data['rateID'] ?? '',
    );
  }

  // Convert Dart to Firestore data
  Map<String, dynamic> toMap() {
    return {
      "replyID": replyID,
      "replyText": replyText,
      "replyCreatedAt": Timestamp.fromDate(replyCreatedAt),
      "rateID": rateID,
    };
  }
}

class ServiceModel {
  final String serviceID;
  final String serviceName;
  final String serviceDesc;
  final double? servicePrice;
  final String serviceDuration;
  final String serviceStatus;
  final DateTime serviceCreatedAt;

  ServiceModel({
    required this.serviceID,
    required this.serviceName,
    required this.serviceDesc,
    this.servicePrice,
    required this.serviceDuration,
    required this.serviceStatus,
    required this.serviceCreatedAt,
  });

  // Convert Firestore data to Dart
  factory ServiceModel.fromMap(Map<String, dynamic> data) {
    return ServiceModel(
      serviceID: data['serviceID'] ?? '',
      serviceName: data['serviceName'] ?? '',
      serviceDesc: data['serviceDesc'] ?? '',
      servicePrice: (data['servicePrice'] as num?)?.toDouble(),
      serviceDuration: data['serviceDuration'] ?? '',
      serviceStatus: data['serviceStatus'] ?? '',
      serviceCreatedAt: (data['serviceCreatedAt'] is Timestamp
          ? (data['serviceCreatedAt'] as Timestamp).toDate()
          : DateTime.now()),
    );
  }

  // Convert Dart to Firestore data
  Map<String, dynamic> toMap() {
    return {
      'serviceID': serviceID,
      'serviceName': serviceName,
      'serviceDesc': serviceDesc,
      'servicePrice': servicePrice,
      'serviceDuration': serviceDuration,
      'serviceStatus': serviceStatus,
      'serviceCreatedAt': Timestamp.fromDate(serviceCreatedAt),
    };
  }
}

class ServicePictureModel {
  final String picID;
  final String serviceID;
  final String picName;
  final bool isPrimary;

  ServicePictureModel({
    required this.picID,
    required this.serviceID,
    required this.picName,
    required this.isPrimary,
  });

  // Convert Firestore data to Dart
  factory ServicePictureModel.fromMap(Map<String, dynamic> data) {
    return ServicePictureModel(
      picID: data['picID'] ?? '',
      serviceID: data['serviceID'] ?? '',
      picName: data['picName'] ?? '',
      isPrimary: data['isPrimary'] ?? false,
    );
  }

  // Convert Dart to Firestore data
  Map<String, dynamic> toMap() {
    return {
      'picID': picID,
      'serviceID': serviceID,
      'picName': picName,
      'isPrimary': isPrimary,
    };
  }
}

class ServiceProviderModel {
  final String providerID;
  final String contactPersonName;
  final String empID;

  ServiceProviderModel({
    required this.providerID,
    required this.contactPersonName,
    required this.empID,
  });

  // Convert Firestore data to Dart
  factory ServiceProviderModel.fromMap(Map<String, dynamic> data) {
    return ServiceProviderModel(
      providerID: data['providerID'] ?? '',
      contactPersonName: data['contactPersonName'] ?? '',
      empID: data['empID'] ?? '',
    );
  }

  // Convert Dart to Firestore data
  Map<String, dynamic> toMap() {
    return {
      "providerID": providerID,
      "contactPersonName": contactPersonName,
      "empID": empID,
    };
  }
}

class ServiceRequestModel {
  final String reqID;
  final DateTime reqDateTime;
  final DateTime scheduledDateTime;
  final String reqAddress;
  final String reqDesc;
  final List<String> reqPicName;
  final DateTime? reqCompleteTime;
  final String reqStatus; // "pending", "confirmed", "departed", "completed", "cancelled"
  final String? reqRemark;
  final DateTime? reqCancelDateTime;
  final String? reqCustomCancel;
  final String custID;
  final String serviceID;
  final String handymanID;
  final String? cancelID;

  ServiceRequestModel({
    required this.reqID,
    required this.reqDateTime,
    required this.scheduledDateTime,
    required this.reqAddress,
    required this.reqDesc,
    required this.reqPicName,
    this.reqCompleteTime,
    required this.reqStatus,
    this.reqRemark,
    this.reqCancelDateTime,
    this.reqCustomCancel,
    required this.custID,
    required this.serviceID,
    required this.handymanID,
    this.cancelID,
  });

  // Convert Firestore data to Dart
  factory ServiceRequestModel.fromMap(Map<String, dynamic> data) {
    return ServiceRequestModel(
      reqID: data['reqID'] ?? '',
      reqDateTime: (data['reqDateTime'] is Timestamp
          ? (data['reqDateTime'] as Timestamp).toDate()
          : DateTime.now()),
      scheduledDateTime: (data['scheduledDateTime'] is Timestamp
          ? (data['scheduledDateTime'] as Timestamp).toDate()
          : DateTime.now()),
      reqAddress: data['reqAddress'] ?? '',
      reqDesc: data['reqDesc'] ?? '',
      reqPicName:
          (data['reqPicName'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      reqCompleteTime: (data['reqCompleteTime'] as Timestamp?)?.toDate(),
      reqStatus: data['reqStatus'] ?? 'pending',
      reqRemark: data['reqRemark'],
      reqCancelDateTime: (data['reqCancelDateTime'] as Timestamp?)?.toDate(),
      reqCustomCancel: data['reqCustomCancel'] ?? '',
      custID: data['custID'] ?? '',
      serviceID: data['serviceID'] ?? '',
      handymanID: data['handymanID'] ?? '',
      cancelID: data['cancelID'] ?? '',
    );
  }

  // Convert Dart to Firestore data
  Map<String, dynamic> toMap() {
    return {
      'reqID': reqID,
      'reqDateTime': Timestamp.fromDate(reqDateTime),
      'scheduledDateTime': Timestamp.fromDate(scheduledDateTime),
      'reqAddress': reqAddress,
      'reqDesc': reqDesc,
      'reqPicName': reqPicName,
      'reqStatus': reqStatus,
      'reqRemark': reqRemark,
      'reqCancelDateTime': reqCancelDateTime != null
          ? Timestamp.fromDate(reqCancelDateTime!)
          : null,
      'reqCustomCancel': reqCustomCancel,
      'custID': custID,
      'serviceID': serviceID,
      'handymanID': handymanID,
      'cancelID': cancelID,
    };
  }
}

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
      userPicName: data['userProfilePic'],
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

class HandymanAvailabilityModel {
  final String availabilityID;
  final DateTime availabilityStartDateTime;
  final DateTime availabilityEndDateTime;
  final DateTime availabilityCreatedAt;
  final String handymanID;

  HandymanAvailabilityModel({
    required this.availabilityID,
    required this.availabilityStartDateTime,
    required this.availabilityEndDateTime,
    required this.availabilityCreatedAt,
    required this.handymanID,
  });

  // Convert Firestore data to Dart
  factory HandymanAvailabilityModel.fromMap(Map<String, dynamic> data) {
    return HandymanAvailabilityModel(
      availabilityID: data['availabilityID'],
      availabilityStartDateTime: (data['availabilityStartDateTime'] is Timestamp
          ? (data['availabilityStartDateTime'] as Timestamp).toDate()
          : DateTime.now()),
      availabilityEndDateTime: (data['availabilityEndDateTime'] is Timestamp
          ? (data['availabilityEndDateTime'] as Timestamp).toDate()
          : DateTime.now()),
      availabilityCreatedAt: (data['availabilityCreatedAt'] is Timestamp
          ? (data['availabilityCreatedAt'] as Timestamp).toDate()
          : DateTime.now()),
      handymanID: data['handymanID'],
    );
  }

  // Convert Dart to Firestore data
  Map<String, dynamic> toMap() {
    return {
      'availabilityID': availabilityID,
      'availabilityStartDateTime': Timestamp.fromDate(
        availabilityStartDateTime,
      ),
      'availabilityEndDateTime': Timestamp.fromDate(availabilityEndDateTime),
      'availabilityCreatedAt': Timestamp.fromDate(availabilityCreatedAt),
      'handymanID': handymanID,
    };
  }
}
