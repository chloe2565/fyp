import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class ServiceRequestDetailsPage extends StatefulWidget {
  final String selectedLocation; // To receive location from previous page

  const ServiceRequestDetailsPage({
    super.key,
    this.selectedLocation = '18, Jalan Lembah Permai, Tanjung Bungah', // Default for demonstration
  });

  @override
  State<ServiceRequestDetailsPage> createState() =>
      _ServiceRequestDetailsPageState();
}

class _ServiceRequestDetailsPageState extends State<ServiceRequestDetailsPage> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedHour = '09'; // Default value
  String? _selectedMinute = '00'; // Default value
  String? _selectedAmPm = 'AM'; // Default value

  final List<String> _hours =
      List.generate(12, (index) => (index + 1).toString().padLeft(2, '0'));
  final List<String> _minutes =
      List.generate(60, (index) => index.toString().padLeft(2, '0'));
  final List<String> _amPm = ['AM', 'PM'];

  @override
  void initState() {
    super.initState();
    _locationController.text = widget.selectedLocation;

    // Set default date to 23 Sep 2025 for demonstration
    _selectedDate = DateTime(2025, 9, 23);
    _dateController.text = DateFormat('dd MMM yyyy').format(_selectedDate!);
  }

  @override
  void dispose() {
    _locationController.dispose();
    _dateController.dispose();
    _descriptionController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF7643), // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF7643), // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd MMM yyyy').format(_selectedDate!);
      });
    }
  }

  void _handleSubmit() {
    // TODO: Implement submission logic
    print('Submit button pressed!');
    print('Location: ${_locationController.text}');
    print('Date: ${_dateController.text}');
    print('Time: $_selectedHour:$_selectedMinute $_selectedAmPm');
    print('Description: ${_descriptionController.text}');
    print('Remark: ${_remarkController.text}');
    // You'd typically send this data to a backend or navigate
  }

  void _handleCancel() {
    // TODO: Implement cancel logic or simply pop the page
    print('Cancel button pressed!');
    Navigator.pop(context); // Go back to the previous page
  }

  void _handleUploadPhoto() {
    // TODO: Implement photo upload logic (e.g., using image_picker package)
    print('Upload photo button pressed!');
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Service Request Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _locationController,
                    readOnly: true, // Location is passed, not edited here
                    decoration: InputDecoration(
                      hintText: 'Enter your location',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: const Color(0xFFFF7643).withOpacity(0.5),
                            width: 1.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Select Preferred Date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _dateController,
                        decoration: InputDecoration(
                          hintText: 'Select Date',
                          suffixIcon: const Icon(Icons.calendar_today,
                              color: Color(0xFFFF7643)),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: const Color(0xFFFF7643).withOpacity(0.5),
                                width: 1.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Select Preferred Time',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Hour Dropdown
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedHour,
                              icon: const Icon(Icons.keyboard_arrow_down,
                                  color: Colors.grey),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedHour = newValue;
                                });
                              },
                              items: _hours.map<DropdownMenuItem<String>>(
                                  (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Minute Dropdown - (If you want 00/30 or specific, you'd adjust _minutes list)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedMinute,
                              icon: const Icon(Icons.keyboard_arrow_down,
                                  color: Colors.grey),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedMinute = newValue;
                                });
                              },
                              items: ['00', '30'].map<DropdownMenuItem<String>>(
                                  (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // AM/PM Dropdown
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedAmPm,
                              icon: const Icon(Icons.keyboard_arrow_down,
                                  color: Colors.grey),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedAmPm = newValue;
                                });
                              },
                              items: _amPm.map<DropdownMenuItem<String>>(
                                  (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Enter the details of the service request...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: const Color(0xFFFF7643).withOpacity(0.5),
                            width: 1.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Service Request Photos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _handleUploadPhoto,
                    icon: const Icon(Icons.upload_file, color: Colors.black),
                    label: const Text(
                      'Upload photo',
                      style: TextStyle(color: Colors.black),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Additional Remark',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _remarkController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Enter the additional of the service request...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: const Color(0xFFFF7643).withOpacity(0.5),
                            width: 1.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Submit and Cancel Buttons
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7643), // Orange
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
                    onPressed: _handleCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300, // Grey
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0, // No shadow for cancel button
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
          ),
        ],
      ),
    );
  }
}