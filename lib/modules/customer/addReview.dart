import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/ratingReview.dart';
import '../../shared/helper.dart';

class AddRateReviewScreen extends StatefulWidget {
  final Map<String, dynamic> headerData;

  const AddRateReviewScreen({super.key, required this.headerData});

  @override
  State<AddRateReviewScreen> createState() => AddRateReviewScreenState();
}

class AddRateReviewScreenState extends State<AddRateReviewScreen> {
  bool isLoadingForm = true;
  String? formError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        initializeForm();
      }
    });
  }

  Future<void> initializeForm() async {
    try {
      final controller = Provider.of<RatingReviewController>(
        context,
        listen: false,
      );
      controller.prepareFormForNewReview(widget.headerData);

      if (mounted) {
        setState(() {
          isLoadingForm = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          formError = "Failed to load form: $e";
          isLoadingForm = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rate the Service Request',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: isLoadingForm
          ? const Center(child: CircularProgressIndicator())
          : formError != null
          ? Center(child: Text(formError!))
          : Consumer<RatingReviewController>(
              builder: (context, controller, child) {
                if (controller.formHeaderData == null) {
                  return const Center(
                    child: Text('Error: Missing request data'),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildHeaderCard(controller.formHeaderData!),
                            const SizedBox(height: 24),

                            buildStarRatingInput(controller),
                            const SizedBox(height: 24),

                            buildPhotosSection(controller, context),
                            const SizedBox(height: 24),

                            buildReviewTextField(controller),
                            const SizedBox(height: 80),

                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (controller.currentRating == 0) {
                                        showErrorDialog(
                                          context,
                                          title: "Missing Rating",
                                          message:
                                              "Please give a star rating before submitting your review.",
                                        );
                                        return;
                                      }

                                      // Show loading dialog
                                      showLoadingDialog(
                                        context,
                                        "Submitting your review...",
                                      );

                                      try {
                                        final success = await controller
                                            .submitNewReview();

                                        // Close loading dialog
                                        if (context.mounted)
                                          Navigator.of(context).pop();

                                        if (success && context.mounted) {
                                          showSuccessDialog(
                                            context,
                                            title: "Thank You!",
                                            message:
                                                "Your review has been successfully submitted.",
                                            primaryButtonText: "Back",
                                            onPrimary: () {
                                              Navigator.of(context)
                                                ..pop() // close success dialog
                                                ..pop(
                                                  true,
                                                ); // return to previous page
                                            },
                                          );
                                        } else if (context.mounted) {
                                          showErrorDialog(
                                            context,
                                            title: "Submission Failed",
                                            message:
                                                "Something went wrong while submitting your review.",
                                          );
                                        }
                                      } catch (e) {
                                        // Close loading if still showing
                                        if (context.mounted)
                                          Navigator.of(context).pop();

                                        if (context.mounted) {
                                          showErrorDialog(
                                            context,
                                            title: "Error",
                                            message: "Unexpected error: $e",
                                          );
                                        }
                                      }
                                    },

                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    child: const Text('Submit'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget buildPhotosSection(
    RatingReviewController controller,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Photos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: controller.isPickingImages
                  ? null
                  : controller.handleUploadPhoto,
              icon: const Icon(Icons.upload_file, color: Colors.black),
              label: Text(
                controller.uploadedImages.isEmpty
                    ? 'Upload photo'
                    : 'Add another photo',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  decoration: TextDecoration.none,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
            ),
          ],
        ),

        if (controller.photoErrorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              controller.photoErrorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),

        PhotoPreviewList(
          images: controller.uploadedImages,
          onRemove: controller.removePhoto,
        ),

        const SizedBox(height: 10),
      ],
    );
  }
}
