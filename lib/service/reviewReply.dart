import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/databaseModel.dart';

class ReviewReplyService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final CollectionReference reviewReplyCollection = FirebaseFirestore.instance
      .collection('ReviewReply');

  Future<String> generateNextReplyID() async {
    const String prefix = 'RP';
    const int padding = 4;
    final query = await reviewReplyCollection
        .orderBy('replyID', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return '$prefix${'1'.padLeft(padding, '0')}';
    }
    final lastID = query.docs.first.id;
    final numericPart = int.tryParse(lastID.substring(prefix.length)) ?? 0;
    final nextNumber = numericPart + 1;
    return '$prefix${nextNumber.toString().padLeft(padding, '0')}';
  }

  Future<ReviewReplyModel?> getReplyForReview(String rateID) async {
    try {
      final query = await reviewReplyCollection
          .where('rateID', isEqualTo: rateID)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null; // No reply found
      }
      return ReviewReplyModel.fromMap(
        query.docs.first.data() as Map<String, dynamic>,
      );
    } catch (e) {
      print("Error fetching reply for review $rateID: $e");
      return null;
    }
  }

  Future<void> addReplyToReview({
    required String rateID,
    required String replyText,
  }) async {
    try {
      final newReplyID = await generateNextReplyID();
      final newReply = ReviewReplyModel(
        replyID: newReplyID,
        replyText: replyText,
        replyCreatedAt: DateTime.now(),
        rateID: rateID,
      );

      await reviewReplyCollection.doc(newReplyID).set(newReply.toMap());
    } catch (e) {
      print("Error adding reply: $e");
      rethrow;
    }
  }

  Future<void> updateReply({
    required String replyID,
    required String replyText,
  }) async {
    try {
      await reviewReplyCollection.doc(replyID).update({
        'replyText': replyText,
      });
    } catch (e) {
      print("Error updating reply $replyID: $e");
      rethrow;
    }
  }

  Future<void> deleteReply(String replyID) async {
    try {
      await reviewReplyCollection.doc(replyID).delete();
    } catch (e) {
      print("Error deleting reply $replyID: $e");
      rethrow;
    }
  }
}
