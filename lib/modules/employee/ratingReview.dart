import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controller/ratingReview.dart';
import '../../model/databaseModel.dart';
import '../../shared/helper.dart';
import 'ratingReviewDetail.dart';
import '../../shared/empRatingReviewFilterDialog.dart';

class EmpRatingReviewScreen extends StatefulWidget {
  const EmpRatingReviewScreen({super.key});

  @override
  State<EmpRatingReviewScreen> createState() => EmpRatingReviewScreenState();
}

class EmpRatingReviewScreenState extends State<EmpRatingReviewScreen> {
  bool isInitialized = false;
  late RatingReviewController controller;
  final TextEditingController searchController = TextEditingController();

  // Filter state
  String? replyFilter;
  DateTime? startDate;
  DateTime? endDate;
  double? minRating;
  double? maxRating;

  @override
  void initState() {
    super.initState();
    controller = RatingReviewController();
    initializeController();
    searchController.addListener(onSearchChanged);
  }

  Future<void> initializeController() async {
    await controller.initializeForEmployee();
    if (mounted) {
      setState(() {
        isInitialized = true;
      });
    }
  }

  void onSearchChanged() {
    applyFilters();
  }

  void applyFilters() {
    final query = searchController.text;
    controller.applyFilters(
      searchQuery: query,
      replyFilter: replyFilter,
      startDate: startDate,
      endDate: endDate,
      minRating: minRating,
      maxRating: maxRating,
    );
  }

  void showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: RatingReviewFilterDialog(
            initialReplyFilter: replyFilter,
            initialStartDate: startDate,
            initialEndDate: endDate,
            initialMinRating: minRating,
            initialMaxRating: maxRating,
            onApply:
                ({
                  String? replyFilter,
                  DateTime? startDate,
                  DateTime? endDate,
                  double? minRating,
                  double? maxRating,
                }) {
                  if (mounted) {
                    setState(() {
                      this.replyFilter = replyFilter;
                      this.startDate = startDate;
                      this.endDate = endDate;
                      this.minRating = minRating;
                      this.maxRating = maxRating;
                    });
                    applyFilters();
                  }
                },
            onReset: () {
              if (mounted) {
                setState(() {
                  replyFilter = null;
                  startDate = null;
                  endDate = null;
                  minRating = null;
                  maxRating = null;
                });
                applyFilters();
              }
            },
          ),
        );
      },
    );
  }

  int get numberOfFilters {
    int count = 0;
    if (replyFilter != null) count++;
    if (startDate != null || endDate != null) count++;
    if (minRating != null || maxRating != null) count++;
    return count;
  }

  @override
  void dispose() {
    controller.dispose();
    searchController.removeListener(onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFilter = numberOfFilters > 0;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, '/empHome');
                }
              },
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: const Text(
              'Ratings & Reviews',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
          ),
          body: !isInitialized
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    const SizedBox(height: 16),
                    buildSearchField(
                      context: context,
                      controller: searchController,
                      hintText: 'Search by service, handyman, or customer...',
                      onFilterPressed: showFilterDialog,
                      hasFilter: hasFilter,
                      numberOfFilters: numberOfFilters,
                    ),
                    const SizedBox(height: 8),
                    Expanded(child: buildRatingReviewList()),
                  ],
                ),
        );
      },
    );
  }

  Widget buildRatingReviewList() {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final reviews = controller.filteredAllReviews;

    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              searchController.text.isNotEmpty || numberOfFilters > 0
                  ? 'No reviews match your filters.'
                  : 'No ratings and reviews found.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 16),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final reviewData = reviews[index];
        return RatingReviewCard(
          reviewData: reviewData,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmpRatingReviewDetailScreen(
                  reviewData: reviewData,
                  controller: controller,
                  onReplyPosted: () async {
                    await controller.initializeForEmployee();
                    applyFilters();
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class RatingReviewCard extends StatelessWidget {
  final Map<String, dynamic> reviewData;
  final VoidCallback onTap;

  const RatingReviewCard({
    required this.reviewData,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  static final dateFormat = DateFormat('dd MMM yyyy');
  static final timeFormat = DateFormat('hh:mm a');

  @override
  Widget build(BuildContext context) {
    final request = reviewData['request'] as ServiceRequestModel;
    final review = reviewData['review'] as RatingReviewModel;
    final service = reviewData['service'] as ServiceModel?;
    final handymanUser = reviewData['handymanUser'] as UserModel?;
    final customerUser = reviewData['customerUser'] as UserModel?;

    final rating = review.ratingNum;
    final serviceName = service?.serviceName ?? 'Unknown Service';
    final handymanName = handymanUser?.userName ?? 'Not Assigned';
    final customerName = customerUser?.userName ?? 'Unknown Customer';
    final icon = ServiceHelper.getIconForService(serviceName);
    final bgColor = ServiceHelper.getColorForService(serviceName);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Service Icon + Name + Rating
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.black, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      serviceName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Details Grid
              Row(
                children: [
                  Expanded(
                    child: buildDetailItem('Customer Name', customerName),
                  ),
                  Expanded(
                    child: buildDetailItem('Handyman Assigned', handymanName),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: buildDetailItem(
                      'Service Date & Time',
                      Formatter.formatDateTime(request.scheduledDateTime),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: buildDetailItem(
                      'Review Date & Time',
                      Formatter.formatDateTime(review.ratingCreatedAt),
                    ),
                  ),
                  Expanded(
                    child: buildDetailItem(
                      'Service Status',
                      capitalizeFirst(request.reqStatus),
                      valueColor: getStatusColor(request.reqStatus),
                    ),
                  ),
                ],
              ),

              // Review Preview (only if has text)
              Expanded(
                child: buildDetailItem(
                  'Service Status',
                  capitalizeFirst(request.reqStatus),
                  valueColor: getStatusColor(request.reqStatus),
                ),
              ),

              if (review.ratingText.isNotEmpty) ...[
                Text(
                  "Review Text",
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  review.ratingText,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDetailItem(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
