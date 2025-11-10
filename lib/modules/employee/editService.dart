import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../controller/service.dart';
import '../../model/databaseModel.dart';
import '../../service/image_service.dart';
import '../../service/servicePicture.dart';
import '../../shared/dropdownMultiOption.dart';
import '../../shared/dropdownSingleOption.dart';
import '../../shared/helper.dart';

class EmpModifyServiceScreen extends StatefulWidget {
  final ServiceModel service;
  final VoidCallback onServiceUpdated;

  const EmpModifyServiceScreen({
    super.key,
    required this.service,
    required this.onServiceUpdated,
  });

  @override
  State<EmpModifyServiceScreen> createState() => EmpModifyServiceScreenState();
}

class EmpModifyServiceScreenState extends State<EmpModifyServiceScreen> {
  final formKey = GlobalKey<FormState>();
  final GlobalKey<CustomDropdownMultiState> handymanDropdownKey = GlobalKey();
  final ServiceController controller = ServiceController();
  final ServicePictureService pictureService = ServicePictureService();
  final TextEditingController serviceIDController = TextEditingController();
  final TextEditingController serviceNameController = TextEditingController();
  final TextEditingController minDurationController = TextEditingController();
  final TextEditingController maxDurationController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController createdAtController = TextEditingController();

  String serviceStatus = 'active';
  final List<File> selectedImages = [];
  final ImagePicker picker = ImagePicker();
  List<ServicePictureModel> existingPictures = [];
  List<String> removedPicUrls =
      []; // Changed from removedPicNames to removedPicUrls
  late Future<Map<String, String>> handymenFuture;
  Map<String, String> allHandymenMap = {};
  Map<String, String> selectedHandymen = {};
  bool isLoading = false;
  bool isPageLoading = true;

  @override
  void initState() {
    super.initState();
    handymenFuture = controller.getAllHandymenMap();
    initializeFields();
  }

