import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controller/service.dart';
import '../../model/databaseModel.dart';
import '../../shared/fullScreenImage.dart';
import '../../shared/helper.dart';
import 'editService.dart';

class EmpServiceDetailScreen extends StatefulWidget {
  final ServiceModel service;
  final VoidCallback onDataChanged;
  final bool isAdmin;

  const EmpServiceDetailScreen({
    required this.service,
    required this.onDataChanged,
    required this.isAdmin,
    super.key,
  });

  @override
  State<EmpServiceDetailScreen> createState() => EmpServiceDetailScreenState();
}

class EmpServiceDetailScreenState extends State<EmpServiceDetailScreen> {
  late final ServiceModel service;
  final ServiceController serviceController = ServiceController();
  late Future<List<ServicePictureModel>> picturesFuture;
  late Future<List<String>> assignedHandymenFuture;

  List<String> imagePaths = [];
  final String imageBasePath = 'assets/services';

  @override
  void initState() {
    super.initState();
    service = widget.service;
    loadServiceData();
  }

  void loadServiceData() {
    setState(() {
      picturesFuture = serviceController.getPicturesForService(
        service.serviceID,
      );
      assignedHandymenFuture = serviceController.getAssignedHandymanNames(
        service.serviceID,
      );
    });
  }

  void openGallery(BuildContext context, int index) {
    if (imagePaths.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenGalleryViewer(
          imagePaths: imagePaths,
          initialIndex: index,
          basePath: imageBasePath,
        ),
      ),
    );
  }

  void navigateToModify() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmpModifyServiceScreen(
          service: service,
          onServiceUpdated: () {
            setState(() {});
            widget.onDataChanged();
            Navigator.of(context).pop();
          },
        ),
      ),
    ).then((_) {
      refreshServiceData();
    });
  }

  Future<void> refreshServiceData() async {
    try {
      final services = await serviceController.empGetAllServices();
      final updatedService = services.firstWhere(
        (s) => s.serviceID == widget.service.serviceID,
        orElse: () => widget.service,
      );
      setState(() {
        service = updatedService;
      });
      loadServiceData();
    } catch (e) {
      print("Error refreshing service: $e");
    }
  }

  void handleDelete() {
    showConfirmDialog(
      context,
      title: 'Are you sure?',
      message:
          'Do you confirm to delete service? This action will set status to "inactive" and hide it from customers.',
      affirmativeText: 'Delete',
      negativeText: 'Cancel',
      onAffirmative: () async {
        try {
          showLoadingDialog(context, 'Deleting...');
          await serviceController.deleteService(service.serviceID);

          if (mounted) Navigator.of(context).pop();

          widget.onDataChanged();
          if (mounted) {
            showSuccessDialog(
              context,
              title: 'Successful',
              message: 'The service has been set to inactive.',
              primaryButtonText: 'OK',
              onPrimary: () {
                Navigator.of(context).pop(); // Pop success dialog
                Navigator.of(context).pop(); // Pop detail page
              },
            );
          }
        } catch (e) {
          if (mounted) Navigator.of(context).pop();
          if (mounted) {
            showErrorDialog(
              context,
              title: 'Error',
              message: 'Failed to delete service: $e',
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text(
          'Service Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildDetailRow('Service ID', service.serviceID),
              buildDetailRow('Service Name', service.serviceName),
              buildSectionTitle('Photos'),
              buildPhotosSection(),
              const SizedBox(height: 16),
              buildDetailRow('Service Duration', service.serviceDuration),
              buildDetailRow(
                'Service Price (RM / hour)',
                service.servicePrice?.toStringAsFixed(2) ?? 'N/A',
              ),
              buildSectionTitle('Description'),
              Text(
                service.serviceDesc,
                textAlign: TextAlign.justify,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              buildDetailRow(
                'Service Status',
                capitalizeFirst(service.serviceStatus),
                valueColor: getStatusColor(service.serviceStatus),
              ),
              buildDetailRow(
                'Service Created At',
                DateFormat('yyyy-MM-dd').format(service.serviceCreatedAt),
              ),
              buildSectionTitle('Handyman Assigned'),
              buildHandymenSection(),
              const SizedBox(height: 32),
              if (widget.isAdmin) buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDetailRow(String title, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
            style: TextStyle(
              color: valueColor ?? Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      ),
    );
  }

  Widget buildPhotosSection() {
    return FutureBuilder<List<ServicePictureModel>>(
      future: picturesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Text('Error loading photos');
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No photos available');
        }

        final pictures = snapshot.data!;
        imagePaths = pictures.map((p) => p.picName).toList();

        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: pictures.length,
            itemBuilder: (context, index) {
              final picture = pictures[index];
              final String assetPath =
                  '$imageBasePath/${picture.picName.trim().toLowerCase()}';

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () => openGallery(context, index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.asset(
                      assetPath,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey.shade400,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget buildHandymenSection() {
    return FutureBuilder<List<String>>(
      future: assignedHandymenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text(
            'Error loading handymen',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text(
            'No handymen assigned',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          );
        }
        return Text(
          snapshot.data!.join(', '),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }

  Widget buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: navigateToModify,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Modify', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: handleDelete,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
