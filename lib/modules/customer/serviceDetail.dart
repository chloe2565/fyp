import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/service.dart';
import '../../controller/service.dart';
import '../../model/servicePicture.dart';
import 'serviceReqLocation.dart';

class ServiceDetailPage extends StatefulWidget {
  final ServiceModel service;

  const ServiceDetailPage({super.key, required this.service});

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  final PageController _pageController = PageController();
  final ServiceController _serviceController = ServiceController(); 
  int _currentPage = 0;
  List<String> _mainImagePaths = [];
  bool _isLoadingImages = true;

  bool _isLoadingReviews = true;
  List<ReviewDisplayData> _reviews = []; 
  List<String> _reviewImagePaths = [];

  @override
  void initState() {
    super.initState();
    _loadImages();
    _loadReviews();
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

  Future<void> _loadImages() async {
    List<ServicePictureModel> pictures = await _serviceController.getPicturesForService(widget.service.serviceID);

    if (!mounted) return;
    setState(() {
      _mainImagePaths = pictures
          .where((picture) => picture.picName.isNotEmpty)
          .map((picture) {
            final path = 'assets/services/${picture.picName.toLowerCase()}';
            return path;
          })
          .toList();

      _isLoadingImages = false;
    });
  }

  
  Future<void> _loadReviews() async {
    if (!mounted) return;
    setState(() {
      _isLoadingReviews = true;
    });
    try {
      final reviewsData = await _serviceController.getReviewsForService(widget.service.serviceID);
      
      final List<String> galleryImages = [];
      for (final reviewData in reviewsData) {
        if (reviewData.review.ratingPicName != null) {
          galleryImages.addAll(reviewData.review.ratingPicName!);
        }
      }

      if (mounted) {
        setState(() {
          _reviews = reviewsData;
          _reviewImagePaths = galleryImages;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      print('Error loading reviews: $e');
      if (mounted) {
        setState(() {
          _isLoadingReviews = false;
          _reviews = [];
        });
      }
    }
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
        stars.add(
          Icon(Icons.star, color: const Color(0xFFFFC107), size: starSize),
        ); // Amber color for full stars
      } else if (i - rating < 1) {
        stars.add(
          Icon(Icons.star_half,
              color: const Color(0xFFFFC107), size: starSize),
        ); // Amber color for half stars
      } else {
        stars.add(
          Icon(Icons.star_border,
              color: Colors.grey.shade400, size: starSize),
        ); // Grey border for empty stars
      }
    }
    // Removed MainAxisAlignment.center to allow for left-alignment in review tiles
    return Row(children: stars);
  }

  // Helper method to build the dot indicator row
  Widget _buildDotIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _mainImagePaths.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: 8.0,
          width: _currentPage == index ? 24.0 : 8.0,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? const Color(0xFFFF7643) // Orange color from image
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(5),
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
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
      ),
    );
  }

  Widget _buildReviewTile(ReviewDisplayData reviewData) {
    final review = reviewData.review;
    final authorName = reviewData.authorName;
    final String avatarAssetPath = reviewData.avatarPath.isNotEmpty
        ? 'assets/images/${reviewData.avatarPath}'
        : 'assets/images/profile.jpg';
    
    final String formattedDate = DateFormat('dd MMM yyyy').format(review.ratingCreatedAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: AssetImage(avatarAssetPath),
            backgroundColor: Colors.grey.shade200,
            onBackgroundImageError: (exception, stackTrace) {
              print('Error loading avatar: $avatarAssetPath');
            },
            child: reviewData.avatarPath.isEmpty
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      authorName, 
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      formattedDate, 
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildStarRating(review.ratingNum, starSize: 18),
                const SizedBox(height: 8),
                Text(
                  review.ratingText, 
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hardcoded values from the UI image
    final rating = 4.8; // TODO: This should be dynamic from aggregate
    final ordersCompleted = 80; // TODO: This should be dynamic from aggregate

    String introDesc = widget.service.serviceDesc;
    List<String> servicesIncluded = [];
    String servicesTitle = 'Services include:'; 

    if (widget.service.serviceDesc.contains(servicesTitle)) {
      final parts = widget.service.serviceDesc.split(servicesTitle);
      introDesc = parts[0].trim();
      if (parts.length > 1) {
        servicesIncluded = parts[1]
            .trim()
            .split(
              RegExp(
                r'• '
                '|\n- ',
              ),
            ) 
            .map((s) => s.trim().replaceAll('.', ''))
            .where((s) => s.isNotEmpty)
            .toList();
      }
    } 
    else if (widget.service.serviceDesc.contains('Service provided includes')) {
      servicesTitle = 'Service provided includes';
      final parts = widget.service.serviceDesc.split(
        'Service provided includes',
      );
      introDesc = parts[0].trim();
      if (parts.length > 1) {
        servicesIncluded = parts[1]
            .trim()
            .split(',')
            .map((s) => s.trim().replaceAll('.', ''))
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light grey background
      appBar: AppBar(
        backgroundColor: Colors.white, // Solid white app bar
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text(
          widget.service.serviceName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingImages
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. Image Slider ---
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.3,
                    width: double.infinity,
                    child: _mainImagePaths.isEmpty
                        ? Image.asset(
                            'assets/images/placeholder.jpg',
                            fit: BoxFit.cover,
                          )
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: _mainImagePaths.length,
                            itemBuilder: (context, index) {
                              return Image.asset(
                                _mainImagePaths[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/placeholder.jpg',
                                    fit: BoxFit.cover,
                                  );
                                },
                              );
                            },
                          ),
                  ),

                  // --- 2. Dot Indicator ---
                  if (_mainImagePaths.length > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: _buildDotIndicator(),
                    ),

                  // --- 3. White Info Card ---
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    padding: const EdgeInsets.symmetric(
                      vertical: 15.0,
                      horizontal: 15.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left Column: Rating
                            Row(
                              children: [
                                _buildStarRating(rating, starSize: 20),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$rating',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Text(
                                      'Rating',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(width: 15),

                            // Right Column: Orders
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade600,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$ordersCompleted Orders',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Text(
                                      'Completed',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- 4. Content Body ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Duration',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (widget.service.serviceDuration.contains(
                              'to',
                            )) ...[
                              _buildStyledChip(
                                widget.service.serviceDuration
                                    .split('to')[0]
                                    .trim(),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  'To',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                              _buildStyledChip(
                                widget.service.serviceDuration
                                    .split('to')[1]
                                    .trim(),
                              ),
                            ] else
                              _buildStyledChip(widget.service.serviceDuration),
                          ],
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'Price',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildStyledChip(
                          'RM ${widget.service.servicePrice?.toStringAsFixed(0)} / hour',
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          introDesc,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (servicesIncluded.isNotEmpty) ...[
                          Text(
                            servicesTitle, 
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (var item in servicesIncluded)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 2.0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '• ',
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        height: 1.5,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],

                        // Review gallery section
                        const SizedBox(height: 24),
                        if (_reviewImagePaths
                            .isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Review Gallery',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // TODO: Implement 'View all' action for review gallery
                                },
                                child: const Text(
                                  'View all',
                                  style: TextStyle(
                                    color: Color(0xFFFF7643),
                                    fontSize: 16,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              // 1. Use dynamic item count
                              itemCount: _reviewImagePaths.length,
                              itemBuilder: (context, index) {
                                // 2. Get the specific picture name
                                final picName = _reviewImagePaths[index].trim();
                                // 3. Build the asset path
                                final assetPath ='assets/reviews/${picName.toLowerCase()}';
                                
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    assetPath, // 4. Use dynamic path
                                    width: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      print('Error loading review image: $assetPath');
                                      return Image.asset(
                                        'assets/images/placeholder.jpg',
                                        width: 100,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                );
                              },
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 8),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        const Text(
                          'Review',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        _isLoadingReviews
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : _reviews.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text('No reviews yet.'),
                                    ),
                                  )
                                : Column(
                                    children: _reviews
                                        .map((reviewData) =>
                                            _buildReviewTile(reviewData))
                                        .toList(),
                                  ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),

      // Book service button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ServiceRequestLocationPage(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF7643),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Book Service',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}