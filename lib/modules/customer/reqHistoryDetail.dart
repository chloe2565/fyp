import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controller/serviceRequest.dart';
import '../../model/serviceRequestViewModel.dart';
import '../../shared/fullScreenImage.dart';
import '../../shared/helper.dart';
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
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            titleTextStyle: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            centerTitle: true,
          ),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildDetailItem(context, 'Service Request ID', viewModel.reqID),
          buildDetailItem(context, 'Service ID', model.serviceID),
          buildDetailItem(context, 'Customer ID', model.custID),
          buildDetailItem(
            context,
            'Photos',
            null,
            child: buildPhotos(model.reqPicName),
          ),
          buildDetailItem(context, 'Service Location', model.reqAddress),
          buildDetailItem(
            context,
            'Booking Date',
            DateFormat('yyyy-MM-dd').format(viewModel.scheduledDateTime),
          ),
          buildDetailItem(
            context,
            'Booking Time',
            DateFormat('HH:mm:ss').format(viewModel.scheduledDateTime),
          ),
          buildDetailItem(context, 'Description', model.reqDesc),
          if (model.reqRemark != null && model.reqRemark!.isNotEmpty)
            buildDetailItem(context, 'Additional Remark', model.reqRemark!),
          buildDetailItem(
            context,
            'Service Request Status',
            null,
            child: Text(
              viewModel.reqStatus,
              style: TextStyle(
                color: getStatusColor(viewModel.reqStatus),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          buildDetailItem(
            context,
            'Service Request Created At',
            DateFormat('yyyy-MM-dd').format(model.reqDateTime),
          ),
          buildDetailItem(context, 'Handyman Assigned', viewModel.handymanName),
          const SizedBox(height: 20),
          ...buildBottomActions(context, viewModel, controller),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget buildDetailItem(
    BuildContext context,
    String label,
    String? value, {
    Widget? child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          child ??
              Text(
                value ?? '',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
        ],
      ),
    );
  }

  Widget buildPhotos(List<String> picNames) {
    if (picNames.isEmpty) {
      return const Text(
        'No photos uploaded.',
        style: TextStyle(fontSize: 16, color: Colors.black54),
      );
    }
    const String basePath = 'assets/requests';
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: picNames.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final picName = picNames[index].trim().toLowerCase();
          final imagePath = '$basePath/$picName';
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenGalleryViewer(
                    imagePaths: picNames,
                    initialIndex: index,
                    basePath: 'assets/requests',
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.asset(
                imagePath,
                height: 100,
                width: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 100,
                    width: 100,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
            ),
          );
        },
      ),
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
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ServiceReqMapScreen(reqID: viewModel.reqID),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('View Map'),
        ),
      );
    }

    // Reschedule and cancel button
    if ((status == 'pending' || status == 'confirmed') &&
        differenceInDays >= 3) {
      actions.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => controller.rescheduleRequest(viewModel.reqID),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Reschedule'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  controller.cancelRequest(viewModel.reqID);
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      );
    }
    return actions;
  }
}
