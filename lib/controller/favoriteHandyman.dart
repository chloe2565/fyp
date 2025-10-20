// controllers/favorite_controller.dart
import 'package:flutter/material.dart';
import '../service/favoriteHandyman.dart';

class FavoriteController extends ChangeNotifier {
  // --- Model Layer ---
  final FavoriteService _favoriteService = FavoriteService();

  // --- State ---
  // Hardcode customerID for this example
  final String _currentCustomerID = 'customer123';

  DateTime _startDate = DateTime(2025, 7, 1);
  DateTime _endDate = DateTime(2025, 8, 31);
  late Future<List<Map<String, dynamic>>> _favoritesFuture;

  // --- Getters for the UI ---
  // The UI can read these values but not change them directly.
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  Future<List<Map<String, dynamic>>> get favoritesFuture => _favoritesFuture;

  // --- Constructor ---
  FavoriteController() {
    // Load data immediately when the controller is created
    loadFavorites();
  }

  // --- Logic / Methods ---

  // Fetches data from the service (Model)
  void loadFavorites() {
    _favoritesFuture = _favoriteService.getFavoriteDetails(
      _currentCustomerID,
      _startDate,
      _endDate,
    );
    // Tell the UI to rebuild because the future has been updated.
    notifyListeners();
  }

  // Handles the date picking logic
  Future<void> selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      if (isStart) {
        _startDate = picked;
        if (_startDate.isAfter(_endDate)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _startDate = _endDate;
        }
      }
      
      // After date changes, reload the data
      loadFavorites(); 
      // We don't need notifyListeners() here because loadFavorites() already calls it.
    }
  }
}