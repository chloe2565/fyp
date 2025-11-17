import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controller/service.dart';
import '../../model/databaseModel.dart';
import '../../service/image_service.dart';
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
  late ServiceModel service;
  final ServiceController serviceController = ServiceController();
  late Future<List<ServicePictureModel>> picturesFuture;
  late Future<List<String>> assignedHandymenFuture;

  List<String> imagePaths = [];

  @override
  void initState() {
    super.initState();
    service = widget.service;
    loadServiceData();
  }

  void loadServiceData() {
    if (mounted) {
      setState(() {
        picturesFuture = serviceController.getPicturesForService(
          service.serviceID,
        );
        assignedHandymenFuture = serviceController.getAssignedHandymanNames(
          service.serviceID,
        );
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

  void navigateToModify() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmpModifyServiceScreen(
          service: service,
          onServiceUpdated: () {
            if (mounted) {
              setState(() {});
              widget.onDataChanged();
            }
            Navigator.of(context).pop();
          },
        ),
      ),
    ).then((_) {
      if (mounted) {
        refreshServiceData();
      }
    });
  }

  Future<void> refreshServiceData() async {
    try {
      final services = await serviceController.empGetAllServices();
      final updatedService = services.firstWhere(
        (s) => s.serviceID == widget.service.serviceID,
        orElse: () => widget.service,
      );
      if (mounted) {
        setState(() {
          service = updatedService;
        });
        loadServiceData();
      }
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
        title: const Text('Service Details'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Header Card
            buildServiceHeaderCard(context),
            const SizedBox(height: 12),

            // Status Card
            buildStatusCard(context),
            const SizedBox(height: 12),

            // Service Details Card
            buildServiceDetailsCard(context),
            const SizedBox(height: 12),

            // Photos Card
            buildPhotosCard(context),
            const SizedBox(height: 12),

            // Description Card
            buildDescriptionCard(context),
            const SizedBox(height: 12),

            // Handyman Assigned Card
            buildHandymenCard(context),
            const SizedBox(height: 12),

            // Action Buttons
            if (widget.isAdmin) buildActionButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildServiceHeaderCard(BuildContext context) {
    final icon = ServiceHelper.getIconForService(service.serviceName);
    final bgColor = ServiceHelper.getColorForService(service.serviceName);

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
                  service.serviceName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildServiceDetailsCard(BuildContext context) {
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
            Icons.schedule,
            'Service Created At',
            DateFormat('MMMM dd, yyyy').format(service.serviceCreatedAt),
          ),
          const SizedBox(height: 12),
          buildInfoRow(
            Icons.access_time,
            'Service Duration',
            service.serviceDuration,
          ),
          const SizedBox(height: 12),
          buildInfoRow(
            Icons.attach_money,
            'Service Price',
            'RM ${service.servicePrice?.toStringAsFixed(2) ?? 'N/A'} / hour',
          ),
        ],
      ),
    );
  }

  Widget buildPhotosCard(BuildContext context) {
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
            'Service Photos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<ServicePictureModel>>(
            future: picturesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Text(
                  'Error loading photos: ${snapshot.error}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text(
                  'No photos available',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                );
              }

              final pictures = snapshot.data!;
              imagePaths = pictures.map((p) => p.picName).toList();

              return SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: pictures.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final picture = pictures[index];
                    final String imageUrl = picture.picName;

                    return GestureDetector(
                      onTap: () => openGallery(context, index),
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
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildDescriptionCard(BuildContext context) {
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
            'Service Description',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            service.serviceDesc,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatusCard(BuildContext context) {
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
              Icon(
                Icons.info_outline,
                color: getStatusColor(service.serviceStatus),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Service Status: ',
                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
              ),
              Text(
                capitalizeFirst(service.serviceStatus),
                style: TextStyle(
                  color: getStatusColor(service.serviceStatus),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildHandymenCard(BuildContext context) {
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
                'Handyman Assigned',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<String>>(
            future: assignedHandymenFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(),
                );
              }
              if (snapshot.hasError) {
                return Text(
                  'Error loading handymen',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 14,
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text(
                  'No handymen assigned',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: snapshot.data!.map((name) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 18, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
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

  Widget buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: navigateToModify,
            icon: const Icon(Icons.edit, size: 20),
            label: const Text('Modify'),
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
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: handleDelete,
            icon: const Icon(Icons.delete_outline, size: 20),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
