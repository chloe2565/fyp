import 'package:flutter/material.dart';
import 'databaseModel.dart';

class RequestViewModel {
  final String reqID;
  final String title;
  final IconData icon; 
  final List<MapEntry<String, String>> details; // Info card on request history screen
  final String reqStatus; 
  final DateTime scheduledDateTime;
  final String? amountToPay;
  final String? payDueDate;
  final String? paymentStatus;
  final ServiceRequestModel requestModel; 
  final String handymanName;

  RequestViewModel({
    required this.reqID,
    required this.title,
    required this.icon,
    required this.details,
    required this.reqStatus,
    required this.scheduledDateTime,
    this.amountToPay,
    this.payDueDate,
    this.paymentStatus,
    required this.requestModel,
    required this.handymanName,
  });
}