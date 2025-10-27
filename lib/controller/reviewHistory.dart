// import '../model/databaseModel.dart';
// import '../model/reviewHistoryViewModel.dart';
// import '../service/handyman.dart';
// import '../service/ratingReview.dart';
// import '../service/service.dart';
// import '../service/serviceRequest.dart';

// class RateReviewHistoryController extends ChangeNotifier {
//   // Services
//   final RatingReviewService _ratingReviewService = RatingReviewService();
//   final HandymanService _handymanService = HandymanService();
//   final ServiceRequestService _serviceRequestService = ServiceRequestService();
//   final ServiceService _serviceService = ServiceService();

//   // State
//   bool _isLoading = true;
//   bool get isLoading => _isLoading;

//   List<PendingReviewItem> _pendingItems = [];
//   List<HistoryReviewItem> _historyItems = [];

//   // Filtered lists for the UI
//   List<PendingReviewItem> filteredPendingItems = [];
//   List<HistoryReviewItem> filteredHistoryItems = [];
//   String _searchQuery = '';

//   RateReviewHistoryController() {
//     fetchReviewHistory();
//   }

//   Future<void> fetchReviewHistory() async {
//     _isLoading = true;
//     notifyListeners();

//     // 1. Get current customer ID (hardcoded for this example)
//     // In a real app, you'd get this from an auth provider.
//     const String currentCustID = "your_current_customer_id";

//     // 2. Get all completed service requests for this customer
//     final completedRequests =
//         await _serviceRequestService.getCompletedRequestsForCustomer(currentCustID);

//     if (completedRequests.isEmpty) {
//       _isLoading = false;
//       notifyListeners();
//       return;
//     }

//     // 3. Extract all unique IDs for batch fetching
//     final reqIDs = completedRequests.map((req) => req.reqID).toSet().toList();
//     final handymanIDs =
//         completedRequests.map((req) => req.handymanID).toSet().toList();
//     final serviceIDs =
//         completedRequests.map((req) => req.serviceID).toSet().toList();

//     // 4. Fetch all data in parallel
//     final [reviewsList, handymanNamesMap, serviceNamesMap] = await Future.wait([
//       _ratingReviewService.getReviewsForServiceRequests(reqIDs),
//       _handymanService.fetchHandymanNames(handymanIDs),
//       _serviceService.fetchServiceNames(serviceIDs),
//     ]);

//     // 5. Create a quick-lookup map for the reviews
//     final reviewMap = {
//       for (var review in (reviewsList as List<RatingReviewModel>))
//         review.reqID: review
//     };

//     // 6. Combine all data and sort into 'Pending' or 'History'
//     List<PendingReviewItem> pending = [];
//     List<HistoryReviewItem> history = [];

//     for (var req in completedRequests) {
//       final review = reviewMap[req.reqID];
//       final handymanName =
//           (handymanNamesMap as Map<String, String>)[req.handymanID] ?? 'N/A';
//       final serviceName =
//           (serviceNamesMap as Map<String, String>)[req.serviceID] ?? 'N/A';

//       if (review != null) {
//         // This request has been reviewed -> Add to History
//         history.add(HistoryReviewItem(
//           serviceName: serviceName,
//           handymanName: handymanName,
//           ratingNum: review.ratingNum,
//           date: review.ratingCreatedAt,
//           reqID: req.reqID,
//         ));
//       } else {
//         // This request is completed but not reviewed -> Add to Pending
//         pending.add(PendingReviewItem(
//           serviceName: serviceName,
//           handymanName: handymanName,
//           scheduledDate: req.scheduledDateTime,
//           reqID: req.reqID,
//         ));
//       }
//     }

//     // 7. Sort by date (newest first)
//     history.sort((a, b) => b.date.compareTo(a.date));
//     pending.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

//     _historyItems = history;
//     _pendingItems = pending;

//     // Initialize filtered lists
//     filteredHistoryItems = _historyItems;
//     filteredPendingItems = _pendingItems;

//     _isLoading = false;
//     notifyListeners();
//   }

//   void filterList(String query) {
//     _searchQuery = query.toLowerCase();

//     if (_searchQuery.isEmpty) {
//       filteredHistoryItems = _historyItems;
//       filteredPendingItems = _pendingItems;
//     } else {
//       filteredHistoryItems = _historyItems
//           .where((item) =>
//               item.serviceName.toLowerCase().contains(_searchQuery) ||
//               item.handymanName.toLowerCase().contains(_searchQuery))
//           .toList();

//       filteredPendingItems = _pendingItems
//           .where((item) =>
//               item.serviceName.toLowerCase().contains(_searchQuery) ||
//               item.handymanName.toLowerCase().contains(_searchQuery))
//           .toList();
//     }
//     notifyListeners();
//   }
// }