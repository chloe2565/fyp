import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/favoriteHandyman.dart';
import '../model/handymanAvailability.dart';
import '../model/handyman.dart';
import '../model/handymanSkill.dart';
import '../model/skill.dart';

class FavoriteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get all favorite handymen details (filtered by date availability)
  Future<List<Map<String, dynamic>>> getFavoriteDetails(
    String customerID,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // 1. Get all favorites for this customer
      final favoriteDocs = await _db
          .collection('FavoriteHandyman')
          .where('customerID', isEqualTo: customerID)
          .get();

      if (favoriteDocs.docs.isEmpty) return [];

      // Convert Firestore docs → FavoriteHandymanModel list
      final favoriteList = favoriteDocs.docs.map((doc) {
        final data = doc.data();
        return FavoriteHandymanModel.fromMap(data);
      }).toList();

      // Extract all handyman IDs
      final allFavoriteHandymanIDs =
          favoriteList.map((fav) => fav.handymanID).toList();

      // 2. Filter which of those are available in the date range
      final availableHandymanIDs = await _getAvailableHandymanIDs(
        allFavoriteHandymanIDs,
        startDate,
        endDate,
      );

      if (availableHandymanIDs.isEmpty) return [];

      // 3. Fetch handyman + skill info
      final List<Future<Map<String, dynamic>?>> detailFutures = [];

      for (final handymanID in availableHandymanIDs) {
        detailFutures.add(_getHandymanAndSkill(handymanID));
      }

      final results = await Future.wait(detailFutures);

      // 4. Filter out nulls and return
      return results.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      print('Error fetching favorite details: $e');
      rethrow;
    }
  }

  // 🔹 Helper: Filter handyman IDs by availability
  Future<Set<String>> _getAvailableHandymanIDs(
    List<String> handymanIDs,
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (handymanIDs.isEmpty) return {};

    final availabilityDocs = await _db
        .collection('HandymanAvailability')
        .where('handymanID', whereIn: handymanIDs)
        .where('availabilityStartDateTime', isLessThanOrEqualTo: endDate)
        .get();

    final Set<String> availableIDs = {};

    for (final doc in availabilityDocs.docs) {
      final data = doc.data();
      final availability = HandymanAvailabilityModel.fromMap(data);

      // Include if their availability overlaps the desired range
      if (availability.availabilityEndDateTime.isAfter(startDate) ||
          availability.availabilityEndDateTime.isAtSameMomentAs(startDate)) {
        availableIDs.add(availability.handymanID);
      }
    }

    return availableIDs;
  }

  // 🔹 Helper: Fetch a handyman and their main skill
  Future<Map<String, dynamic>?> _getHandymanAndSkill(String handymanID) async {
    try {
      // 1. Get handyman details
      final handymanDoc =
          await _db.collection('Handyman').doc(handymanID).get();
      if (!handymanDoc.exists) return null;

      final handymanData = handymanDoc.data()!;
      final handyman = HandymanModel.fromMap(handymanData);

      // 2. Get their first listed skill
      final skillQuery = await _db
          .collection('HandymanSkill')
          .where('handymanID', isEqualTo: handymanID)
          .limit(1)
          .get();

      if (skillQuery.docs.isEmpty) return null;

      final skillData = skillQuery.docs.first.data();
      final handymanSkill = HandymanSkillModel.fromMap(skillData);

      // 3. Get skill details
      final skillDoc =
          await _db.collection('Skill').doc(handymanSkill.skillID).get();
      if (!skillDoc.exists) return null;

      final skill = SkillModel.fromMap(skillDoc.data()!);

      return {
        'handyman': handyman,
        'skill': skill,
      };
    } catch (e) {
      print('Error fetching handyman/skill details: $e');
      return null;
    }
  }
}
