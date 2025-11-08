import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controller/serviceRequest.dart';
import '../../model/serviceRequestViewModel.dart';
import '../../shared/fullScreenImage.dart';
import '../../shared/helper.dart';
import '../../service/nlp_service.dart';
import 'handymanServiceReqMap.dart';
import 'providerServiceReqMap.dart';

class EmpRequestDetailScreen extends StatefulWidget {
  final String reqID;
  final ServiceRequestController controller;

  const EmpRequestDetailScreen({
    super.key,
    required this.reqID,
    required this.controller,
  });

  @override
  State<EmpRequestDetailScreen> createState() => EmpRequestDetailScreenState();
}

class EmpRequestDetailScreenState extends State<EmpRequestDetailScreen> {
  ComprehensiveAnalysis? nlpAnalysis;
  bool isLoadingAnalysis = false;

  @override
  void initState() {
    super.initState();
    loadNLPAnalysis();
  }

  Future<void> loadNLPAnalysis() async {
    setState(() => isLoadingAnalysis = true);

    final viewModel = widget.controller.getRequestById(widget.reqID);
    if (viewModel != null && viewModel.requestModel.reqDesc.isNotEmpty) {
      final analysis = await NLPService.analyzeDescription(
        viewModel.requestModel.reqDesc,
      );
      setState(() {
        nlpAnalysis = analysis;
        isLoadingAnalysis = false;
      });
    } else {
      setState(() => isLoadingAnalysis = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final RequestViewModel? viewModel = widget.controller.getRequestById(
          widget.reqID,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Request Details'),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          // NLP insight
          if (nlpAnalysis != null) buildNLPInsightsCard(),
          if (isLoadingAnalysis)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Analyzing request...'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

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
          buildDetailItem(
            context,
            'Additional Remark',
            (model.reqRemark != null && model.reqRemark!.isNotEmpty)
                ? model.reqRemark!
                : 'None',
          ),
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
          ...buildBottomActions(context, viewModel, widget.controller),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget buildNLPInsightsCard() {
    if (nlpAnalysis == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Insights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(height: 24, color: Colors.grey[400],),

            // Urgency Badge
            Row(
              children: [
                const Text(
                  'Urgency: ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: getUrgencyColor(nlpAnalysis!.urgency),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    nlpAnalysis!.urgency.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Recommendations
            if (nlpAnalysis!.recommendations.isNotEmpty) ...[
              const Text(
                'Recommendations:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...(nlpAnalysis!.recommendations.map(
                (rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(rec, style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              )),
            ],

            // Complexity
            if (nlpAnalysis!.insights['complexity'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Complexity: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    capitalizeFirst(nlpAnalysis!.insights['complexity']),
                    style: TextStyle(
                      color: getComplexityColor(
                        nlpAnalysis!.insights['complexity'],
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
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
          onPressed: () async {
            final String? empType = controller.currentEmployeeType;

            if (empType == 'handyman') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HandymanServiceReqMapScreen(reqID: viewModel.reqID),
                ),
              );
            } else if (empType == 'admin') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProviderServiceReqMapScreen(reqID: viewModel.reqID),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error: Could not determine user role.'),
                ),
              );
            }
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
