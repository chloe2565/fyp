import 'package:flutter/material.dart'; 

class Review {
  final String authorName;
  final String date;
  final String comment;
  final double rating;
  final String avatarPath; // Added for review avatar

  Review({
    required this.authorName,
    required this.date,
    required this.comment,
    required this.rating,
    this.avatarPath = '', // Default empty if not provided
  });
}