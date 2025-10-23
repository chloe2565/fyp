import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/ratingReview.dart';

class RatingReviewService {
  final CollectionReference _ratingReviewCollection = FirebaseFirestore.instance.collection('RatingReview');

  Future<List<RatingReviewModel>> getReviewsForServiceRequests(
      List<String> reqIDs) async {
    if (reqIDs.isEmpty) {
      return []; 
    }

    try {
      QuerySnapshot querySnapshot = await _ratingReviewCollection
          .where('reqID', whereIn: reqIDs) 
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