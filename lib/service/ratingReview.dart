import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/databaseModel.dart';

class RatingReviewService {
  final CollectionReference ratingReviewCollection = FirebaseFirestore.instance.collection('RatingReview');

  Future<List<RatingReviewModel>> getReviewsForServiceRequests(
      List<String> reqIDs) async {
    if (reqIDs.isEmpty) {
      return [];
    }

    try {
      List<RatingReviewModel> allReviews = [];
      for (var i = 0; i < reqIDs.length; i += 30) {
        final sublist =
            reqIDs.sublist(i, i + 30 > reqIDs.length ? reqIDs.length : i + 30);
        
        final querySnapshot = await ratingReviewCollection
            .where('reqID', whereIn: sublist)
            .get();

        final reviews = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return RatingReviewModel.fromMap(data);
        }).toList();
        allReviews.addAll(reviews);
      }
      return allReviews;
    } catch (e) {
      print('Error in getReviewsForServiceRequests: $e');
      return [];
    }
  }
}