import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import '../../controller/serviceRequest.dart';
import '../../shared/helper.dart';

class ServiceRequestDetailsPage extends StatefulWidget {
  final String selectedLocation;
  final String serviceID;

  const ServiceRequestDetailsPage({
    super.key,
    this.selectedLocation = '18, Jalan Lembah Permai, Tanjung Bungah',
    required this.serviceID,
  });

  @override
  State<ServiceRequestDetailsPage> createState() =>
      ServiceRequestDetailsPageState();
}

class ServiceRequestDetailsPageState extends State<ServiceRequestDetailsPage> {
  final TextEditingController locationController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController remarkController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  List<File> uploadedImages = [];
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    locationController.text = widget.selectedLocation;
  }

  @override
  void dispose() {
    locationController.dispose();
    dateController.dispose();
    timeController.dispose();
    descriptionController.dispose();
    remarkController.dispose();
    super.dispose();
  }

  DateTime dateTimeFromTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF7643),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF7643),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dateController.text = DateFormat('dd MMM yyyy').format(selectedDate!);
      });
    }
  }

  Future<void> selectTime(BuildContext context) async {
    DateTime now = DateTime.now();
    DateTime minTime = DateTime(now.year, now.month, now.day, 9, 0); // 9:00 AM
    DateTime maxTime = DateTime(now.year, now.month, now.day, 17, 0); // 5:00 PM

    DateTime initialDt = dateTimeFromTimeOfDay(
      selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (initialDt.isBefore(minTime)) initialDt = minTime;
    if (initialDt.isAfter(maxTime)) initialDt = maxTime;

    DateTime? tempPickedTime = initialDt;

    final bool? didSelect = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          padding: const EdgeInsets.only(top: 6.0),
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  CupertinoButton(
                    child: const Text(
                      'Done',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ],
              ),

              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: initialDt,
                  minuteInterval: 5, // 5-minute interval
                  minimumDate: minTime, // 9:00 AM
                  maximumDate: maxTime, // 5:00 PM
                  backgroundColor: CupertinoColors.systemBackground.resolveFrom(
                    context,
                  ),
                  onDateTimeChanged: (DateTime newDateTime) {
                    tempPickedTime = newDateTime;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    // If user tapped "Done"
    if (didSelect == true && tempPickedTime != null) {
      setState(() {
        selectedTime = TimeOfDay.fromDateTime(tempPickedTime!);
        final DateTime tempDate = DateTime(
          2000,
          1,
          1,
          selectedTime!.hour,
          selectedTime!.minute,
        );
        timeController.text = DateFormat('hh:mm a').format(tempDate);
      });
    }
  }

  Future<void> handleUploadPhoto() async {
    final List<XFile> pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        uploadedImages.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  void removePhoto(int index) {
    setState(() {
      uploadedImages.removeAt(index);
    });
  }

  Future<void> handleSubmit() async {
    if (selectedDate == null) {
      showErrorDialog(context, "Please select a preferred date.");
      return;
    }
    if (selectedTime == null) {
      showErrorDialog(context, "Please select a preferred time.");
      return;
    }
    if (descriptionController.text.isEmpty) {
      showErrorDialog(context, "Please enter a service description.");
      return;
    }
    if (uploadedImages.isEmpty) {
      showErrorDialog(context, "Please upload at least one photo.");
      return;
    }

    final DateTime scheduledDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    final List<String> photoFilenames =
        uploadedImages.map((file) => p.basename(file.path)).toList();

    showLoadingDialog(context, "Submitting...");

    try {
      final controller = Provider.of<ServiceRequestController>(
        context,
        listen: false,
      );

      final bool success = await controller.addNewRequest(
        location: locationController.text,
        scheduledDateTime: scheduledDateTime,
        description: descriptionController.text,
        reqPicFileName: photoFilenames,
        serviceID: widget.serviceID,
        remark: remarkController.text.isNotEmpty ? remarkController.text : null,
      );

      Navigator.of(context).pop();

      if (success) {
        showSuccessDialog(
          context,
          'Success!',
          'Your service request has been submitted.',
          () {
            Navigator.of(context).pop(); // Close success dialog
            int popCount = 2;
            Navigator.of(context).popUntil((_) => popCount-- == 0);
          },
        );
      } else {
        showErrorDialog(context, "Failed to submit request. Please try again.");
      }
    } catch (e) {
      Navigator.of(context).pop();
      showErrorDialog(context, "An error occurred: $e");
    }
  }

  void handleCancel() {
    // TODO: Implement cancel logic or simply pop the page
    print('Cancel button pressed!');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Electric Service Booking',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Request Location',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: locationController,
              readOnly: true,
              style: Theme.of(context).textTheme.bodySmall,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Select Preferred Date',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => selectDate(context),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: dateController,
                        style: Theme.of(context).textTheme.bodySmall,
                        decoration: InputDecoration(
                          hintText: 'Select Date',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                          suffixIcon: const Icon(Icons.calendar_today),
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
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: const Color(0xFFFF7643).withOpacity(0.5),
                              width: 1.0,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Select Preferred Time',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => selectTime(context),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: timeController,
                        style: Theme.of(context).textTheme.bodySmall,
                        decoration: InputDecoration(
                          hintText: 'Select Time',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                          suffixIcon: const Icon(Icons.access_time),
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
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: const Color(0xFFFF7643).withOpacity(0.5),
                              width: 1.0,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'Service Description',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: descriptionController,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter the details of the service request...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
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
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: const Color(0xFFFF7643).withOpacity(0.5),
                    width: 1.0,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Service Request Photos',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: handleUploadPhoto,
              icon: const Icon(Icons.upload_file, color: Colors.black),
              label: Text(
                uploadedImages.isEmpty ? 'Upload photo' : 'Add another photo',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
              ),
            ),
            PhotoPreviewList(
              images: uploadedImages,
              onRemove: removePhoto,
            ),
            const SizedBox(height: 20),

            const Text(
              'Additional Remark',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: remarkController,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter the additional of the service request...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
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
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: const Color(0xFFFF7643).withOpacity(0.5),
                    width: 1.0,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7643),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: ElevatedButton(
                    onPressed: handleCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
