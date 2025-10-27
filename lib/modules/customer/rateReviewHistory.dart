// import 'package:flutter/material.dart';

// import '../../controller/reviewHistory.dart';

// class RateAndReviewHistoryScreen extends StatefulWidget {
//   const RateAndReviewHistoryScreen({super.key});

//   @override
//   State<RateAndReviewHistoryScreen> createState() =>
//       _RateAndReviewHistoryScreenState();
// }

// class _RateAndReviewHistoryScreenState extends State<RateAndReviewHistoryScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   int _bottomNavIndex = 3; // Set 'Rating' as active

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     // Add a listener to switch to the 'History' tab as shown in the image
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _tabController.animateTo(1); // 0 is 'Pending', 1 is 'History'
//     });
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final controller = context.watch<RateReviewHistoryController>();

//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () {
//             // Handle back navigation
//             if (Navigator.canPop(context)) {
//               Navigator.pop(context);
//             }
//           },
//         ),
//         title: const Text(
//           "Rate and Review History",
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//           ),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: NestedScrollView(
//         headerSliverBuilder: (context, innerBoxIsScrolled) {
//           return [
//             SliverToBoxAdapter(child: _buildSearchBar(controller)),
//             SliverPersistentHeader(
//               delegate: _SliverTabBarDelegate(
//                 TabBar(
//                   controller: _tabController,
//                   labelColor: const Color(0xFFF37A20), // Orange color
//                   unselectedLabelColor: Colors.grey[600],
//                   indicatorColor: const Color(0xFFF37A20),
//                   indicatorWeight: 3,
//                   labelStyle: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                   tabs: const [
//                     Tab(text: "Pending"),
//                     Tab(text: "History"),
//                   ],
//                 ),
//               ),
//               pinned: true,
//             ),
//           ];
//         },
//         body: controller.isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : TabBarView(
//                 controller: _tabController,
//                 children: [
//                   _buildReviewList(controller.filteredPendingItems),
//                   _buildReviewList(controller.filteredHistoryItems),
//                 ],
//               ),
//       ),
//       bottomNavigationBar: _buildBottomNavBar(),
//     );
//   }

//   Widget _buildSearchBar(RateReviewHistoryController controller) {
//     return Container(
//       color: Colors.white,
//       padding: const EdgeInsets.all(16.0),
//       child: TextField(
//         onChanged: (value) {
//           controller.filterList(value);
//         },
//         decoration: InputDecoration(
//           hintText: "Search here..",
//           hintStyle: TextStyle(color: Colors.grey[500]),
//           prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
//           suffixIcon: IconButton(
//             icon: Icon(Icons.tune_rounded, color: Colors.grey[700]),
//             onPressed: () {
//               // Handle filter button tap
//             },
//           ),
//           filled: true,
//           fillColor: const Color(0xFFF8F8F8),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12.0),
//             borderSide: BorderSide.none,
//           ),
//           contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
//         ),
//       ),
//     );
//   }

//   Widget _buildReviewList(List<dynamic> items) {
//     if (items.isEmpty) {
//       return Center(
//         child: Text(
//           "No items to show.",
//           style: TextStyle(color: Colors.grey[600], fontSize: 16),
//         ),
//       );
//     }
    
//     // Check item type to decide which card to build
//     bool isHistory = items is List<HistoryReviewItem>;

//     return ListView.builder(
//       padding: const EdgeInsets.all(16.0),
//       itemCount: items.length,
//       itemBuilder: (context, index) {
//         return isHistory
//             ? _buildHistoryCard(items[index])
//             : _buildPendingCard(items[index]);
//       },
//     );
//   }

