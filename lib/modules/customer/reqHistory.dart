import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/serviceRequest.dart';
import '../../shared/helper.dart';
import '../../shared/custNavigatorBase.dart';
import '../../shared/serviceRequestFilterDialog.dart';
import 'reqHistoryDetail.dart';

class RequestHistoryScreen extends StatefulWidget {
  const RequestHistoryScreen({super.key});

  @override
  State<RequestHistoryScreen> createState() => RequestHistoryScreenState();
}

class RequestHistoryScreenState extends State<RequestHistoryScreen> {
  int currentIndex = 1;
  bool isInitialized = false;
  late ServiceRequestController controller;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = ServiceRequestController();
    initializeController();
    searchController.addListener(() {
      controller.onSearchChanged(searchController.text);
    });
  }

  Future<void> initializeController() async {
    await controller.initialize();
    if (mounted) {
      setState(() {
        isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
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
        routeToPush = '/custHome';
        break;
      case 1:
        break;
      case 2:
        routeToPush = '/favorite';
        break;
      case 3:
        routeToPush = '/rating';
        break;
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/custHome');
              }
            },
          ),
          title: const Text(
            'Service Request',
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
                  ListenableBuilder(
                    listenable: controller,
                    builder: (context, child) {
                      final int serviceFilterCount =
                          controller.selectedServices.isNotEmpty ? 1 : 0;
                      final int statusFilterCount =
                          controller.selectedStatuses.isNotEmpty ? 1 : 0;
                      final int dateRangeFilterCount =
                          (controller.startDate != null ||
                              controller.endDate != null)
                          ? 1
                          : 0;

                      final int numberOfFilters =
                          serviceFilterCount +
                          statusFilterCount +
                          dateRangeFilterCount;
                      final hasFilter = numberOfFilters > 0;

                      return buildSearchField(
                        context: context,
                        hintText: 'Search requests...',
                        controller: searchController,
                        onFilterPressed: () {
                          showServiceRequestFilterDialog(
                            context: context,
                            controller: controller,
                            onApply:
                                (services, statuses, startDate, endDate) async {
                                  await controller.applyMultiFilters(
                                    services: services,
                                    statuses: statuses,
                                    startDate: startDate,
                                    endDate: endDate,
                                  );
                                },
                            onReset: () async {
                              searchController.clear();
                              await controller.clearFilters();
                            },
                          );
                        },
                        hasFilter: hasFilter,
                        numberOfFilters: numberOfFilters,
                      );
                    },
                  ),

                  const SizedBox(height: 8),
                  buildPrimaryTabBar(
                    context: context,
                    tabs: ['Upcoming', 'History'],
                  ),

                  Expanded(
                    child: ListenableBuilder(
                      listenable: controller,
                      builder: (context, child) {
                        if (controller.isFiltering) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.orange,
                              ),
                            ),
                          );
                        }

                        return TabBarView(
                          children: [buildUpcomingList(), buildHistoryList()],
                        );
                      },
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
  }

  Widget buildUpcomingList() {
    if (controller.isLoadingCustomer) {
      return const Center(child: CircularProgressIndicator());
    }

    final viewModels = controller.filteredUpcomingRequests;

    if (viewModels.isEmpty) {
      return const Center(
        child: Text(
          'No upcoming requests match your filters.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: viewModels.length,
      itemBuilder: (context, index) {
        final requestViewModel = viewModels[index];
        final upcomingDetails = List.of(requestViewModel.details);
        upcomingDetails.add(MapEntry('Status', requestViewModel.reqStatus));
        final List<Widget> upcomingActions = [];
        final now = DateTime.now();
        final scheduledDateTime = requestViewModel.scheduledDateTime;
        final timeUntilScheduled = scheduledDateTime.difference(now);
        final status = requestViewModel.reqStatus.toLowerCase();

        if ((status == 'pending' || status == 'confirmed') &&
            timeUntilScheduled.inHours >= 24) {
          upcomingActions.addAll([
            OutlinedButton(
              onPressed: () =>
                  controller.rescheduleRequest(requestViewModel.reqID),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Reschedule'),
            ),
            OutlinedButton(
              onPressed: () {
                showCancelRequestDialog(
                  context,
                  reqID: requestViewModel.reqID,
                  onConfirmCancel: controller.cancelRequest,
                  onSuccess: controller.loadRequests,
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                foregroundColor: Theme.of(context).colorScheme.error,
                side: const BorderSide(color: Colors.red, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ]);
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider.value(
                  value: controller,
                  child: RequestHistoryDetailScreen(
                    reqID: requestViewModel.reqID,
                    controller: controller,
                  ),
                ),
              ),
            );
          },
          child: InfoCard(
            icon: requestViewModel.icon,
            title: requestViewModel.title,
            details: upcomingDetails,
            actions: upcomingActions,
          ),
        );
      },
    );
  }

  Widget buildHistoryList() {
    if (controller.isLoadingCustomer) {
      return const Center(child: CircularProgressIndicator());
    }

    final viewModels = controller.filteredHistoryRequests;

    if (viewModels.isEmpty) {
      return const Center(
        child: Text(
          'No past service requests match your filters.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: viewModels.length,
      itemBuilder: (context, index) {
        final requestViewModel = viewModels[index];
        final historyDetails = List.of(requestViewModel.details);
        historyDetails.add(MapEntry('Status', requestViewModel.reqStatus));

        if (requestViewModel.amountToPay != null) {
          historyDetails.add(
            MapEntry('Amount to Pay', requestViewModel.amountToPay!),
          );
        }
        if (requestViewModel.payDueDate != null &&
            requestViewModel.paymentStatus?.toLowerCase() != 'paid') {
          historyDetails.add(
            MapEntry('Pay Due Date', requestViewModel.payDueDate!),
          );
        }
        if (requestViewModel.paymentStatus != null) {
          historyDetails.add(
            MapEntry('Payment Status', requestViewModel.paymentStatus!),
          );
        }
        if (requestViewModel.paymentStatus?.toLowerCase() == 'paid' &&
            requestViewModel.paymentCreatedAt != null) {
          historyDetails.add(
            MapEntry(
              'Payment Created Date',
              requestViewModel.paymentCreatedAt!,
            ),
          );
        }

        final List<Widget> historyActions = [];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider.value(
                  value: controller,
                  child: RequestHistoryDetailScreen(
                    reqID: requestViewModel.reqID,
                    controller: controller,
                  ),
                ),
              ),
            );
          },
          child: InfoCard(
            icon: requestViewModel.icon,
            title: requestViewModel.title,
            details: historyDetails,
            actions: historyActions,
          ),
        );
      },
    );
  }

  void showCancelDialog(BuildContext context, String reqID) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Service Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please provide a reason for cancelling this service request:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'Enter cancellation reason...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a cancellation reason'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop();

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const Center(child: CircularProgressIndicator());
                  },
                );

                try {
                  await controller.cancelRequest(reqID, reason);
                  Navigator.of(context).pop(); // Close loading dialog

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Service request cancelled successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop(); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error cancelling request: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Cancel'),
            ),
          ],
        );
      },
    );
  }
}
