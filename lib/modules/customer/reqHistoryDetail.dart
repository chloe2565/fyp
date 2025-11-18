import 'package:flutter/material.dart';
import 'package:fyp/service/image_service.dart';
import 'package:intl/intl.dart';
import '../../controller/serviceRequest.dart';
import '../../model/serviceRequestViewModel.dart';
import '../../model/databaseModel.dart';
import '../../shared/fullScreenImage.dart';
import '../../shared/helper.dart';
import 'billDetail.dart';
import 'serviceReqMap.dart';

class RequestHistoryDetailScreen extends StatelessWidget {
  final String reqID;
  final ServiceRequestController controller;

  const RequestHistoryDetailScreen({
    super.key,
    required this.reqID,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final RequestViewModel? viewModel = controller.getRequestById(reqID);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Request Details'),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            titleTextStyle: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            centerTitle: true,
          ),
          backgroundColor: Colors.grey[50],
          body: viewModel == null
              ? const Center(
                  child: Text(
                    'Service request not found.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : buildDetailsBody(context, viewModel),
        );
      },
    );
  }

  Widget buildDetailsBody(BuildContext context, RequestViewModel viewModel) {
    final model = viewModel.requestModel;
    final icon = ServiceHelper.getIconForService(viewModel.title);
    final bgColor = ServiceHelper.getColorForService(viewModel.title);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Header Card
          buildServiceHeaderCard(context, viewModel, icon, bgColor),
          const SizedBox(height: 12),

          // Status Card
          buildStatusCard(context, viewModel),
          const SizedBox(height: 12),

          // Booking Details Card
          buildBookingDetailsCard(context, viewModel),
          const SizedBox(height: 12),

          // Location Card
          buildLocationCard(context, model.reqAddress),
          const SizedBox(height: 12),

          // Photos Card
          if (model.reqPicName.isNotEmpty)
            buildPhotosCard(context, model.reqPicName),
          if (model.reqPicName.isNotEmpty) const SizedBox(height: 12),

          // Description Card
          buildDescriptionCard(context, model.reqDesc, model.reqRemark),
          const SizedBox(height: 12),

          // Billing Card (only for completed requests that require payment)
          if (viewModel.reqStatus.toLowerCase() == 'completed' &&
              viewModel.amountToPay != null)
            buildBillingCard(context, viewModel),
          if (viewModel.reqStatus.toLowerCase() == 'completed' &&
              viewModel.amountToPay != null)
            const SizedBox(height: 12),

          // Action Buttons
          ...buildBottomActions(context, viewModel, controller),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget buildServiceHeaderCard(
    BuildContext context,
    RequestViewModel viewModel,
    IconData icon,
    Color bgColor,
  ) {
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
                  viewModel.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Request ID: ${viewModel.reqID}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatusCard(BuildContext context, RequestViewModel viewModel) {
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
          Icon(
            Icons.info_outline,
            color: getStatusColor(viewModel.reqStatus),
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Service Request Status: ',
            style: TextStyle(fontSize: 15, color: Colors.grey[700]),
          ),
          Text(
            viewModel.reqStatus,
            style: TextStyle(
              color: getStatusColor(viewModel.reqStatus),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBookingDetailsCard(
    BuildContext context,
    RequestViewModel viewModel,
  ) {
    final model = viewModel.requestModel;
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
            'Service Reqeust Booking Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          buildInfoRow(
            Icons.calendar_today,
            'Service Request Scheduled Date',
            DateFormat('MMMM dd, yyyy').format(viewModel.scheduledDateTime),
          ),
          const SizedBox(height: 12),
          buildInfoRow(
            Icons.access_time,
            'Service Request Scheduled Time',
            DateFormat('hh:mm a').format(viewModel.scheduledDateTime),
          ),
          const SizedBox(height: 12),
          buildInfoRow(
            Icons.person_outline,
            'Handyman Assigned',
            viewModel.handymanName.isNotEmpty
                ? viewModel.handymanName
                : 'Not Assigned',
          ),
          const SizedBox(height: 12),
          buildInfoRow(
            Icons.schedule,
            'Service Request Created At',
            DateFormat('MMM dd, yyyy hh:mm a').format(model.reqDateTime),
          ),
        ],
      ),
    );
  }

  Widget buildLocationCard(BuildContext context, String address) {
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
                  'Service Request Location',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPhotosCard(BuildContext context, List<String> photoUrls) {
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
            'Service Request Photos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photoUrls.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final String photoUrl = photoUrls[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenGalleryViewer(
                          imagePaths: photoUrls,
                          initialIndex: index,
                          basePath: null,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image(
                      image: photoUrl.getImageProvider(),
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 100,
                          width: 100,
                          color: Colors.grey[200],
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDescriptionCard(
    BuildContext context,
    String description,
    String? remark,
  ) {
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
            'Service Request Description',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          if (remark != null && remark.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Additional Remarks',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              remark,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildBillingCard(BuildContext context, RequestViewModel viewModel) {
    final isPaid = viewModel.paymentStatus?.toLowerCase() == 'paid';

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Billing Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isPaid ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  viewModel.paymentStatus ?? 'Pending',
                  style: TextStyle(
                    color: isPaid ? Colors.green[700] : Colors.orange[700],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          buildInfoRow(
            Icons.payments_outlined,
            'Amount',
            viewModel.amountToPay ?? 'N/A',
          ),
          const SizedBox(height: 12),
          if (viewModel.payDueDate != null)
            buildInfoRow(
              Icons.event_outlined,
              isPaid ? 'Paid On' : 'Due Date',
              isPaid
                  ? (viewModel.paymentCreatedAt ?? viewModel.payDueDate!)
                  : viewModel.payDueDate!,
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                // Fetch the billing model and navigate to bill detail
                final billingModel = await fetchBillingModel(viewModel.reqID);
                if (billingModel != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BillDetailScreen(billingModel),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.receipt_long, size: 20),
              label: const Text('View Bill Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPaid
                    ? Colors.green[600]
                    : Colors.orange[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<BillingModel?> fetchBillingModel(String reqID) async {
    try {
      final billingMap = await controller.serviceRequest
          .fetchBillingInfo([reqID]);
      return billingMap[reqID];
    } catch (e) {
      print('Error fetching billing model: $e');
      return null;
    }
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

  List<Widget> buildBottomActions(
    BuildContext context,
    RequestViewModel viewModel,
    ServiceRequestController controller,
  ) {
    final status = viewModel.reqStatus.toLowerCase();
    final now = DateTime.now();
    final scheduledDate = DateUtils.dateOnly(viewModel.scheduledDateTime);
    final today = DateUtils.dateOnly(now);
    final differenceInDays = scheduledDate.difference(today).inDays;

    List<Widget> actions = [];

    // View map
    if (status == 'departed') {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ServiceReqMapScreen(reqID: viewModel.reqID),
                ),
              );
            },
            icon: const Icon(Icons.map, size: 20),
            label: const Text('Track Handyman'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      );
      actions.add(const SizedBox(height: 12));
    }

    // Reschedule and cancel button
    if ((status == 'pending' || status == 'confirmed') &&
        differenceInDays >= 3) {
      actions.add(
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => controller.rescheduleRequest(viewModel.reqID),
                icon: const Icon(Icons.schedule, size: 18),
                label: const Text('Reschedule'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  showCancelRequestDialog(
                    context,
                    reqID: viewModel.reqID,
                    onConfirmCancel: controller.cancelRequest,
                    onSuccess: () {
                      Navigator.of(context).pop();
                    },
                  );
                },
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return actions;
  }
}
