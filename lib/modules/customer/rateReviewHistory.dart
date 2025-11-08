import 'package:flutter/material.dart';
import 'package:fyp/modules/customer/addReview.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controller/ratingReview.dart';
import '../../model/databaseModel.dart';
import '../../shared/custNavigatorBase.dart';
import '../../shared/helper.dart';
import '../../shared/custRatingReviewFilterDialog.dart';
import 'rateReviewHistoryDetail.dart';

class RateReviewHistoryScreen extends StatefulWidget {
  const RateReviewHistoryScreen({super.key});

  @override
  State<RateReviewHistoryScreen> createState() =>
      RateReviewHistoryScreenState();
}

class RateReviewHistoryScreenState extends State<RateReviewHistoryScreen> {
  int currentIndex = 3;
  bool isInitialized = false;
  late RatingReviewController ratingReviewController;
  final TextEditingController searchController = TextEditingController();

  Map<String, String> serviceFilter = {};
  DateTime? startDate;
  DateTime? endDate;
  double? minRating;
  double? maxRating;

  @override
  void initState() {
    super.initState();
    ratingReviewController = RatingReviewController();
    initializeController();
    searchController.addListener(onSearchChanged);
  }

  Future<void> initializeController() async {
    await ratingReviewController.initialize();
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
    ratingReviewController.applyFilters(
      searchQuery: query,
      serviceFilter: serviceFilter,
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
          child: CustomerRatingReviewFilterDialog(
            availableServices: ratingReviewController.allAvailableServices,
            initialServiceFilter: serviceFilter,
            initialStartDate: startDate,
            initialEndDate: endDate,
            initialMinRating: minRating,
            initialMaxRating: maxRating,
            onApply:
                ({
                  Map<String, String>? serviceFilter,
                  DateTime? startDate,
                  DateTime? endDate,
                  double? minRating,
                  double? maxRating,
                }) {
                  if (mounted) {
                    setState(() {
                      this.serviceFilter = serviceFilter ?? {};
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
                  serviceFilter = {};
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
    if (serviceFilter.isNotEmpty) count++;
    if (startDate != null || endDate != null) count++;
    if (minRating != null || maxRating != null) count++;
    return count;
  }

  @override
  void dispose() {
    ratingReviewController.dispose();
    searchController.removeListener(onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void onNavBarTap(int index) async {
    if (index == currentIndex) {
      return;
    }

    String? routeToPush;

    switch (index) {
      case 0:
        Navigator.pop(context);
        return;
      case 1:
        routeToPush = '/request';
        break;
      case 2:
        routeToPush = '/favorite';
        break;
      case 3:
        break;
      // More menu (index 4) is handled in the navigation bar itself
    }

    if (routeToPush != null) {
      await Navigator.pushNamed(context, routeToPush);

      if (mounted) {
        setState(() {
          currentIndex = 1;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFilter = numberOfFilters > 0;

    return ChangeNotifierProvider.value(
      value: ratingReviewController,
      child: Consumer<RatingReviewController>(
        builder: (context, controller, child) {
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: const Text(
                  'Rate and Review History',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
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
                          onFilterPressed: showFilterDialog,
                          hasFilter: hasFilter,
                          numberOfFilters: numberOfFilters,
                        ),
                        const SizedBox(height: 16),
                        buildPrimaryTabBar(
                          context: context,
                          tabs: ['Pending', 'History'],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              buildList(
                                controller.filteredPending,
                                isPending: true,
                              ),
                              buildList(
                                controller.filteredHistory,
                                isPending: false,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
              bottomNavigationBar: CustNavigationBar(
                currentIndex: currentIndex,
                onTap: onNavBarTap,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildList(
    List<Map<String, dynamic>> items, {
    required bool isPending,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              searchController.text.isNotEmpty || numberOfFilters > 0
                  ? 'No reviews found.'
                  : isPending
                  ? 'No pending reviews.'
                  : 'No review history found.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return RatingReviewCard(itemData: items[index], isPending: isPending);
      },
    );
  }
}

class RatingReviewCard extends StatelessWidget {
  final Map<String, dynamic> itemData;
  final bool isPending;

  const RatingReviewCard({
    required this.itemData,
    required this.isPending,
    Key? key,
  }) : super(key: key);

  void handleRateNowPressed(BuildContext context) async {
    try {
      final controller = Provider.of<RatingReviewController>(
        context,
        listen: false,
      );

      itemData.forEach((key, value) {
        print("  $key: ${value.runtimeType}");
      });

      final request = itemData['request'] as ServiceRequestModel?;
      if (request == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Invalid request data")));
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return ChangeNotifierProvider.value(
              value: controller,
              child: AddRateReviewScreen(headerData: itemData),
            );
          },
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void handleHistoryCardPressed(BuildContext context) {
    final request = itemData['request'] as ServiceRequestModel;
    final controller = Provider.of<RatingReviewController>(
      context,
      listen: false,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: controller,
          child: RateReviewHistoryDetailScreen(reqID: request.reqID),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = itemData['request'] as ServiceRequestModel;
    final service = itemData['service'] as ServiceModel?;
    final handyman = itemData['handymanUser'] as UserModel?;
    final review = itemData['review'] as RatingReviewModel?;
    final dateFormat = DateFormat('dd MMM yyyy');

    final DateTime? dateToShow = isPending
        ? request.reqCompleteTime
        : review?.ratingCreatedAt;
    final String dateStr = dateFormat.format(dateToShow!);
    final String serviceName = service?.serviceName ?? 'Unknown Service';
    final String handymanName = handyman?.userName ?? 'Unknown Handyman';
    final IconData icon = ServiceHelper.getIconForService(serviceName);
    final Color iconBg = ServiceHelper.getColorForService(serviceName);
    final Color primaryColor = Theme.of(context).primaryColor;

    return InkWell(
      onTap: isPending ? null : () => handleHistoryCardPressed(context),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 25, color: Colors.black),
                  ),
                  const SizedBox(width: 12),

                  Text(
                    serviceName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),

                  if (!isPending)
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.grey[400]),
              const SizedBox(height: 8),

              // Service Request Completed Time
              if (isPending) buildInfoRow('Service Completed', dateStr),
              const SizedBox(height: 12),

              // Handyman Name
              buildInfoRow('Handyman name', handymanName),
              const SizedBox(height: 12),

              // Rating
              buildInfoRow(
                'Rating',
                isPending ? 'Pending' : '',
                trailing: isPending
                    ? null
                    : Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            review?.ratingNum.toStringAsFixed(1) ?? '0.0',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),

              // Row 4: Button
              if (isPending)
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    onPressed: () => handleRateNowPressed(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Rate Now'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInfoRow(String label, String value, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        if (trailing != null)
          trailing
        else
          Text(value, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      ],
    );
  }
}
