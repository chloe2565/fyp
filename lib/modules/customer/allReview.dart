import 'package:flutter/material.dart';
import '../../model/reviewDisplayViewModel.dart';
import '../../service/image_service.dart';
import '../../shared/helper.dart';
import '../../shared/fullScreenImage.dart';

class AllReviewsScreen extends StatelessWidget {
  final List<String> imagePaths;
  final List<ReviewDisplayData> reviews;

  const AllReviewsScreen({
    super.key,
    required this.imagePaths,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Reviews'),
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: Text(
                '${reviews.length} Reviews',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final reviewData = reviews[index];
              final List<String>? reviewImages =
                  reviewData.review.ratingPicName;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildReviewTile(reviewData),

                  if (reviewImages != null && reviewImages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(88.0, 0, 16.0, 16.0),
                      child: SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: reviewImages.length,
                          separatorBuilder: (context, _) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, imageIndex) {
                            final imageUrl = reviewImages[imageIndex];
                            final int initialGalleryIndex = imagePaths.indexOf(
                              imageUrl,
                            );

                            return GestureDetector(
                              onTap: () {
                                if (initialGalleryIndex != -1) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          FullScreenGalleryViewer(
                                            imagePaths: imagePaths,
                                            initialIndex: initialGalleryIndex,
                                          ),
                                    ),
                                  );
                                }
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: imageUrl.toNetworkImage(
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  if (index < reviews.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            }, childCount: reviews.length),
          ),
        ],
      ),
    );
  }
}