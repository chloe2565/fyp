import 'package:flutter/material.dart';
import '../../model/serviceRequestViewModel.dart';
import '../../controller/serviceRequest.dart';
import '../../shared/helper.dart';
import '../../shared/navigatorBase.dart';

class RequestHistoryScreen extends StatefulWidget {
  const RequestHistoryScreen({super.key});

  @override
  State<RequestHistoryScreen> createState() => RequestHistoryScreenState();
}

class RequestHistoryScreenState extends State<RequestHistoryScreen> {
  int currentIndex = 1;
  late ServiceRequestController controller;

  @override
  void initState() {
    super.initState();
    controller = ServiceRequestController();
  }

  @override
  void dispose() {
    controller.dispose();
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
                'Service Request',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
            ),
            body: Column(
              children: [
                buildSearchField(context: context, onFilterPressed: () {}),
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
            bottomNavigationBar: AppNavigationBar(
              currentIndex: currentIndex,
              onTap: onNavBarTap,
            ),
          );
        },
      ),
    );
  }

  Widget buildUpcomingList() {
    return FutureBuilder<List<RequestViewModel>>(
      future: controller.upcomingRequestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No upcoming requests.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        final viewModels = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: viewModels.length,
          itemBuilder: (context, index) {
            final requestViewModel = viewModels[index];

            return InfoCard(
              icon: requestViewModel.icon,
              title: requestViewModel.title,
              details: requestViewModel.details,
              actions: [
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
                  onPressed: () =>
                      controller.cancelRequest(requestViewModel.reqID),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget buildHistoryList() {
    return FutureBuilder<List<RequestViewModel>>(
      future: controller.historyRequestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No past service requests.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        final viewModels = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: viewModels.length,
          itemBuilder: (context, index) {
            final requestViewModel = viewModels[index];
            final historyDetails = List.of(requestViewModel.details);
            historyDetails.add(MapEntry('Status', requestViewModel.reqStatus));

            return InfoCard(
              icon: requestViewModel.icon,
              title: requestViewModel.title,
              details: historyDetails,
              actions: [/* No actions for history, or "Book Again" */],
            );
          },
        );
      },
    );
  }
}
