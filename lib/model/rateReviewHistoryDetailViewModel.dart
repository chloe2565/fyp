import 'package:flutter/material.dart';
import '../model/databaseModel.dart';

class RatingReviewDetailViewModel {
  final String reqID;
  final String serviceName;
  final DateTime serviceDate;
  final IconData serviceIcon;
  final Color serviceIconBg;
  final String handymanName;
  final double ratingNum;
  final List<String> photos;
  final String reviewText;
  final DateTime? updatedAt;
  final DateTime reviewCreatedAt;
  final ReviewReplyModel? reply;

  RatingReviewDetailViewModel({
    required this.reqID,
    required this.serviceName,
    required this.serviceDate,
    required this.serviceIcon,
    required this.serviceIconBg,
    required this.handymanName,
    required this.ratingNum,
    required this.photos,
    required this.reviewText,
    this.updatedAt,
    required this.reviewCreatedAt,
    this.reply,
  });

  bool get canUpdate {
    // Allow update only if reviewCreatedAt is within 5 days from now
    return DateTime.now().difference(reviewCreatedAt).inDays < 5;
  }

  bool get canDelete {
    // Allow delete only if reviewCreatedAt is within 5 days from now
    return DateTime.now().difference(reviewCreatedAt).inDays < 5;
  }
}
