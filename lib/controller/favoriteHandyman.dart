import 'package:flutter/material.dart';
import '../service/favoriteHandyman.dart';

class FavoriteController extends ChangeNotifier {
  final FavoriteService favoriteService = FavoriteService();
  final String currentCustomerID = 'customer123';
  DateTime startDateValue = DateTime(2025, 7, 1);
  DateTime endDateValue = DateTime(2025, 8, 31);
  late Future<List<Map<String, dynamic>>> favoritesFutureData;
  DateTime get startDate => startDateValue;
  DateTime get endDate => endDateValue;
  Future<List<Map<String, dynamic>>> get favoritesFuture => favoritesFutureData;

  FavoriteController() {
    loadFavorites();
  }

  void loadFavorites() {
    favoritesFutureData = favoriteService.getFavoriteDetails(
      currentCustomerID,
      startDateValue,
      endDateValue,
    );
    notifyListeners();
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
        startDateValue = picked;
        if (startDateValue.isAfter(endDateValue)) {
          endDateValue = startDateValue;
        }
      } else {
        endDateValue = picked;
        if (endDateValue.isBefore(startDateValue)) {
          startDateValue = endDateValue;
        }
      }
      
      loadFavorites(); 
    }
  }
}