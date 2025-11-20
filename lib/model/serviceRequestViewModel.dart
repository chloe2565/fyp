import 'package:flutter/material.dart';
import 'databaseModel.dart';

class RequestViewModel {
  final String reqID;
  final String title;
  final IconData icon; 
  final List<MapEntry<String, String>> details; // Info card on request history screen
  final String reqStatus; 
  final DateTime reqDateTime;
  final DateTime scheduledDateTime;
  final String? amountToPay;
  final String? payDueDate;
  final DateTime? payDueDateRaw;
  final String? paymentStatus;
  final DateTime? paymentCreatedAt;
  final ServiceRequestModel requestModel; 
  final String handymanName;
  final String customerName; 
  final String customerContact;
  final BillingModel? billing;
  final PaymentModel? payment;

  RequestViewModel({
    required this.reqID,
    required this.title,
    required this.icon,
    required this.details,
    required this.reqStatus,
    required this.reqDateTime,
    required this.scheduledDateTime,
    this.amountToPay,
    this.payDueDate,
    this.payDueDateRaw, 
    this.paymentStatus,
    this.paymentCreatedAt,
    required this.requestModel,
    required this.handymanName,
    required this.customerName,
    required this.customerContact,
    this.billing,
    this.payment,
  });
}