//   Widget _buildHistoryCard(HistoryReviewItem item) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 16.0),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
//       elevation: 2,
//       shadowColor: Colors.black.withOpacity(0.1),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 CircleAvatar(
//                   backgroundColor: const Color(0xFFEBF3FF),
//                   child: Icon(_getIconForService(item.serviceName),
//                       color: const Color(0xFF004AAD), size: 20),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     item.serviceName,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 18,
//                     ),
//                   ),
//                 ),
//                 Text(
//                   DateFormat('dd MMM yyyy').format(item.date),
//                   style: TextStyle(
//                     color: Colors.grey[600],
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//             const Padding(
//               padding: EdgeInsets.symmetric(vertical: 12.0),
//               child: Divider(),
//             ),
//             _buildInfoRow("Handyman name", item.handymanName),
//             const SizedBox(height: 8),
//             _buildInfoRow(
//               "Rating",
//               null, // Pass null to use the custom rating widget
//               trailingWidget: Row(
//                 children: [
//                   const Icon(Icons.star, color: Colors.orange, size: 20),
//                   const SizedBox(width: 4),
//                   Text(
//                     item.ratingNum.toStringAsFixed(1),
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 15,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),
//             Align(
//               alignment: Alignment.centerRight,
//               child: ElevatedButton(
//                 onPressed: () {
//                   // Handle "View Details" tap
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFF37A20),
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8.0),
//                   ),
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                 ),
//                 child: const Text(
//                   "View Details",
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPendingCard(PendingReviewItem item) {
//     // A different card style for pending reviews
//     return Card(
//       margin: const EdgeInsets.only(bottom: 16.0),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
//       elevation: 2,
//       shadowColor: Colors.black.withOpacity(0.1),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//              Row(
//               children: [
//                 CircleAvatar(
//                   backgroundColor: const Color(0xFFEBF3FF),
//                   child: Icon(_getIconForService(item.serviceName),
//                       color: const Color(0xFF004AAD), size: 20),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     item.serviceName,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 18,
//                     ),
//                   ),
//                 ),
//                 Text(
//                   DateFormat('dd MMM yyyy').format(item.scheduledDate),
//                   style: TextStyle(
//                     color: Colors.grey[600],
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//             const Padding(
//               padding: EdgeInsets.symmetric(vertical: 12.0),
//               child: Divider(),
//             ),
//             _buildInfoRow("Handyman name", item.handymanName),
//             const SizedBox(height: 16),
//              Align(
//               alignment: Alignment.centerRight,
//               child: ElevatedButton(
//                 onPressed: () {
//                   // Handle "Rate Now" tap
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green, // Different color for action
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8.0),
//                   ),
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                 ),
//                 child: const Text(
//                   "Rate Now",
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(String title, String? value,
//       {Widget? trailingWidget}) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           title,
//           style: TextStyle(
//             color: Colors.grey[600],
//             fontSize: 15,
//           ),
//         ),
//         trailingWidget ??
//             Text(
//               value ?? '',
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 15,
//               ),
//             ),
//       ],
//     );
//   }

//   IconData _getIconForService(String serviceName) {
//     // Simple logic to return an icon based on service name
//     if (serviceName.toLowerCase().contains('carpentry')) return Icons.carpentry;
//     if (serviceName.toLowerCase().contains('cleaning')) return Icons.cleaning_services;
//     if (serviceName.toLowerCase().contains('electric')) return Icons.electrical_services;
//     if (serviceName.toLowerCase().contains('painting')) return Icons.format_paint;
//     return Icons.handyman; // Default
//   }

//   Widget _buildBottomNavBar() {
//     return BottomNavigationBar(
//       currentIndex: _bottomNavIndex,
//       onTap: (index) {
//         setState(() {
//           _bottomNavIndex = index;
//           // Handle navigation
//         });
//       },
//       type: BottomNavigationBarType.fixed, // Shows all labels
//       selectedItemColor: const Color(0xFFF37A20), // Orange color
//       unselectedItemColor: Colors.grey[600],
//       selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
//       unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
//       items: const [
//         BottomNavigationBarItem(
//           icon: Icon(Icons.home_outlined),
//           activeIcon: Icon(Icons.home),
//           label: "Home",
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.description_outlined),
//           activeIcon: Icon(Icons.description),
//           label: "Request",
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.favorite_border_outlined),
//           activeIcon: Icon(Icons.favorite),
//           label: "Favorite",
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.star_border_outlined),
//           activeIcon: Icon(Icons.star),
//           label: "Rating",
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.more_horiz_outlined),
//           activeIcon: Icon(Icons.more_horiz),
//           label: "More",
//         ),
//       ],
//     );
//   }
// }

// class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
//   _SliverTabBarDelegate(this._tabBar);

//   final TabBar _tabBar;

//   @override
//   double get minExtent => _tabBar.preferredSize.height;
//   @override
//   double get maxExtent => _tabBar.preferredSize.height;

//   @override
//   Widget build(
//       BuildContext context, double shrinkOffset, bool overlapsContent) {
//     return Container(
//       color: Colors.white,
//       child: _tabBar,
//     );
//   }

//   @override
//   bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
//     return false;
//   }
// }