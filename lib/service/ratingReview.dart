import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/ratingReview.dart';

class RatingReviewService {
  final CollectionReference _ratingReviewCollection = FirebaseFirestore.instance.collection('RatingReview');

  Future<List<RatingReviewModel>> getReviewsForServiceRequests(
      List<String> reqIDs) async {
    if (reqIDs.isEmpty) {
      return []; // Return empty list if no request IDs are provided
    }

    try {
      QuerySnapshot querySnapshot = await _ratingReviewCollection
          .where('reqID', whereIn: reqIDs) // Use 'whereIn' for efficiency
          .get();

      // Convert docs → model using fromMap()
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return RatingReviewModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error in getReviewsForServiceRequests: $e');
      return [];
    }
  }
}