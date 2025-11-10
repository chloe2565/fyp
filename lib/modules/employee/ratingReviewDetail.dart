import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controller/ratingReview.dart';
import '../../model/databaseModel.dart';
import '../../service/user.dart';
import '../../service/image_service.dart';
import '../../shared/fullScreenImage.dart';
import '../../shared/helper.dart';

class EmpRatingReviewDetailScreen extends StatefulWidget {
  final Map<String, dynamic> reviewData;
  final RatingReviewController controller;
  final VoidCallback onReplyPosted;

  const EmpRatingReviewDetailScreen({
    super.key,
    required this.reviewData,
    required this.controller,
    required this.onReplyPosted,
  });

  @override
  State<EmpRatingReviewDetailScreen> createState() =>
      EmpRatingReviewDetailScreenState();
}

class EmpRatingReviewDetailScreenState
    extends State<EmpRatingReviewDetailScreen> {
  final UserService userService = UserService();
  bool isAdmin = false;
  bool isLoadingRole = true;
  bool isSubmittingReply = false;

  late RatingReviewModel review;
  late ServiceRequestModel request;
  late List<String> imagePaths;

  static final dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  @override
  void initState() {
    super.initState();
    review = widget.reviewData['review'] as RatingReviewModel;
    request = widget.reviewData['request'] as ServiceRequestModel;
    imagePaths = review.ratingPicName ?? [];

    loadEmployeeRole();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadReviewDetails(request.reqID);
    });
  }

  Future<void> loadEmployeeRole() async {
    final empInfo = await userService.getCurrentEmployeeInfo();
    if (mounted) {
      setState(() {
        if (empInfo != null && empInfo['empType'] == 'admin') {
          isAdmin = true;
        }
        isLoadingRole = false;
      });
    }
  }

  void openGallery(BuildContext context, int index) {
    if (imagePaths.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenGalleryViewer(
          imagePaths: imagePaths,
          initialIndex: index,
        ),
      ),
    );
  }

  void showReplyDialog(
    RatingReviewController controller, {
    ReviewReplyModel? existingReply,
  }) {
    final bool isEditing = existingReply != null;
    final TextEditingController replyController = TextEditingController(
      text: isEditing ? existingReply.replyText : '',
    );
    final GlobalKey<FormState> dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: dialogFormKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing
                                ? 'Edit Reply'
                                : 'Reply Rating and Review',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Review',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            review.ratingText,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: replyController,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlignVertical: TextAlignVertical.top,
                            decoration: InputDecoration(
                              labelText: isEditing
                                  ? 'Edit your reply'
                                  : 'Enter reply',
                              alignLabelWithHint: true,
                              border: const OutlineInputBorder(),
                            ),
                            maxLines: 4,
                            validator: (value) =>
                                Validator.validateNotEmpty(value, 'Reply'),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: isSubmittingReply
                                      ? null
                                      : () {
                                          if (dialogFormKey.currentState!
                                              .validate()) {
                                            submitReply(
                                              controller,
                                              replyController.text,
                                              setDialogState,
                                              isEditing: isEditing,
                                            );
                                          }
                                        },
                                  child: Text(
                                    isEditing ? 'Update' : 'Submit',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: isSubmittingReply
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> submitReply(
    RatingReviewController controller,
    String replyText,
    StateSetter setDialogState, {
    required bool isEditing,
  }) async {
    // Close reply dialog
    Navigator.of(context).pop();

    BuildContext? dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        dialogContext = ctx;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  isEditing
                      ? 'Updating your reply...'
                      : 'Posting your reply...',
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      if (isEditing && controller.detailViewModel?.reply?.replyID != null) {
        await controller.updateReply(
          controller.detailViewModel!.reply!.replyID,
          replyText,
        );
      } else {
        await controller.submitReply(review.rateID, replyText);
      }

      if (!mounted) return;

      // Close loading dialog
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.of(dialogContext!).pop();
      }

      showSuccessDialog(
        context,
        title: "Success",
        message: isEditing
            ? "Your reply has been updated."
            : "Your reply has been posted.",
      );

      widget.onReplyPosted();
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.of(dialogContext!).pop();
      }

      showErrorDialog(
        context,
        title: "Error",
        message: "Failed to ${isEditing ? 'update' : 'post'} reply: $e",
      );
    }
  }

  Future<void> deleteReply(
    RatingReviewController controller,
    String replyID,
  ) async {
    showConfirmDialog(
      context,
      title: 'Delete Reply',
      message: 'Are you sure you want to delete this reply?',
      affirmativeText: 'Delete',
      negativeText: 'Cancel',
      onAffirmative: () async {
        try {
          showLoadingDialog(context, 'Deleting...');
          await controller.deleteReply(replyID);

          if (mounted) {
            Navigator.of(context).pop(); // Close loading dialog
            showSuccessDialog(
              context,
              title: 'Successful',
              message: 'The reply has been deleted.',
              primaryButtonText: 'OK',
              onPrimary: () {
                Navigator.of(context).pop(); // Close success dialog
                widget.onReplyPosted();
              },
            );
          }
        } catch (e) {
          if (mounted) Navigator.of(context).pop();
          showErrorDialog(
            context,
            title: 'Error',
            message: 'Failed to delete reply: $e',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            leading: const BackButton(color: Colors.black),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: const Text(
              'Rate and Review Details',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
          ),
          body: buildBody(widget.controller),
        );
      },
    );
  }

  Widget buildBody(RatingReviewController controller) {
    if (controller.detailIsLoading || isLoadingRole) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.detailError != null) {
      return Center(child: Text(controller.detailError!));
    }

    if (controller.detailViewModel == null) {
      return const Center(child: Text("Review details not found."));
    }

    final ReviewReplyModel? reply = controller.detailViewModel!.reply;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildDetailItem('Rating ID', review.rateID),
          buildDetailItem('Service Request ID', request.reqID),
          buildDetailItem('Handyman ID', request.handymanID),
          buildDetailItem(
            'Rate and Review Created At',
            dateTimeFormat.format(review.ratingCreatedAt),
          ),
          buildRatingSection(review.ratingNum),
          buildSectionTitle('Photos'),
          buildPhotosSection(),
          buildSectionTitle('Review'),
          buildReviewTextSection(review.ratingText),

          buildSectionTitle('Admin Reply'),
          buildReplySection(reply),

          const SizedBox(height: 32),
          buildReplyButton(controller, reply),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget buildDetailItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        title,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      ),
    );
  }

  Widget buildRatingSection(double rating) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rating',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildPhotosSection() {
    if (imagePaths.isEmpty) {
      return const Text(
        'No photos provided.',
        style: TextStyle(color: Colors.black54, fontSize: 15),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imagePaths.length,
        itemBuilder: (context, index) {
          final imageUrl = imagePaths[index];

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => openGallery(context, index),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: imageUrl.toNetworkImage(
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildReviewTextSection(String reviewText) {
    return Text(
      reviewText.isEmpty ? "No review text provided." : reviewText,
      textAlign: TextAlign.justify,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
    );
  }

  Widget buildReplySection(ReviewReplyModel? reply) {
    if (reply == null) {
      return const Text(
        'No reply has been posted yet.',
        style: TextStyle(color: Colors.black54, fontSize: 15),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reply.replyText,
            textAlign: TextAlign.justify,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Replied on: ${dateTimeFormat.format(reply.replyCreatedAt)}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildReplyButton(
    RatingReviewController controller,
    ReviewReplyModel? reply,
  ) {
    if (isLoadingRole || controller.detailIsLoading || !isAdmin) {
      return const SizedBox.shrink();
    }

    if (reply == null) {
      // Reply button
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => showReplyDialog(controller),
          child: const Text('Reply', style: TextStyle(fontSize: 16)),
        ),
      );
    } else {
      // Edit reply and delete reply button
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () =>
                  showReplyDialog(controller, existingReply: reply),
              child: const Text('Edit Reply', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => deleteReply(controller, reply.replyID),
              child: const Text('Delete Reply', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      );
    }
  }
}
