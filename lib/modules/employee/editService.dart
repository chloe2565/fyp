import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../controller/service.dart';
import '../../model/databaseModel.dart';
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
  final ServiceController controller = ServiceController();
  final TextEditingController serviceIDController = TextEditingController();
  final TextEditingController serviceNameController = TextEditingController();
  final TextEditingController minDurationController = TextEditingController();
  final TextEditingController maxDurationController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController createdAtController = TextEditingController();
  final TextEditingController handymanController = TextEditingController();

  String serviceStatus = 'active';
  final List<File> selectedImages = [];
  final ImagePicker picker = ImagePicker();

  late Future<Map<String, String>> allHandymenFuture;
  Map<String, String> selectedHandymen = {};

  bool isLoading = false;
  bool isPageLoading = true;

  @override
  void initState() {
    super.initState();
    allHandymenFuture = controller.getAllHandymenMap();
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
      handymanController.text = selectedHandymen.values.join(', ');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
    setState(() => isPageLoading = false);
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
    handymanController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final List<XFile> pickedFiles = await picker.pickMultiImage(
      imageQuality: 80,
    );
    setState(() {
      selectedImages.addAll(pickedFiles.map((xfile) => File(xfile.path)));
    });
  }

  void removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  void showHandymanSelectDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Assign Handymen'),
              content: SizedBox(
                width: double.maxFinite,
                child: FutureBuilder<Map<String, String>>(
                  future: allHandymenFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Error loading handymen'),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No handymen found'));
                    }

                    final allHandymenMap = snapshot.data!;
                    final handymanIDs = allHandymenMap.keys.toList();
                    final userNames = allHandymenMap.values.toList();

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: allHandymenMap.length,
                      itemBuilder: (context, index) {
                        final handymanID = handymanIDs[index];
                        final userName = userNames[index];
                        final isSelected = selectedHandymen.containsKey(
                          handymanID,
                        );

                        return CheckboxListTile(
                          title: Text(userName),
                          subtitle: Text(handymanID),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                selectedHandymen[handymanID] = userName;
                              } else {
                                selectedHandymen.remove(handymanID);
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      handymanController.text = selectedHandymen.values.join(
                        ', ',
                      );
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> submitForm() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      final service = ServiceModel(
        serviceID: serviceIDController.text,
        serviceName: serviceNameController.text,
        serviceDesc: descriptionController.text,
        servicePrice: priceController.text.isEmpty
            ? null
            : double.tryParse(priceController.text),
        serviceDuration:
            '${minDurationController.text} to ${maxDurationController.text} minutes',
        serviceStatus: serviceStatus,
        serviceCreatedAt: widget.service.serviceCreatedAt,
      );

      final List<String> handymanIDs = selectedHandymen.keys.toList();

      await controller.updateService(service, handymanIDs, selectedImages);

      widget.onServiceUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating service: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        title: const Text(
          'Modify Service',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    buildTextFormField(
                      controller: serviceIDController,
                      label: 'Service ID',
                      readOnly: true,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    buildTextFormField(
                      controller: serviceNameController,
                      label: 'Service Name',
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 16),
                    buildSectionTitle('Add New Photos'),
                    buildPhotoUploader(),
                    PhotoPreviewList(
                      images: selectedImages,
                      onRemove: removeImage,
                    ),
                    const SizedBox(height: 16),
                    buildSectionTitle('Service Duration (minutes)'),
                    Row(
                      children: [
                        Expanded(
                          child: buildTextFormField(
                            controller: minDurationController,
                            label: 'min',
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                value!.isEmpty ? 'Required' : null,
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
                            validator: (value) =>
                                value!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    buildTextFormField(
                      controller: priceController,
                      label: 'Service Price (RM / hour)',
                      hint: 'Leave empty if N/A',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    buildTextFormField(
                      controller: descriptionController,
                      label: 'Description',
                      maxLines: 4,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a description' : null,
                    ),
                    const SizedBox(height: 16),
                    buildDropdownFormField(
                      label: 'Service Status',
                      value: serviceStatus,
                      items: ['active', 'inactive'],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => serviceStatus = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    buildTextFormField(
                      controller: createdAtController,
                      label: 'Service Created At',
                      readOnly: true,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    buildTextFormField(
                      controller: handymanController,
                      label: 'Handyman Assigned',
                      readOnly: true,
                      onTap: showHandymanSelectDialog,
                      suffixIcon: const Icon(Icons.add_circle_outline),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading ? null : submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
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
                              foregroundColor: Colors.grey.shade700,
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

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
    );
  }

  Widget buildPhotoUploader() {
    return OutlinedButton.icon(
      onPressed: pickImage,
      icon: const Icon(Icons.upload_file_outlined),
      label: const Text('Upload new photos'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey.shade700,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool readOnly = false,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Icon? suffixIcon,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle(label),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
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

  Widget buildDropdownFormField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle(label),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item.substring(0, 1).toUpperCase() + item.substring(1),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 12,
            ),
          ),
        ),
      ],
    );
  }
}
