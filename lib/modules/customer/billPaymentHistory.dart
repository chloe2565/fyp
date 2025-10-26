import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controller/serviceRequest.dart';
import '../../shared/helper.dart';
import '../../shared/navigatorBase.dart';

class BillPaymentHistoryScreen extends StatefulWidget {
  const BillPaymentHistoryScreen({super.key});

  @override
  State<BillPaymentHistoryScreen> createState() => BillPaymentHistoryScreenState();
}

class BillPaymentHistoryScreenState extends State<BillPaymentHistoryScreen> {
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
      case 3: //rating
        routeToPush = '/home';
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
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
              ),
              title: const Text(
                'Bill and Payment History',
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
                      ),
                      buildPrimaryTabBar(
                        context: context,
                        tabs: ['Billing', 'Payment'],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [buildUpcomingList(), buildHistoryList()],
                        ),
                      ),
                    ],
                  ),
            bottomNavigationBar: AppNavigationBar(
              currentIndex: currentIndex,
              onTap: onNavBarTap,
            ),
          );
        },
      ),
    );
  }

  // build billing list
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

        return InfoCard(
          icon: requestViewModel.icon,
          title: requestViewModel.title,
          details: upcomingDetails,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/billPayment', arguments: requestViewModel.reqID);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Pay'),
            ),
          ],
        );
      },
    );
  }

  // build payment list
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

        return InfoCard(
          icon: requestViewModel.icon,
          title: requestViewModel.title,
          details: historyDetails,
          actions: [/* No actions for history, or "Book Again" */],
        );
      },
    );
  }
}
