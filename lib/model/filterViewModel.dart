import '../../model/serviceRequestViewModel.dart';

class FilterInput {
  final List<RequestViewModel> allPending;
  final List<RequestViewModel> allUpcoming;
  final List<RequestViewModel> allHistory;
  final String searchQuery;
  final Map<String, String> selectedServices;
  final Map<String, String> selectedStatuses;
  final DateTime? startDate;
  final DateTime? endDate;

  FilterInput({
    required this.allPending,
    required this.allUpcoming,
    required this.allHistory,
    required this.searchQuery,
    required this.selectedServices,
    required this.selectedStatuses,
    this.startDate,
    this.endDate,
  });
}

class FilterOutput {
  final List<RequestViewModel> filteredPending;
  final List<RequestViewModel> filteredUpcoming;
  final List<RequestViewModel> filteredHistory;

  FilterOutput({
    required this.filteredPending,
    required this.filteredUpcoming,
    required this.filteredHistory,
  });
}