  Future<void> initializeFields() async {
    setState(() => isPageLoading = true);
    final service = widget.service;

    try {
      serviceIDController.text = service.serviceID;
      serviceNameController.text = service.serviceName;
      priceController.text = service.servicePrice?.toString() ?? '';
      descriptionController.text = service.serviceDesc;
      createdAtController.text = DateFormat(
        'yyyy-MM-dd',
      ).format(service.serviceCreatedAt);
      serviceStatus = service.serviceStatus;

      final durationParts = service.serviceDuration.split(' to ');
      if (durationParts.length == 2) {
        minDurationController.text = durationParts[0].replaceAll(
          RegExp(r'[^0-9]'),
          '',
        );
        maxDurationController.text = durationParts[1].replaceAll(
          RegExp(r'[^0-9]'),
          '',
        );
      }

      selectedHandymen = await controller.getAssignedHandymenMap(
        service.serviceID,
      );
      allHandymenMap = await handymenFuture;
      existingPictures = await pictureService.getPicturesForService(
        service.serviceID,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => isPageLoading = false);
      }
    }
  }

  @override
  void dispose() {
    serviceIDController.dispose();
    serviceNameController.dispose();
    minDurationController.dispose();
    maxDurationController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    createdAtController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final List<XFile> pickedFiles = await picker.pickMultiImage(
      imageQuality: 80,
    );
    setState(() {
      selectedImages.addAll(pickedFiles.map((x) => File(x.path)));
    });
  }

  void removeExistingImage(String picUrl) {
    setState(() {
      existingPictures.removeWhere((pic) => pic.picName == picUrl);
      removedPicUrls.add(picUrl);
    });
  }

  void removeNewImage(int index) {
    setState(() => selectedImages.removeAt(index));
  }

  Future<void> submitForm() async {
    if (!formKey.currentState!.validate() || isLoading) return;

    final dropdownState = handymanDropdownKey.currentState;
    if (dropdownState != null) {
      dropdownState.validate();
      if (dropdownState.errorText != null) {
        showErrorDialog(
          context,
          title: 'Handyman Required',
          message: dropdownState.errorText!,
        );
        return;
      }
    }

    if (existingPictures.isEmpty && selectedImages.isEmpty) {
      showErrorDialog(
        context,
        title: 'Photo Required',
        message: 'At least one photo is required',
      );
      return;
    }

    setState(() => isLoading = true);
    showLoadingDialog(context, 'Updating service and images…');

    try {
      final service = ServiceModel(
        serviceID: serviceIDController.text,
        serviceName: serviceNameController.text,
        serviceDesc: descriptionController.text,
        servicePrice: priceController.text.isEmpty
            ? null
            : double.tryParse(priceController.text),
        serviceDuration:
            '${minDurationController.text} to ${maxDurationController.text} hours',
        serviceStatus: serviceStatus,
        serviceCreatedAt: widget.service.serviceCreatedAt,
      );

      final handymanIDs = selectedHandymen.keys.toList();

      await controller.updateService(
        service,
        handymanIDs,
        selectedImages,
        removedPicUrls: removedPicUrls,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // close loading

      showSuccessDialog(
        context,
        title: 'Service Updated',
        message: 'The service has been updated successfully.',
        primaryButtonText: 'Back to Home',
        onPrimary: () {
          widget.onServiceUpdated();
          Navigator.of(context)
            ..pop() // close success
            ..pop(); // close edit screen
        },
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading
      showErrorDialog(context, title: 'Update Failed', message: e.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
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
          'Modify Service',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: isPageLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildLabel('Service ID'),
                    buildTextFormField(
                      controller: serviceIDController,
                      readOnly: true,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),

                    buildLabel('Service Name'),
                    buildTextFormField(
                      controller: serviceNameController,
                      validator: (value) =>
                          Validator.validateNotEmpty(value, 'Service name'),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Photos',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(width: 100),
                        Expanded(child: buildPhotoUploader()),
                      ],
                    ),
                    const SizedBox(height: 8),
                    buildPhotoPreview(),
                    const SizedBox(height: 16),

                    const Text(
                      'Service Duration (hours)',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: buildTextFormField(
                            controller: minDurationController,
                            label: 'min',
                            keyboardType: TextInputType.number,
                            validator: (_) => Validator.validateDuration(
                              minDurationController.text,
                              maxDurationController.text,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('To'),
                        ),
                        Expanded(
                          child: buildTextFormField(
                            controller: maxDurationController,
                            label: 'max',
                            keyboardType: TextInputType.number,
                            validator: (_) => Validator.validateDuration(
                              minDurationController.text,
                              maxDurationController.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    buildLabel('Service Price (RM / hour)'),
                    buildTextFormField(
                      controller: priceController,
                      hint: 'Leave empty if N/A',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    buildLabel('Description'),
                    buildTextFormField(
                      controller: descriptionController,
                      maxLines: 4,
                      validator: (value) =>
                          Validator.validateNotEmpty(value, 'Description'),
                    ),
                    const SizedBox(height: 16),

                    buildLabel('Service Status'),
                    CustomDropdownSingle(
                      value: serviceStatus,
                      items: const ['active', 'inactive'],
                      hint: 'Select status',
                      onChanged: (value) {
                        setState(() => serviceStatus = value!);
                      },
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Select a status' : null,
                    ),
                    const SizedBox(height: 16),

                    buildLabel('Service Created At'),
                    buildTextFormField(
                      controller: createdAtController,
                      readOnly: true,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),

                    buildLabel('Handyman Assigned'),
                    FutureBuilder<Map<String, String>>(
                      future: handymenFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return Text(
                            'Failed to load handymen',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          );
                        }
                        return CustomDropdownMulti(
                          allItems: snapshot.data!,
                          selectedItems: selectedHandymen,
                          hint: 'Select handymen (multiple)',
                          showSubtitle: true,
                          onChanged: (selected) {
                            setState(() => selectedHandymen = selected);
                          },
                          validator: (map) =>
                              map!.isEmpty ? 'Select at least one' : null,
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading ? null : submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondary,
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildLabel(String text) {
    return Text(text, style: const TextStyle(color: Colors.grey, fontSize: 14));
  }

  Widget buildPhotoUploader() {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : pickImage,
      icon: const Icon(Icons.upload_file_outlined, size: 18),
      label: const Text('Upload photos'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey.shade700,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget buildTextFormField({
    required TextEditingController controller,
    String? label,
    String? hint,
    bool readOnly = false,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[buildLabel(label), const SizedBox(height: 4)],
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          onTap: onTap,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 12,
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  Widget buildPhotoPreview() {
    final allImages = [
      ...existingPictures.map(
        (pic) => {'type': 'existing', 'picUrl': pic.picName},
      ),
      ...selectedImages.asMap().entries.map(
        (e) => {'type': 'new', 'index': e.key, 'file': e.value},
      ),
    ];

    if (allImages.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allImages.map((item) {
        if (item['type'] == 'existing') {
          final picUrl = item['picUrl'] as String;
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: picUrl.toNetworkImage(
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => removeExistingImage(picUrl),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          final index = item['index'] as int;
          final file = item['file'] as File;
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  file,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => removeNewImage(index),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      }).toList(),
    );
  }
}
