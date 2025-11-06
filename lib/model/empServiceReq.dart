import '../../model/serviceRequestViewModel.dart';

class EmpServiceRequestInput {
  final List<RequestViewModel> allPending;
  final List<RequestViewModel> allUpcoming;
  final List<RequestViewModel> allHistory;
  final String searchQuery;
  final String? selectedService;
  final DateTime? selectedDate;
  final String? selectedStatus;

  EmpServiceRequestInput({
    required this.allPending,
    required this.allUpcoming,
    required this.allHistory,
    required this.searchQuery,
    this.selectedService,
    this.selectedDate,
    this.selectedStatus,
  });
}

class EmpServiceRequestOutput {
  final List<RequestViewModel> filteredPending;
  final List<RequestViewModel> filteredUpcoming;
  final List<RequestViewModel> filteredHistory;

  EmpServiceRequestOutput({
    required this.filteredPending,
    required this.filteredUpcoming,
    required this.filteredHistory,
  });
}