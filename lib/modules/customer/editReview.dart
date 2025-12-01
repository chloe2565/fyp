import 'package:flutter/material.dart';
import 'package:fyp/service/image_service.dart';
import 'package:provider/provider.dart';
import '../../controller/ratingReview.dart';
import '../../shared/helper.dart';

class EditRateReviewScreen extends StatefulWidget {
  final Map<String, dynamic> headerData;

  const EditRateReviewScreen({super.key, required this.headerData});

  @override
  State<EditRateReviewScreen> createState() => EditRateReviewScreenState();
}

class EditRateReviewScreenState extends State<EditRateReviewScreen> {
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
      controller.prepareFormForEdit(widget.headerData);

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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      body: isLoadingForm
          ? const Center(child: CircularProgressIndicator())
          : formError != null
          ? Center(child: Text(formError!))
          : Consumer<RatingReviewController>(
              builder: (context, controller, child) {
                if (controller.formHeaderData == null) {
                  return const Center(
                    child: Text('Error: Missing service request data'),
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
                                              "Please provide a star rating.",
                                        );
                                        return;
                                      }

                                      showLoadingDialog(
                                        context,
                                        "Updating your review...",
                                      );

                                      try {
                                        final success = await controller
                                            .submitUpdateReview();

                                        if (context.mounted) {
                                          Navigator.of(
                                            context,
                                          ).pop(); // Close loading
                                        }

                                        if (success && context.mounted) {
                                          showSuccessDialog(
                                            context,
                                            title: "Review Updated!",
                                            message:
                                                "Your review has been successfully updated.",
                                            primaryButtonText: "Back",
                                            onPrimary: () {
                                              Navigator.of(context)
                                                ..pop() // Close success
                                                ..pop(true); // Back to detail
                                            },
                                          );
                                        } else if (context.mounted) {
                                          showErrorDialog(
                                            context,
                                            title: "Update Failed",
                                            message: "Something went wrong.",
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          Navigator.of(
                                            context,
                                          ).pop(); // Close loading
                                        }
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
                                    child: const Text('Update'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
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
              label: const Text(
                'Add photo',
                style: TextStyle(
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

        if (controller.existingPhotoUrls.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text(
            'Current Photos',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          buildExistingPhotosGrid(controller),
        ],

        if (controller.uploadedImages.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text(
            'New Photos',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          PhotoPreviewList(
            images: controller.uploadedImages,
            onRemove: controller.removePhoto,
          ),
        ],
        const SizedBox(height: 10),
      ],
    );
  }

  Widget buildExistingPhotosGrid(RatingReviewController controller) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(controller.existingPhotoUrls.length, (index) {
          final String photoUrl = controller.existingPhotoUrls[index];

          return SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image(
                    image: photoUrl.getImageProvider(),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[300],
                        child: Image(
                          image: NetworkImage(
                            FirebaseImageService.placeholderUrl,
                          ),
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      controller.removeExistingPhoto(index);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
