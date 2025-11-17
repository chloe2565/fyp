import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controller/ratingReview.dart';
import '../../controller/user.dart';
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
  
  String? customerName;
  bool isLoadingCustomerName = false;
  UserController? userController;

  late RatingReviewModel review;
  late ServiceRequestModel request;
  late ServiceModel? service;
  late UserModel? handymanUser;
  late List<String> imagePaths;

  static final dateFormat = DateFormat('dd MMM yyyy');
  static final timeFormat = DateFormat('hh:mm a');
  static final dateTimeFormat = DateFormat('MMM dd, yyyy hh:mm a');

  @override
  void initState() {
    super.initState();
    review = widget.reviewData['review'] as RatingReviewModel;
    request = widget.reviewData['request'] as ServiceRequestModel;
    service = widget.reviewData['service'] as ServiceModel?;
    handymanUser = widget.reviewData['handymanUser'] as UserModel?;
    imagePaths = review.ratingPicName ?? [];
    
    userController = UserController(
      showErrorSnackBar: (error) => print('Error: $error'),
    );

    loadEmployeeRole();
    loadCustomerName();

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

  Future<void> loadCustomerName() async {
    if (!mounted) return;
    setState(() => isLoadingCustomerName = true);

    try {
      if (userController != null) {
        final name = await userController!.getCustomerNameByCustID(
          request.custID,
        );

        if (!mounted) return;
        setState(() {
          customerName = name;
          isLoadingCustomerName = false;
        });
      } else {
        if (!mounted) return;
        setState(() => isLoadingCustomerName = false);
      }
    } catch (e) {
      print('Error in loadCustomerName: $e');
      if (!mounted) return;
      setState(() {
        customerName = null;
        isLoadingCustomerName = false;
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
                                : 'Reply to Customer Review',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Customer Review',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              review.ratingText.isEmpty 
                                  ? 'No review text provided.'
                                  : review.ratingText,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                                fontStyle: FontStyle.italic,
                              ),
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
                                  : 'Write your reply',
                              alignLabelWithHint: true,
                              border: const OutlineInputBorder(),
                              hintText: 'Thank you for your feedback...',
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
            Navigator.of(context).pop();
            showSuccessDialog(
              context,
              title: 'Successful',
              message: 'The reply has been deleted.',
              primaryButtonText: 'OK',
              onPrimary: () {
                Navigator.of(context).pop();
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
              'Review Details',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
          ),
          backgroundColor: Colors.grey[50],
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
    final serviceName = service?.serviceName ?? 'Unknown Service';
    final icon = ServiceHelper.getIconForService(serviceName);
    final bgColor = ServiceHelper.getColorForService(serviceName);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Header Card
          buildServiceHeaderCard(serviceName, icon, bgColor),
          const SizedBox(height: 12),
          
          // Rating Card
          buildRatingCard(),
          const SizedBox(height: 12),
          
          // Service Details Card
          buildServiceDetailsCard(),
          const SizedBox(height: 12),
          
          // Location Card
          buildLocationCard(),
          const SizedBox(height: 12),
          
          // Photos Card
          if (imagePaths.isNotEmpty) ...[
            buildPhotosCard(),
            const SizedBox(height: 12),
          ],
          
          // Review Text Card
          buildReviewTextCard(),
          const SizedBox(height: 12),
          
          // Admin Reply Card
          buildAdminReplyCard(reply),
          const SizedBox(height: 24),
          
          // Action Buttons
          buildReplyButton(controller, reply),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget buildServiceHeaderCard(String serviceName, IconData icon, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.black, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customer Review',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRatingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Rating',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Star Rating Display
              ...List.generate(5, (index) {
                return Icon(
                  index < review.ratingNum.floor()
                      ? Icons.star
                      : (index < review.ratingNum
                          ? Icons.star_half
                          : Icons.star_border),
                  color: Colors.amber,
                  size: 32,
                );
              }),
              const SizedBox(width: 12),
              Text(
                review.ratingNum.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' / 5.0',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Reviewed on ${dateTimeFormat.format(review.ratingCreatedAt)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildServiceDetailsCard() {
    final handymanName = handymanUser?.userName ?? 'Not Assigned';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          buildInfoRow(
            Icons.person,
            'Customer',
            isLoadingCustomerName
                ? 'Loading...'
                : (customerName != null && customerName!.isNotEmpty
                      ? customerName!
                      : 'Unknown Customer'),
          ),
          const SizedBox(height: 12),
          buildInfoRow(
            Icons.handyman,
            'Handyman',
            handymanName.isNotEmpty
                ? capitalizeFirst(handymanName)
                : 'Not Assigned',
          ),
          const SizedBox(height: 12),
          buildInfoRow(
            Icons.calendar_today,
            'Service Date',
            dateFormat.format(request.scheduledDateTime),
          ),
          const SizedBox(height: 12),
          buildInfoRow(
            Icons.access_time,
            'Service Time',
            timeFormat.format(request.scheduledDateTime),
          ),
          const SizedBox(height: 12),
          buildInfoRow(
            Icons.info_outline,
            'Service Status',
            capitalizeFirst(request.reqStatus),
          ),
        ],
      ),
    );
  }

  Widget buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on, color: Colors.red[400], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service Location',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  request.reqAddress,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPhotosCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Customer Photos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${imagePaths.length} photo${imagePaths.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
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
          ),
        ],
      ),
    );
  }

  Widget buildReviewTextCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote, color: Colors.grey[400], size: 24),
              const SizedBox(width: 8),
              const Text(
                'Customer Review',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.ratingText.isEmpty
                ? "No review text provided."
                : review.ratingText,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAdminReplyCard(ReviewReplyModel? reply) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: reply != null ? Colors.blue[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: reply != null ? Colors.blue[200]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.reply,
                color: reply != null ? Colors.blue[700] : Colors.grey[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Admin Response',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: reply != null ? Colors.blue[900] : Colors.grey[700],
                ),
              ),
              const Spacer(),
              if (reply != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Replied',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (reply == null)
            Text(
              'No response has been posted yet.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            )
          else ...[
            Text(
              reply.replyText,
              textAlign: TextAlign.justify,
              style: TextStyle(
                color: Colors.blue[900],
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.blue[600]),
                const SizedBox(width: 4),
                Text(
                  'Replied on ${dateTimeFormat.format(reply.replyCreatedAt)}',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.reply, size: 20),
          label: const Text('Reply to Review', style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => showReplyDialog(controller),
        ),
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit Reply', style: TextStyle(fontSize: 16)),
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
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete Reply', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => deleteReply(controller, reply.replyID),
            ),
          ),
        ],
      );
    }
  }
}