import '../../model/serviceRequestViewModel.dart'; 

class FilterInput {
  final List<RequestViewModel> allUpcoming;
  final List<RequestViewModel> allHistory;
  final String searchQuery;
  final String? selectedService;
  final DateTime? selectedDate;
  final String? selectedStatus;

  FilterInput({
    required this.allUpcoming,
    required this.allHistory,
    required this.searchQuery,
    this.selectedService,
    this.selectedDate,
    this.selectedStatus,
  });
}

class FilterOutput {
  final List<RequestViewModel> filteredUpcoming;
  final List<RequestViewModel> filteredHistory;

  FilterOutput({
    required this.filteredUpcoming,
    required this.filteredHistory,
  });
}