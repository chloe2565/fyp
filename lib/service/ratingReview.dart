import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/ratingReview.dart';

class RatingReviewService {
  final CollectionReference _ratingReviewCollection = FirebaseFirestore.instance.collection('RatingReview');

  Future<List<RatingReviewModel>> getAllRatingReview(String reqID) async {
    QuerySnapshot querySnapshot = await _ratingReviewCollection
        .where('reqID', isEqualTo: reqID)
        .get();

    // Convert docs → model using fromMap()
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return RatingReviewModel.fromMap(data);
    }).toList();
  }
}
