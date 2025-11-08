import 'package:flutter/foundation.dart';
import '../service/empHomepage.dart';

class DashboardController extends ChangeNotifier {
  final DashboardService dashboardService = DashboardService();

  bool isLoading = false;
  String? errorMessage;
  
  Map<String, int> requestStatusCounts = {};
  Map<String, int> handymanAvailability = {};
  Map<String, int> topServices = {};

  Future<void> loadDashboardData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await dashboardService.getDashboardData();
      
      requestStatusCounts = data['requestStatusCounts'] ?? {};
      handymanAvailability = data['handymanAvailability'] ?? {};
      topServices = data['topServices'] ?? {};
      
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      print('Error loading dashboard data: $e');
    }
  }
}