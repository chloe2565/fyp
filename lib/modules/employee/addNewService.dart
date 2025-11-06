import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../controller/service.dart';
import '../../model/databaseModel.dart';
import '../../shared/dropdownMultiOption.dart';
import '../../shared/dropdownSingleOption.dart';
import '../../shared/helper.dart';

class EmpAddServiceScreen extends StatefulWidget {
  final VoidCallback onServiceAdded;

  const EmpAddServiceScreen({super.key, required this.onServiceAdded});

  @override
  State<EmpAddServiceScreen> createState() => EmpAddServiceScreenState();
}

class EmpAddServiceScreenState extends State<EmpAddServiceScreen> {
  final formKey = GlobalKey<FormState>();
  final GlobalKey<CustomDropdownMultiState> handymanDropdownKey = GlobalKey();
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
  Map<String, String> allHandymenMap = {};
  Map<String, String> selectedHandymen = {};
  bool isLoading = false;
  bool isInitializing = true;
  bool dataLoadError = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    createdAtController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    initializeDataInBackground();
  }

  void initializeDataInBackground() async {
    try {
      await Future.wait([loadServiceID(), loadHandymenData()]);

      if (mounted) {
        setState(() => isInitializing = false);
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
      if (mounted) {
        setState(() => isInitializing = false);
      }
    }
  }

  Future<void> loadServiceID() async {
    try {
      final nextID = await controller.generateNextID().timeout(
        const Duration(seconds: 10),
        onTimeout: () => 'S0001',
      );
      serviceIDController.text = nextID;
    } catch (e) {
      debugPrint('Error loading service ID: $e');
      serviceIDController.text = 'S0001';
    }
  }

  Future<void> loadHandymenData() async {
    try {
      final handymenMap = await controller.getAllHandymenMap().timeout(
        const Duration(seconds: 10),
        onTimeout: () => <String, String>{},
      );
      allHandymenMap = handymenMap;
    } catch (e) {
      debugPrint('Error loading handymen: $e');
      dataLoadError = true;
      errorMessage = 'Could not load handymen list';
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
    handymanController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    try {
      final List<XFile> pickedFiles = await picker.pickMultiImage(
        imageQuality: 80,
      );
      if (mounted) {
        setState(() {
          selectedImages.addAll(pickedFiles.map((x) => File(x.path)));
          errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  void removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
      if (selectedImages.isEmpty) {
        errorMessage = 'At least one photo is required';
      }
    });
  }

  Future<void> submitForm() async {
    if (!formKey.currentState!.validate() || isLoading) return;

    final dropdownState = handymanDropdownKey.currentState;
    if (dropdownState != null) {
      dropdownState.validate();
      if (dropdownState.errorText != null) {
        return;
      }
    }

    if (selectedImages.isEmpty) {
      setState(() {
        errorMessage = 'At least one photo is required';
      });
      return;
    }

    showLoadingDialog(context, 'Adding service…');

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
        serviceCreatedAt: DateTime.now(),
      );

      final handymanIDs = selectedHandymen.keys.toList();

      await controller.addNewService(service, handymanIDs, selectedImages);
      if (!mounted) return;
      Navigator.of(context).pop();

      showSuccessDialog(
        context,
        title: 'Service Added',
        message: 'The new service has been created successfully.',
        primaryButtonText: 'Back to Home',
        onPrimary: () {
          widget.onServiceAdded();
          Navigator.of(context)
            ..pop() // close success dialog
            ..pop(); // close add-screen
        },
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading dialog

      showErrorDialog(
        context,
        title: 'Failed to Add Service',
        message: e.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: isLoading ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Service',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: isInitializing
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : Form(
              key: formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ----- Service ID -----
                    buildLabel('Service ID'),
                    buildTextFormField(
                      controller: serviceIDController,
                      readOnly: true,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),

                    // ----- Service Name -----
                    buildLabel('Service Name'),
                    buildTextFormField(
                      controller: serviceNameController,
                      validator: (value) =>
                          Validator.validateNotEmpty(value, 'Service name'),
                    ),
                    const SizedBox(height: 16),

                    // ----- Photos Section -----
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
                    if (selectedImages.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(
                          selectedImages.length,
                          (i) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  selectedImages[i],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedImages.removeAt(i);
                                      errorMessage = Validator.validatePhoto(
                                        selectedImages,
                                      );
                                    });
                                  },
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
                          ),
                        ),
                      ),
                    if (errorMessage != null && selectedImages.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // ----- Duration -----
                    const Text(
                      'Service Duration (Hours)',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: buildTextFormField(
                            controller: minDurationController,
                            label: 'Min',
                            keyboardType: TextInputType.number,
                            validator: (_) => Validator.validateDuration(
                              minDurationController.text,
                              maxDurationController.text,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('To'),
                        ),
                        Expanded(
                          child: buildTextFormField(
                            controller: maxDurationController,
                            label: 'Max',
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

                    // ----- Price -----
                    buildLabel('Service Price (RM / hour)'),
                    buildTextFormField(
                      controller: priceController,
                      hint: 'Leave empty if N/A',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ----- Description -----
                    buildLabel('Description'),
                    buildTextFormField(
                      controller: descriptionController,
                      maxLines: 4,
                      validator: (value) =>
                          Validator.validateNotEmpty(value, 'Description'),
                    ),
                    const SizedBox(height: 16),

                    // ----- Status -----
                    buildLabel('Service Status'),
                    CustomDropdownSingle(
                      value: serviceStatus,
                      items: ['active', 'inactive'],
                      hint: 'Select status',
                      onChanged: (value) {
                        setState(() {
                          serviceStatus = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a status';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ----- Created At -----
                    buildLabel('Service Created At'),
                    buildTextFormField(
                      controller: createdAtController,
                      readOnly: true,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),

                    // ----- Handyman -----
                    buildLabel('Handyman Assigned'),
                    CustomDropdownMulti(
                      key: handymanDropdownKey,
                      allItems: allHandymenMap,
                      selectedItems: selectedHandymen,
                      hint: 'Select handymen (multiple)',
                      showSubtitle: true,
                      onChanged: (selected) {
                        setState(() {
                          selectedHandymen = selected;
                          handymanController.text = selectedHandymen.values
                              .join(', ');
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select at least one handyman';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // ----- Submit / Cancel -----
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading ? null : submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
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
                                    'Submit',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.pop(context),
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
      onPressed: pickImage,
      icon: const Icon(Icons.upload_file_outlined, size: 18),
      label: const Text('Upload photo'),
      style: OutlinedButton.styleFrom(
        textStyle: TextStyle(
          color: Colors.black,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
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
        if (label != null) ...[
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
        ],
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          onTap: onTap,
          style: TextStyle(
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
}
