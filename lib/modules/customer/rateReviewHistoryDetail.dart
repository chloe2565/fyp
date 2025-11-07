import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controller/ratingReview.dart';
import '../../model/databaseModel.dart';
import '../../model/rateReviewHistoryDetailViewModel.dart';
import '../../shared/fullScreenImage.dart';
import '../../shared/helper.dart';
import 'editReview.dart';

class RateReviewHistoryDetailScreen extends StatefulWidget {
  final String reqID;
  const RateReviewHistoryDetailScreen({super.key, required this.reqID});

  @override
  State<RateReviewHistoryDetailScreen> createState() =>
      RateReviewHistoryDetailScreenState();
}

class RateReviewHistoryDetailScreenState
    extends State<RateReviewHistoryDetailScreen> {
  RatingReviewController? controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller = Provider.of<RatingReviewController>(
          context,
          listen: false,
        );
        controller?.loadReviewDetails(widget.reqID).then((_) {
          controller?.initialize();
        });
      }
    });
  }

  @override
  void dispose() {
    controller?.clearReviewDetails();
    super.dispose();
  }

  void handleDelete(RatingReviewController controller, String reqID) {
    showConfirmDialog(
      context,
      title: 'Delete Review',
      message:
          'Are you sure you want to delete this review? This cannot be undone.',
      affirmativeText: 'Delete',
      onAffirmative: () async {
        showLoadingDialog(context, "Deleting review...");

        try {
          final success = await controller.deleteReview(reqID);
          if (context.mounted) Navigator.of(context).pop(); // Close loading

          if (success && context.mounted) {
            // Show success and pop back to history list
            showSuccessDialog(
              context,
              title: "Review Deleted",
              message: "Your review has been successfully deleted.",
              primaryButtonText: "OK",
              onPrimary: () {
                Navigator.of(context)
                  ..pop() // Close success dialog
                  ..pop(true); // Pop back to history list
              },
            );
          } else if (context.mounted) {
            showErrorDialog(
              context,
              title: "Error",
              message: "Failed to delete review.",
            );
          }
        } catch (e) {
          if (context.mounted) Navigator.of(context).pop(); // Close loading
          if (context.mounted) {
            showErrorDialog(
              context,
              title: "Error",
              message: "An error occurred: $e",
            );
          }
        }
      },
    );
  }

  void handleUpdate(RatingReviewController controller, String reqID) {
    try {
      final itemData = controller.allHistoryData.firstWhere(
        (item) => (item['request'] as ServiceRequestModel).reqID == reqID,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider.value(
            value: controller,
            child: EditRateReviewScreen(headerData: itemData),
          ),
        ),
      ).then((didUpdate) {
        if (didUpdate == true && mounted) {
          controller.loadReviewDetails(reqID);
        }
      });
    } catch (e) {
      print("Error: Could not find review data to update: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Could not find review data to edit.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rate and Review Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[50],
      body: Consumer<RatingReviewController>(
        builder: (context, controller, child) {
          if (controller.detailIsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.detailError != null) {
            return Center(child: Text(controller.detailError!));
          }
          if (controller.detailViewModel == null) {
            return const Center(child: Text('Review details not found.'));
          }

          final viewModel = controller.detailViewModel!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [buildDetailCard(context, controller, viewModel)],
            ),
          );
        },
      ),
    );
  }

  Widget buildDetailCard(
    BuildContext context,
    RatingReviewController controller,
    RatingReviewDetailViewModel viewModel,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color errorColor = Theme.of(context).colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: viewModel.serviceIconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  viewModel.serviceIcon,
                  size: 25,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 12),

              Text(
                viewModel.serviceName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),

              Text(
                dateFormat.format(viewModel.serviceDate),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          Divider(color: Colors.grey[400], height: 40),

          if (viewModel.updatedAt != null) ...[
            buildInfoRow('Updated at', dateFormat.format(viewModel.updatedAt!)),
            const SizedBox(height: 12),
          ],

          buildInfoRow('Handyman name', viewModel.handymanName),
          const SizedBox(height: 12),

          buildInfoRow(
            'Rating',
            '',
            trailing: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  viewModel.ratingNum.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Photos',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 8),

          buildPhotosGrid(context, viewModel.photos),
          const SizedBox(height: 16),

          Text(
            'Review Text',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 8),

          Text(
            viewModel.reviewText.isNotEmpty == true
                ? viewModel.reviewText
                : 'No review text provided',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),

          const SizedBox(height: 24),

          if (viewModel.canUpdate || viewModel.canDelete)
            Row(
              children: [
                if (viewModel.canUpdate)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          handleUpdate(controller, viewModel.reqID),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Update'),
                    ),
                  ),
                if (viewModel.canUpdate && viewModel.canDelete)
                  const SizedBox(width: 12),
                if (viewModel.canDelete)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          handleDelete(controller, viewModel.reqID),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: errorColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget buildInfoRow(String label, String value, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        if (trailing != null)
          trailing
        else
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
      ],
    );
  }

  Widget buildPhotosGrid(BuildContext context, List<String> photos) {
    if (photos.isEmpty) {
      return const Text(
        'No photos provided.',
        style: TextStyle(color: Colors.grey, fontSize: 14),
      );
    }

    const String basePath = 'assets/reviews';

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final String picName = photos[index];
        final String assetPath = '$basePath/${picName.trim().toLowerCase()}';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenGalleryViewer(
                  imagePaths: photos,
                  initialIndex: index,
                  basePath: basePath,
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
