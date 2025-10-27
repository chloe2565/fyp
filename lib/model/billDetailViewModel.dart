import 'package:flutter/material.dart';
import 'databaseModel.dart';

class BillDetailViewModel {
  // From BillingModel
  final double totalPrice;
  final String billStatus;
  final String billingID;

  // From ServiceRequestModel
  final String customerAddress;
  final DateTime bookingTimestamp; // reqDateTime
  final DateTime serviceTimestamp; // scheduledDateTime

  // From Customer + User
  final String customerName;
  final String customerContact;

  // From ServiceModel
  final String serviceName;
  final String serviceRate; // e.g., "RM 25 / hour"
  final double serviceBasePrice;

  // From Handyman + Employee + User
  final String handymanName;

  // From PaymentModel
  final DateTime? paymentTimestamp;

  // Calculated
  final double outstationFee;

  BillDetailViewModel({
    required this.totalPrice,
    required this.billStatus,
    required this.billingID,
    required this.customerAddress,
    required this.bookingTimestamp,
    required this.serviceTimestamp,
    required this.customerName,
    required this.customerContact,
    required this.serviceName,
    required this.serviceRate,
    required this.serviceBasePrice,
    required this.handymanName,
    this.paymentTimestamp,
  }) : outstationFee = totalPrice - serviceBasePrice;

  bool get isPaymentPending {
    final status = billStatus.toLowerCase();
    return status != 'paid' && status != 'cancelled';
  }
}