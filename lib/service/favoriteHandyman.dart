import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/databaseModel.dart';

class FavoriteService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<List<FavoriteHandymanModel>> getAllFavorites(
    String customerID,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final favoriteDocs = await db
        .collection('FavoriteHandyman')
        .where('custID', isEqualTo: customerID)
        .where('favoriteCreatedAt', isGreaterThanOrEqualTo: startDate)
        .where('favoriteCreatedAt', isLessThanOrEqualTo: endDate)
        .get();

    if (favoriteDocs.docs.isEmpty) return [];

    // Convert Firestore docs -> FavoriteHandymanModel list
    return favoriteDocs.docs.map((doc) {
      final data = doc.data();
      return FavoriteHandymanModel.fromMap(data);
    }).toList();
  }

  Future<Map<String, DateTime?>> getFavoriteDateRange(String customerID) async {
    final favoriteDocs = await db
        .collection('FavoriteHandyman')
        .where('custID', isEqualTo: customerID)
        .get();

    if (favoriteDocs.docs.isEmpty) {
      return {'minDate': null, 'maxDate': null};
    }

    // Sort by date to find the first and last
    final favorites = favoriteDocs.docs
        .map((doc) => FavoriteHandymanModel.fromMap(doc.data()))
        .toList();
    favorites.sort(
      (a, b) => a.favoriteCreatedAt.compareTo(b.favoriteCreatedAt),
    );

    return {
      'minDate': favorites.first.favoriteCreatedAt,
      'maxDate': favorites.last.favoriteCreatedAt,
    };
  }

  // Get all favorite handymen details (filtered by date availability)
  Future<List<Map<String, dynamic>>> getFavoriteDetails(
    String customerID,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Get all favorite
      final favoriteList = await getAllFavorites(
        customerID,
        startDate,
        endDate,
      );

      if (favoriteList.isEmpty) return [];

      final allFavoriteHandymanIDs = favoriteList
          .map((fav) => fav.handymanID)
          .toSet()
          .toList();

      // Fetch handyman + skill
      final List<Future<Map<String, dynamic>?>> detailFutures = [];

      for (final handymanID in allFavoriteHandymanIDs) {
        detailFutures.add(getHandymanAndSkill(handymanID));
      }

      final results = await Future.wait(detailFutures);

      // Filter out nulls and return
      return results.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      print('Error fetching favorite details: $e');
      rethrow;
    }
  }

  Future<Set<String>> getAvailableHandymanIDs(
    List<String> handymanIDs,
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (handymanIDs.isEmpty) return {};

    final availabilityDocs = await db
        .collection('HandymanAvailability')
        .where('handymanID', whereIn: handymanIDs)
        .where('availabilityStartDateTime', isLessThanOrEqualTo: endDate)
        .get();

    final Set<String> availableIDs = {};

    for (final doc in availabilityDocs.docs) {
      final data = doc.data();
      final availability = HandymanAvailabilityModel.fromMap(data);

      if (availability.availabilityEndDateTime.isAfter(startDate) ||
          availability.availabilityEndDateTime.isAtSameMomentAs(startDate)) {
        availableIDs.add(availability.handymanID);
      }
    }

    return availableIDs;
  }

  Future<Map<String, dynamic>?> getHandymanAndSkill(String handymanID) async {
    try {
      // Get handyman details
      final handymanDoc = await db.collection('Handyman').doc(handymanID).get();
      if (!handymanDoc.exists) return null;

      final handymanData = handymanDoc.data()!;
      final handyman = HandymanModel.fromMap(handymanData);
      String handymanName = 'Handyman';
      String? userPicName;

      if (handyman.empID.isNotEmpty) {
        // Get Employee doc using employeeID
        final employeeDoc = await db
            .collection('Employee')
            .doc(handyman.empID)
            .get();

        if (employeeDoc.exists) {
          final String userID = employeeDoc.data()!['userID'] ?? '';

          // Get User doc using userID
          if (userID.isNotEmpty) {
            final userDoc = await db.collection('User').doc(userID).get();

            if (userDoc.exists) {
              handymanName = userDoc.data()!['userName'] ?? 'Handyman';
              userPicName = userDoc.data()!['userPicName'] as String?;
            }
          }
        }
      }

      final reviewCountQuery = await db
          .collection('ServiceRequest')
          .where('handymanID', isEqualTo: handymanID)
          .count()
          .get();
      final int reviewCount = reviewCountQuery.count ?? 0;

      // Get first listed skill
      final skillQuery = await db
          .collection('HandymanSkill')
          .where('handymanID', isEqualTo: handymanID)
          .limit(1)
          .get();

      if (skillQuery.docs.isEmpty) return null;

      final skillData = skillQuery.docs.first.data();
      // final handymanSkill = HandymanSkillModel.fromMap(skillData);

      // Get skill details
      // final skillDoc = await db
      //     .collection('Skill')
      //     .doc(handymanSkill.skillID)
      //     .get();
      // if (!skillDoc.exists) return null;

      // final skill = SkillModel.fromMap(skillDoc.data()!);

      return {
        'handyman': handyman,
        // 'skill': skill,
        'handymanName': handymanName,
        'reviewCount': reviewCount,
        'userPicName': userPicName,
      };
    } catch (e) {
      print('Error fetching handyman/skill details: $e');
      return null;
    }
  }
}
