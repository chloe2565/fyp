import 'package:flutter/material.dart'; 

class Review {
  final String rateID;
  final DateTime ratingCreatedAt;
  final double ratingNum;
  final String ratingText;

  Review({
    required this.rateID,
    required this.ratingCreatedAt,
    required this.ratingNum,
    required this.ratingText,
  });
}