
import 'databaseModel.dart';

class ReviewDisplayData {
  final RatingReviewModel review;
  final String authorName;
  final String avatarPath;

  ReviewDisplayData({
    required this.review,
    required this.authorName,
    required this.avatarPath,
  });
}
