import 'package:flutter/material.dart';
import '../service/favoriteHandyman.dart';
import '../service/user.dart';

class FavoriteController extends ChangeNotifier {
  final FavoriteService favoriteService = FavoriteService();
  final UserService userService = UserService();

  late DateTime startDateValue;
  late DateTime endDateValue;
  late Future<List<Map<String, dynamic>>> favoritesFutureData;
  bool isInitialized = false;
  bool get getIsInitialized => isInitialized;
  DateTime get startDate => isInitialized ? startDateValue : DateTime.now();
  DateTime get endDate => isInitialized ? endDateValue : DateTime.now();
  Future<List<Map<String, dynamic>>> get favoritesFuture => favoritesFutureData;

  FavoriteController() {
    loadFavorites();
  }

  void loadFavorites() {
    favoritesFutureData = loadAsync();
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> loadAsync() async {
    final String? customerID = await userService.getCurrentCustomerID();

    if (customerID == null) {
      print("Could not load favorites: No customer ID found.");
      final today = DateTime.now();
      startDateValue = DateTime(today.year, today.month, today.day);
      endDateValue = DateTime(today.year, today.month, today.day, 23, 59, 59);
      isInitialized = true;
      notifyListeners();
      return [];
    }

    final dateRange = await favoriteService.getFavoriteDateRange(customerID);
    final minDate = dateRange['minDate'];
    final maxDate = dateRange['maxDate'];

    if (minDate != null && maxDate != null) {
      startDateValue = DateTime(minDate.year, minDate.month, minDate.day);
      endDateValue = DateTime(
        maxDate.year,
        maxDate.month,
        maxDate.day,
        23,
        59,
        59,
      );
    } else {
      final today = DateTime.now();
      startDateValue = DateTime(today.year, today.month, today.day);
      endDateValue = DateTime(today.year, today.month, today.day, 23, 59, 59);
    }

    isInitialized = true;
    notifyListeners();

    return favoriteService.getFavoriteDetails(
      customerID,
      startDateValue,
      endDateValue,
    );
  }

  Future<void> selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDateValue : endDateValue,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      if (isStart) {
        startDateValue = DateTime(picked.year, picked.month, picked.day);
        if (startDateValue.isAfter(endDateValue)) {
          endDateValue = DateTime(
            picked.year,
            picked.month,
            picked.day,
            23,
            59,
            59,
          );
        }
      } else {
        endDateValue = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
          59,
        );
        if (endDateValue.isBefore(startDateValue)) {
          startDateValue = DateTime(picked.year, picked.month, picked.day);
        }
      }

      loadFavorites();
    }
  }
}
