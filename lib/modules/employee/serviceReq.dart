import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controller/serviceRequest.dart';
import '../../shared/empNavigatorBase.dart';
import '../../shared/helper.dart'; // Ensure buildSearchField is available here
import '../../shared/serviceRequestFilterDialog.dart';
import 'serviceReqDetail.dart';

class EmpRequestScreen extends StatefulWidget {
  const EmpRequestScreen({super.key});

  @override
  State<EmpRequestScreen> createState() => EmpRequestScreenState();
}

class EmpRequestScreenState extends State<EmpRequestScreen> {
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
    await controller.initializeForEmployee();
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
        Navigator.pop(context);
        return;
      case 1:
        break;
      case 2:
        routeToPush = '/empEmployee';
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
      length: 3,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          final int serviceFilterCount =
              controller.selectedServices.isNotEmpty ? 1 : 0;
          final int statusFilterCount =
              controller.selectedStatuses.isNotEmpty ? 1 : 0;
          final int dateRangeFilterCount =
              (controller.startDate != null || controller.endDate != null)
                  ? 1
                  : 0;

          final int numberOfFilters =
              serviceFilterCount + statusFilterCount + dateRangeFilterCount;
          final hasFilter = numberOfFilters > 0;

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
                : controller.isFiltering
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.orange),
                        ),
                      )
                    : Column(
                        children: [
                          // Search Field with Filter Button (Similar to reqHistory.dart)
                          buildSearchField(
                            context: context,
                            hintText: 'Search requests...',
                            controller: searchController,
                            onFilterPressed: () {
                              showServiceRequestFilterDialog(
                                context: context,
                                controller: controller,
                                onApply: (services, statuses, startDate,
                                    endDate) async {
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
                          ),

                          FilterChipsDisplay(controller: controller),
                          const SizedBox(height: 8),
                          buildPrimaryTabBar(
                            context: context,
                            tabs: ['Pending', 'Upcoming', 'History'],
                          ),

                          Expanded(
                            child: TabBarView(
                              children: [
                                buildPendingList(),
                                buildUpcomingList(),
                                buildHistoryList(),
                              ],
                            ),
                          ),
                        ],
                      ),
            bottomNavigationBar: EmpNavigationBar(
              currentIndex: currentIndex,
              onTap: onNavBarTap,
            ),
          );
        },
      ),
    );
  }

  Widget buildPendingList() {
    if (controller.isLoadingCustomer) {
      return const Center(child: CircularProgressIndicator());
    }

    final viewModels = controller.filteredPendingRequests;

    if (viewModels.isEmpty) {
      return const Center(
        child: Text(
          'No pending requests match your filters.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: viewModels.length,
      itemBuilder: (context, index) {
        final requestViewModel = viewModels[index];
        final date = DateFormat(
          'dd MMM yyyy',
        ).format(requestViewModel.scheduledDateTime);
        final time = DateFormat(
          'hh:mm a',
        ).format(requestViewModel.scheduledDateTime);

        final pendingDetails = [
          MapEntry('Location', requestViewModel.requestModel.reqAddress),
          MapEntry('Booking Date', date),
          MapEntry('Start Time', time),
          MapEntry('Service', requestViewModel.title),
          MapEntry('Handyman Name', requestViewModel.handymanName),
          MapEntry('Status', requestViewModel.reqStatus),
        ];

        final now = DateTime.now();
        final scheduledDate = DateUtils.dateOnly(
          requestViewModel.scheduledDateTime,
        );
        final today = DateUtils.dateOnly(now);
        final differenceInDays = scheduledDate.difference(today).inDays;

        final List<Widget> pendingActions = [];
        if (differenceInDays >= 3) {
          pendingActions.addAll([
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
              onPressed: () => controller.cancelRequest(requestViewModel.reqID),
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
                  child: EmpRequestDetailScreen(
                    reqID: requestViewModel.reqID,
                    controller: controller,
                  ),
                ),
              ),
            );
          },
          child: EmpInfoCard(
            icon: requestViewModel.icon,
            reqID: requestViewModel.reqID,
            details: pendingDetails,
            onViewDetails: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider.value(
                    value: controller,
                    child: EmpRequestDetailScreen(
                      reqID: requestViewModel.reqID,
                      controller: controller,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
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
        final date = DateFormat(
          'dd MMM yyyy',
        ).format(requestViewModel.scheduledDateTime);
        final time = DateFormat(
          'hh:mm a',
        ).format(requestViewModel.scheduledDateTime);

        final upcomingDetails = [
          MapEntry('Location', requestViewModel.requestModel.reqAddress),
          MapEntry('Booking Date', date),
          MapEntry('Start Time', time),
          MapEntry('Service', requestViewModel.title),
          MapEntry('Handyman Name', requestViewModel.handymanName),
          MapEntry('Status', requestViewModel.reqStatus),
        ];

        final now = DateTime.now();
        final scheduledDate = DateUtils.dateOnly(
          requestViewModel.scheduledDateTime,
        );
        final today = DateUtils.dateOnly(now);
        final differenceInDays = scheduledDate.difference(today).inDays;
        final status = requestViewModel.reqStatus.toLowerCase();

        final List<Widget> upcomingActions = [];
        if (status == 'confirmed' && differenceInDays >= 3) {
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
              onPressed: () => controller.cancelRequest(requestViewModel.reqID),
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
                  child: EmpRequestDetailScreen(
                    reqID: requestViewModel.reqID,
                    controller: controller,
                  ),
                ),
              ),
            );
          },
          child: EmpInfoCard(
            icon: requestViewModel.icon,
            reqID: requestViewModel.reqID,
            details: upcomingDetails,
            onViewDetails: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider.value(
                    value: controller,
                    child: EmpRequestDetailScreen(
                      reqID: requestViewModel.reqID,
                      controller: controller,
                    ),
                  ),
                ),
              );
            },
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
        final date = DateFormat(
          'dd MMM yyyy',
        ).format(requestViewModel.scheduledDateTime);
        final time = DateFormat(
          'hh:mm a',
        ).format(requestViewModel.scheduledDateTime);

        final historyDetails = [
          MapEntry('Location', requestViewModel.requestModel.reqAddress),
          MapEntry('Booking Date', date),
          MapEntry('Start Time', time),
          MapEntry('Service', requestViewModel.title),
          MapEntry('Handyman Name', requestViewModel.handymanName),
          MapEntry('Status', requestViewModel.reqStatus),
        ];

        if (requestViewModel.paymentStatus != null) {
          historyDetails.add(
            MapEntry('Payment Status', requestViewModel.paymentStatus!),
          );
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider.value(
                  value: controller,
                  child: EmpRequestDetailScreen(
                    reqID: requestViewModel.reqID,
                    controller: controller,
                  ),
                ),
              ),
            );
          },
          child: EmpInfoCard(
            icon: requestViewModel.icon,
            reqID: requestViewModel.reqID,
            details: historyDetails,
            onViewDetails: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider.value(
                    value: controller,
                    child: EmpRequestDetailScreen(
                      reqID: requestViewModel.reqID,
                      controller: controller,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}