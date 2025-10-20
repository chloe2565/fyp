import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/favoriteHandyman.dart';
import '../model/handymanAvailability.dart';
import '../model/handyman.dart';
import '../model/handymanSkill.dart';
import '../model/skill.dart';

class FavoriteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // This is the main function to get all data needed for the UI
  Future<List<Map<String, dynamic>>> getFavoriteDetails(
    String customerID,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // 1. Get all favorite handyman IDs for the current customer
      final favoriteDocs = await _db
          .collection('FavoriteHandyman')
          .where('customerID', isEqualTo: customerID)
          .get();

      if (favoriteDocs.docs.isEmpty) {
        return []; // No favorites, return empty list
      }

      final allFavoriteHandymanIDs = favoriteDocs.docs
          .map((doc) => FavoriteHandymanModel.fromFirestore(doc.data()).handymanID)
          .toList();

      // 2. Find which of (up to 30) of those handymen are available in the date range
      final availableHandymanIDs = await _getAvailableHandymanIDs(
        allFavoriteHandymanIDs,
        startDate,
        endDate,
      );

      if (availableHandymanIDs.isEmpty) {
        return []; // No favorites are available in this range
      }

      // 3. For each available handyman, get their details and primary skill
      final List<Future<Map<String, dynamic>?>> detailFutures = [];

      for (String handymanID in availableHandymanIDs) {
        detailFutures.add(_getHandymanAndSkill(handymanID));
      }

      // Wait for all fetches to complete
      final results = await Future.wait(detailFutures);

      // Filter out any nulls (e.g., if data was missing) and return the list
      return results.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      print('Error fetching favorite details: $e');
      rethrow;
    }
  }

  // Helper to filter handyman IDs by availability
  Future<Set<String>> _getAvailableHandymanIDs(
    List<String> handymanIDs,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final availabilityDocs = await _db
        .collection('HandymanAvailability')
        .where('handymanID', whereIn: handymanIDs)
        .where('availabilityStartDateTime', isLessThanOrEqualTo: endDate)
        .get();

    final Set<String> availableIDs = {};
    for (var doc in availabilityDocs.docs) {
      final availability = HandymanAvailabilityModel.fromFirestore(doc.data());
      if (availability.availabilityEndDateTime.isAfter(startDate) ||
          availability.availabilityEndDateTime.isAtSameMomentAs(startDate)) {
        availableIDs.add(availability.handymanID);
      }
    }
    return availableIDs;
  }

  // Helper to fetch Handyman and their first Skill
  Future<Map<String, dynamic>?> _getHandymanAndSkill(String handymanID) async {
    try {
      // Fetch Handyman details
      final handymanDoc = await _db.collection('Handyman').doc(handymanID).get();
      if (!handymanDoc.exists) return null;
      final handyman = HandymanModel.fromFirestore(handymanDoc);

      // Fetch their first skill
      final skillQuery = await _db
          .collection('HandymanSkill')
          .where('handymanID', isEqualTo: handymanID)
          .limit(1)
          .get();

      if (skillQuery.docs.isEmpty) return null; // Handyman has no skill listed

      final handymanSkill =
          HandymanSkillModel.fromFirestore(skillQuery.docs.first.data());

      // Fetch the skill description
      final skillDoc =
          await _db.collection('Skill').doc(handymanSkill.skillID).get();
      if (!skillDoc.exists) return null;

      final skill = SkillModel.fromFirestore(skillDoc.data()!);

      // ⚠️ MODIFIED: Return a Map instead of FavoriteDetailsModel
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