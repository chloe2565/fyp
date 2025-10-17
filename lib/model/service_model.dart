// lib/model/service_model.dart
import 'package:flutter/material.dart'; // Import for IconData and Color

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

class Service {
  final String title;
  final List<String> mainImagePaths; // Changed to a list for image slider
  final double rating;
  final int ordersCompleted;
  final String duration;
  final String price;
  final String description;
  final List<String> servicesIncluded;
  final List<String> galleryImagePaths;
  final List<Review> reviews;
  final IconData icon;
  final Color color;

  const Service({
    required this.title,
    required this.mainImagePaths, // Changed to a list
    required this.rating,
    required this.ordersCompleted,
    required this.duration,
    required this.price,
    required this.description,
    required this.servicesIncluded,
    required this.galleryImagePaths,
    required this.reviews,
    required this.icon,
    required this.color,
  });
}