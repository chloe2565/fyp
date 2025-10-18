import 'package:flutter/material.dart';
import '../../controller/serviceRequest.dart'; 
import '../../model/serviceRequestInfo.dart'; 
import '../../navigatorBase.dart'; 

class RequestHistoryScreen extends StatefulWidget {
  const RequestHistoryScreen({super.key});

  @override
  State<RequestHistoryScreen> createState() => _RequestHistoryScreenState();
}

class _RequestHistoryScreenState extends State<RequestHistoryScreen> {
  int _currentIndex = 1; // 'Request' is the 2nd item (index 1)
  final ServiceRequestRepository _repository = ServiceRequestRepository();
  late Future<List<ServiceRequestInfo>> _upcomingFuture;
  late Future<List<ServiceRequestInfo>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _upcomingFuture =
          _repository.fetchRequestsByStatus(['pending', 'confirmed']);
      _historyFuture =
          _repository.fetchRequestsByStatus(['completed', 'cancelled']);
    });
  }

  // Your navigation logic
  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/home');
        break;
      case 1:
        // We are already here
        break;
      case 2:
        Navigator.pushNamed(context, '/favorite'); // Example
        break;
      case 3:
        Navigator.pushNamed(context, '/rating'); // Example
        break;
      // More menu (index 4) is handled in the navigation bar itself
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two tabs: Upcoming and History
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const BackButton(color: Colors.black),
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
            // --- Search Bar ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: 'Search here...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon:
                        const Icon(Icons.tune, color: Color(0xFFFF7643)),
                    onPressed: () {
                      // TODO: Implement filter action
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            // --- Tab Bar ---
            Container(
              height: 45,
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: const Color(0xFFFF7643), // Orange color
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'History'),
                ],
              ),
            ),

            // --- Tab Bar View ---
            Expanded(
              child: TabBarView(
                children: [
                  // --- Upcoming Tab ---
                  _buildServiceList(_upcomingFuture),
                  // --- History Tab ---
                  _buildServiceList(_historyFuture),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: AppNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavBarTap,
        ),
      ),
    );
  }

  // Builds a list view based on a Future
  Widget _buildServiceList(Future<List<ServiceRequestInfo>> future) {
    return FutureBuilder<List<ServiceRequestInfo>>(
      future: future,
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
              'No service requests found.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final list = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final info = list[index];
            return _buildServiceRequestCard(info);
          },
        );
      },
    );
  }

  // Builds the individual service card from our combined model
  Widget _buildServiceRequestCard(ServiceRequestInfo info) {
    // Format date: August 23, 2025
    final month = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ][info.request.scheduledDateTime.month - 1];
    final bookingDate =
        '${info.request.scheduledDateTime.day} $month ${info.request.scheduledDateTime.year}';

    // Format time: 09:00 AM
    final hour = info.request.scheduledDateTime.hour;
    final minute = info.request.scheduledDateTime.minute;
    final ampm = hour < 12 ? 'AM' : 'PM';
    final displayHour = (hour % 12 == 0 ? 12 : hour % 12)
        .toString()
        .padLeft(2, '0');
    final startTime = '${displayHour}:${minute.toString().padLeft(2, '0')} $ampm';

    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- Card Header ---
          Row(
            children: [
              // Image.asset(
              //   info.service.iconPath, // From ServiceModel
              //   width: 32,
              //   height: 32,
              //   errorBuilder: (context, error, stackTrace) {
              //     return const Icon(Icons.build_circle,
              //         color: Color(0xFFFF7643), size: 32);
              //   },
              // ),
              const SizedBox(width: 12),
              Text(
                info.service.serviceName, // From ServiceModel
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          // --- Card Details ---
          _buildDetailRow('Location', info.request.reqAddress),
          _buildDetailRow('Booking date', bookingDate),
          _buildDetailRow('Start time', startTime),
          // _buildDetailRow(
          //     'Handyman name', info.handymanUser.name), // From UserModel
          const SizedBox(height: 16),
          // --- Card Buttons ---
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Implement Reschedule logic
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF7643),
                    side: const BorderSide(color: Color(0xFFFF7643)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Reschedule',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Implement Cancel logic
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF7643),
                    side: const BorderSide(color: Color(0xFFFF7643)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper widget for a single detail row in the card
  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}