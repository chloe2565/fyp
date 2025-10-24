import 'package:flutter/material.dart';

class RequestViewModel {
  final String reqID;
  final String title;
  final IconData icon; 
  final List<MapEntry<String, String>> details;
  final String reqStatus; 

  RequestViewModel({
    required this.reqID,
    required this.title,
    required this.icon,
    required this.details,
    required this.reqStatus,
  });
}