import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controller/ratingReview.dart';
import '../../model/databaseModel.dart';
import '../../shared/helper.dart';
import 'ratingReviewDetail.dart';

class EmpRatingReviewScreen extends StatefulWidget {
  const EmpRatingReviewScreen({super.key});

  @override
  State<EmpRatingReviewScreen> createState() => EmpRatingReviewScreenState();
}

class EmpRatingReviewScreenState extends State<EmpRatingReviewScreen> {
  bool isInitialized = false;
  late RatingReviewController controller;
  final TextEditingController searchController = TextEditingController();

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
    final query = searchController.text;
    controller.onSearchChanged(query);
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
              'Rate and Review',
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
                    buildSearchField(
                      context: context,
                      controller: searchController,
                    ),
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
      return const Center(
        child: Text(
          'No rating reviews found.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
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
                  onReplyPosted: () {
                    controller.initializeForEmployee();
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
    final rating = review.ratingNum ?? 0.0;

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
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.rateID,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Service Request ID',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Handyman ID',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                request.reqID,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                request.handymanID,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Rating',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 2),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(request.scheduledDateTime),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        timeFormat.format(request.scheduledDateTime),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
