// lib/pages/service_detail_page.dart

import 'package:flutter/material.dart';
import '../../model/service_model.dart'; // Ensure correct path

class ServiceDetailPage extends StatefulWidget {
  final Service service;

  const ServiceDetailPage({super.key, required this.service});

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Corrected listener logic
    _pageController.addListener(() {
      if (_pageController.page != null) {
        int nextP = _pageController.page!.round();
        if (_currentPage != nextP) {
          setState(() {
            _currentPage = nextP;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Helper to build star ratings dynamically based on a double rating
  Widget _buildStarRating(double rating, {double starSize = 16}) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      if (i <= rating) {
        stars.add(Icon(Icons.star, color: const Color(0xFFFFC107), size: starSize)); // Amber color for full stars
      } else if (i - rating < 1) {
        stars.add(Icon(Icons.star_half, color: const Color(0xFFFFC107), size: starSize)); // Amber color for half stars
      } else {
        stars.add(Icon(Icons.star_border, color: Colors.grey.shade400, size: starSize)); // Grey border for empty stars
      }
    }
    return Row(children: stars);
  }

  // Helper method to build the dot indicator row
  Widget _buildDotIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.service.mainImagePaths.length,
            (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: 8.0,
          width: _currentPage == index ? 24.0 : 8.0,
          decoration: BoxDecoration(
            color: _currentPage == index ? const Color(0xFFFF7643) : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Allows body to go behind transparent app bar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Make app bar transparent
        elevation: 0, // Remove shadow
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const BackButton(color: Colors.black), // Black back button as in design
        ),
        title: Text(
          widget.service.title,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true, // Center the title
      ),
      body: Stack(
        children: [
          // Image Slider
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.4, // Adjust height to match design
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.service.mainImagePaths.length, // Use a list of main images
              itemBuilder: (context, index) {
                return Image.asset(
                  widget.service.mainImagePaths[index],
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
          // Dot Indicator - This is the corrected part
          if (widget.service.mainImagePaths.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 20, // Simple, fixed offset from the bottom of the image area
              child: _buildDotIndicator(),
            ),
          // Content Area (white card with curved top)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.of(context).size.height * 0.65, // Adjust height for the content card
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)), // Curved top
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 16.0), // Adjusted padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rating and Orders Completed Section
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED), // Light background color from design
                        borderRadius: BorderRadius.circular(12), // Rounded corners
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _buildStarRating(widget.service.rating, starSize: 20),
                              const SizedBox(width: 8),
                              Text(
                                '${widget.service.rating}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green.shade600, size: 20), // Solid check icon
                              const SizedBox(width: 8),
                              Text(
                                '${widget.service.ordersCompleted} Orders Completed',
                                style: const TextStyle(fontSize: 15, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text('Duration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Dynamic duration chips
                        if (widget.service.duration.contains('to')) ...[
                          _buildStyledChip(widget.service.duration.split('to')[0].trim()),
                          const SizedBox(width: 8),
                          _buildStyledChip(widget.service.duration.split('to')[1].trim()),
                        ] else
                          _buildStyledChip(widget.service.duration),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text('Price', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildStyledChip(widget.service.price),
                    const SizedBox(height: 24),

                    const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(
                      widget.service.description,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    // Build the list of included services dynamically with bullet points
                    for (var item in widget.service.servicesIncluded)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 15, height: 1.5)),
                            Expanded(child: Text(item, style: const TextStyle(fontSize: 15, height: 1.5))),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Review Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                            // TODO: Implement 'View all' action for review gallery
                          },
                          child: const Text(
                            'View all',
                            style: TextStyle(color: Color(0xFFFF7643), fontSize: 16, decoration: TextDecoration.none,), // Orange color
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100, // Fixed height for the horizontal gallery
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.service.galleryImagePaths.length,
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10), // Rounded corners for gallery images
                            child: Image.asset(
                              widget.service.galleryImagePaths[index],
                              width: 100, // Fixed width for gallery images
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text('Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    // Build reviews dynamically
                    for (var review in widget.service.reviews) _buildReviewTile(review),
                    const SizedBox(height: 80), // Extra space at the bottom for the floating action button
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0), // Adjusted padding
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3), // Subtle shadow to lift the button
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            // TODO: Implement book service action
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF7643), // Orange color from design
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // More rounded corners
          ),
          child: const Text(
            'Book Service',
            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // Helper widget for consistent chip styling
  Widget _buildStyledChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6), // Light grey background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200), // Lighter border
      ),
      child: Text(text, style: const TextStyle(fontSize: 15, color: Colors.black87)),
    );
  }

  // Helper widget to build individual review tiles
  Widget _buildReviewTile(Review review) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24, // Larger avatar
            backgroundImage: AssetImage(review.avatarPath), // Use actual avatar path
            backgroundColor: Colors.grey.shade200, // Fallback background
            child: review.avatarPath.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(review.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(review.date, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                _buildStarRating(review.rating, starSize: 18), // Use helper for review stars
                const SizedBox(height: 8),
                Text(review.comment, style: const TextStyle(fontSize: 14, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}