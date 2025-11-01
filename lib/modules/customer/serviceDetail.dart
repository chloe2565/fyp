import 'package:flutter/material.dart';
import '../../shared/helper.dart';
import '../../model/reviewDisplayViewModel.dart';
import '../../model/databaseModel.dart';
import '../../controller/service.dart';
import 'serviceReqLocation.dart';
import 'allReview.dart';

class ServiceDetailScreen extends StatefulWidget {
  final ServiceModel service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  State<ServiceDetailScreen> createState() => ServiceDetailScreenState();
}

class ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final PageController pageController = PageController();
  final ServiceController serviceController = ServiceController();

  int currentPage = 0;
  List<String> mainImagePaths = [];
  bool isLoadingImages = true;
  bool isLoadingReviews = true;
  List<ReviewDisplayData> reviews = [];
  List<String> reviewImagePaths = [];
  bool isLoadingAggregates = true;
  double averageRating = 0.0;
  int completedOrders = 0;

  @override
  void initState() {
    super.initState();
    loadImages();
    loadReviews();
    loadAggregates();
    pageController.addListener(() {
      if (pageController.page != null) {
        int nextP = pageController.page!.round();
        if (currentPage != nextP) {
          setState(() {
            currentPage = nextP;
          });
        }
      }
    });
  }

  Future<void> loadImages() async {
    List<ServicePictureModel> pictures = await serviceController
        .getPicturesForService(widget.service.serviceID);

    if (!mounted) return;
    setState(() {
      mainImagePaths = pictures
          .where((picture) => picture.picName.isNotEmpty)
          .map((picture) {
            final path = 'assets/services/${picture.picName.toLowerCase()}';
            return path;
          })
          .toList();

      isLoadingImages = false;
    });
  }

  Future<void> loadAggregates() async {
    if (!mounted) return;
    setState(() {
      isLoadingAggregates = true;
    });

    try {
      final aggregates = await serviceController.getServiceAggregates(
        widget.service.serviceID,
      );
      if (mounted) {
        setState(() {
          averageRating = aggregates.averageRating;
          completedOrders = aggregates.completedOrders;
          isLoadingAggregates = false;
        });
      }
    } catch (e) {
      print('Error loading aggregates: $e');
      if (mounted) {
        setState(() {
          isLoadingAggregates = false;
          averageRating = 0.0;
          completedOrders = 0;
        });
      }
    }
  }

  Future<void> loadReviews() async {
    if (!mounted) return;
    setState(() {
      isLoadingReviews = true;
    });
    try {
      final reviewsData = await serviceController.getReviewsForService(
        widget.service.serviceID,
      );

      final List<String> galleryImages = [];
      for (final reviewData in reviewsData) {
        if (reviewData.review.ratingPicName != null) {
          galleryImages.addAll(reviewData.review.ratingPicName!);
        }
      }

      if (mounted) {
        setState(() {
          reviews = reviewsData;
          reviewImagePaths = galleryImages;
          isLoadingReviews = false;
        });
      }
    } catch (e) {
      print('Error loading reviews: $e');
      if (mounted) {
        setState(() {
          isLoadingReviews = false;
          reviews = [];
        });
      }
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Widget buildDotIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        mainImagePaths.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: 8.0,
          width: currentPage == index ? 24.0 : 8.0,
          decoration: BoxDecoration(
            color: currentPage == index
                ? const Color(0xFFFF7643) 
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String introDesc = widget.service.serviceDesc;
    List<String> servicesIncluded = [];
    String servicesTitle = 'Services include:';
    const String splitKeyword = 'Service provided includes';

    if (widget.service.serviceDesc.contains(splitKeyword)) {
      final parts = widget.service.serviceDesc.split(splitKeyword);

      introDesc = parts[0].trim();

      if (parts.length > 1) {
        servicesIncluded = parts[1]
            .trim()
            .split(RegExp(r'• |\n- |,'))
            .map((s) => s.trim().replaceAll('.', ''))
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[50], 
      appBar: AppBar(
        backgroundColor: Colors.white, 
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
      body: isLoadingImages
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Image Slider ---
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.3,
                    width: double.infinity,
                    child: mainImagePaths.isEmpty
                        ? Image.asset(
                            'assets/images/placeholder.jpg',
                            fit: BoxFit.cover,
                          )
                        : PageView.builder(
                            controller: pageController,
                            itemCount: mainImagePaths.length,
                            itemBuilder: (context, index) {
                              return Image.asset(
                                mainImagePaths[index],
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

                  // --- Dot Indicator ---
                  if (mainImagePaths.length > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: buildDotIndicator(),
                    ),

                  // --- White Info Card ---
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
                          color: Colors.grey.withValues(alpha: 0.1),
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
                                buildStarRating(averageRating, starSize: 20),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isLoadingAggregates
                                          ? '...'
                                          : averageRating.toStringAsFixed(1),
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
                                      isLoadingAggregates
                                          ? '...'
                                          : '$completedOrders Orders',
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

                  // --- Content Body ---
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
                              buildStyledChip(
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
                              buildStyledChip(
                                widget.service.serviceDuration
                                    .split('to')[1]
                                    .trim(),
                              ),
                            ] else
                              buildStyledChip(widget.service.serviceDuration),
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
                        buildStyledChip(
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
                        if (reviewImagePaths.isNotEmpty) ...[
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AllReviewsScreen(
                                        imagePaths: reviewImagePaths,
                                        reviews: reviews,
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  'View all',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
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
                              itemCount: reviewImagePaths.length,
                              itemBuilder: (context, index) {
                                // 2. Get the specific picture name
                                final picName = reviewImagePaths[index].trim();
                                // 3. Build the asset path
                                final assetPath =
                                    'assets/reviews/${picName.toLowerCase()}';

                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    assetPath, // 4. Use dynamic path
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print(
                                        'Error loading review image: $assetPath',
                                      );
                                      return Image.asset(
                                        'assets/images/placeholder.jpg',
                                        width: 100,
                                        height: 100,
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

                        isLoadingReviews
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : reviews.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('No reviews yet.'),
                                ),
                              )
                            : Column(
                                children: reviews
                                    .map(
                                      (reviewData) =>
                                          buildReviewTile(reviewData),
                                    )
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
              color: Colors.grey.withValues(alpha: 0.1),
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
                builder: (context) => ServiceRequestLocationScreen(
                  serviceID: widget.service.serviceID,
                  serviceName: widget.service.serviceName,
                ),
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
