import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controller/serviceRequest.dart';
import '../../shared/helper.dart';
import '../../shared/custNavigatorBase.dart';
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
        Navigator.pop(context);
        return;
      case 1:
        break;
      case 2:
        routeToPush = '/favorite';
        break;
      case 3: 
        routeToPush = '/rating';
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

  void showFilterDialog() {
    String? tempService = controller.selectedService;
    DateTime? tempDate = controller.selectedDate;
    String? tempStatus = controller.selectedStatus;
    final allStatuses = [
      'Pending',
      'Confirmed',
      'Departed',
      'Completed',
      'Cancelled',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Wrap(
                    runSpacing: 16,
                    children: [
                      const Text(
                        'Filter By',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Service Name Filter
                      DropdownButtonFormField<String>(
                        initialValue: tempService,
                        hint: const Text('Select Service'),
                        items: controller.allServiceNames
                            .map(
                              (name) => DropdownMenuItem(
                                value: name,
                                child: Text(name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setModalState(() => tempService = value),
                        decoration: const InputDecoration(
                          labelText: 'Service Name',
                        ),
                      ),

                      // Status Filter
                      DropdownButtonFormField<String>(
                        initialValue: tempStatus,
                        hint: const Text('Select Status'),
                        items: allStatuses
                            .map(
                              (name) => DropdownMenuItem(
                                value: name.toLowerCase(),
                                child: Text(name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setModalState(() => tempStatus = value),
                        decoration: const InputDecoration(labelText: 'Status'),
                      ),

                      // Date Filter
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: tempDate == null
                              ? ''
                              : DateFormat('dd MMM yyyy').format(tempDate!),
                        ),
                        decoration: InputDecoration(
                          labelText: 'Select Date',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: tempDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (pickedDate != null) {
                            setModalState(() => tempDate = pickedDate);
                          }
                        },
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            child: const Text('Clear Filters'),
                            onPressed: () async {
                              Navigator.pop(context);
                              searchController.clear();
                              await controller.clearFilters();
                            },
                          ),
                          ElevatedButton(
                            child: const Text('Apply'),
                            onPressed: () async {
                              Navigator.pop(context);
                              await controller.applyFilters(
                                service: tempService,
                                date: tempDate,
                                status: tempStatus,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
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
                : controller.isFiltering
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  )
                : Column(
                    children: [
                      buildSearchField(
                        context: context,
                        controller: searchController,
                        onFilterPressed: showFilterDialog,
                      ),
                      buildPrimaryTabBar(
                        context: context,
                        tabs: ['Upcoming', 'History'],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [buildUpcomingList(), buildHistoryList()],
                        ),
                      ),
                    ],
                  ),
            bottomNavigationBar: CustNavigationBar(
              currentIndex: currentIndex,
              onTap: onNavBarTap,
            ),
          );
        },
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
        final scheduledDate = DateUtils.dateOnly(
          requestViewModel.scheduledDateTime,
        );
        final today = DateUtils.dateOnly(now);
        final differenceInDays = scheduledDate.difference(today).inDays;
        final status = requestViewModel.reqStatus.toLowerCase();

        if ((status == 'pending' || status == 'confirmed') &&
            differenceInDays >= 3) {
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
        if (requestViewModel.payDueDate != null) {
          historyDetails.add(
            MapEntry('Pay Due Date', requestViewModel.payDueDate!),
          );
        }
        if (requestViewModel.paymentStatus != null) {
          historyDetails.add(
            MapEntry('Payment Status', requestViewModel.paymentStatus!),
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
}
