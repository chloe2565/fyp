import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../model/databaseModel.dart';
import '../service/image_service.dart';
import '../service/user.dart';
import '../service/employee.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user.dart';

class EmployeeController extends ChangeNotifier {
  final UserService userService = UserService();
  final EmployeeService empService = EmployeeService();
  final FirebaseImageService imageService = FirebaseImageService();
  List<String> handymanServiceNames = [];

  UserModel? user;
  EmployeeModel? employee;
  HandymanModel? handyman;
  ServiceProviderModel? provider;

  bool isLoading = true;
  bool isAdmin = false;
  bool isLoadingRole = true;
  String? error;

  // Employee detail
  HandymanModel? specificHandymanModel;
  ServiceProviderModel? specificServiceProviderModel;
  List<String> specificHandymanServiceNames = [];
  bool isDetailsLoading = false;

  List<Map<String, dynamic>> allEmployeesRaw = [];
  List<Map<String, dynamic>> displayedEmployees = [];

  // Handyman availability
  List<HandymanAvailabilityModel> handymanAvailabilities = [];
  bool isLoadingAvailability = false;

  // NEW: Timetable properties
  List<Map<String, dynamic>> handymanServiceRequests = [];
  bool isLoadingTimetable = false;
  StreamSubscription? availabilitySubscription;
  StreamSubscription? requestsSubscription;

  Future<void> loadPageData(UserController userController) async {
    isLoadingRole = true;
    notifyListeners();

    final user = await userController.getCurrentUser();
    if (user != null) {
      final empType = await userController.getEmpType(user.userID);
      if (empType == 'admin') {
        isAdmin = true;
      }
    }
    isLoadingRole = false;
    notifyListeners();

    if (isAdmin) {
      await loadEmployees();
    }
  }

  Future<void> loadEmployees() async {
    isLoading = true;
    notifyListeners();

    try {
      allEmployeesRaw = await empService.getAllEmployeesWithUserInfo();

      for (var employee in allEmployeesRaw) {
        if (employee['empType'] == 'handyman') {
          final empID = employee['empID'] as String;
          final handyman = await empService.getHandymanByEmpID(empID);
          if (handyman != null) {
            final services = await empService.getAssignedServicesByHandymanID(
              handyman.handymanID,
            );
            employee['assignedServices'] = services;
          }
        }
      }

      searchEmployees("");
    } catch (e) {
      print("Error loading employees: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> reloadEmployeeData(String empID) async {
    try {
      return await empService.getOneEmployeeWithUserInfo(empID);
    } catch (e) {
      print('Error reloading employee data: $e');
      return null;
    }
  }

  void searchEmployees(String query) {
    final lowerQuery = query.toLowerCase();

    if (lowerQuery.isEmpty) {
      displayedEmployees = List.from(allEmployeesRaw);
    } else {
      displayedEmployees = allEmployeesRaw.where((employee) {
        final userName = (employee['userName'] as String? ?? '').toLowerCase();
        final empID = (employee['empID'] as String? ?? '').toLowerCase();
        final empType = (employee['empType'] as String? ?? '').toLowerCase();
        return userName.contains(lowerQuery) ||
            empID.contains(lowerQuery) ||
            empType.contains(lowerQuery);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> loadProfile() async {
    isLoading = true;
    error = null;
    if (hasListeners) notifyListeners();

    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) throw 'Not authenticated';

      user = await userService.getUserByAuthID(authUser.uid);
      if (user == null) throw 'User not found';

      employee = await empService.getEmployeeByUserID(user!.userID);
      if (employee == null) throw 'Employee record missing';

      if (employee!.empType == 'handyman') {
        handyman = await empService.getHandymanByEmpID(employee!.empID);
        if (handyman != null) {
          handymanServiceNames = await empService
              .getAssignedServicesByHandymanID(handyman!.handymanID);
        }
      } else {
        provider = await empService.getServiceProviderByEmpID(employee!.empID);
      }

      isLoading = false;
      if (hasListeners) notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      if (hasListeners) {
        notifyListeners();
      }
    }
  }

  Future<void> loadSpecificEmployeeDetails(Map<String, dynamic> empData) async {
    isDetailsLoading = true;
    specificHandymanModel = null;
    specificServiceProviderModel = null;
    specificHandymanServiceNames = [];
    notifyListeners();

    try {
      final empID = empData['empID'] as String;
      final empType = empData['empType'] as String;

      if (empType == 'handyman') {
        specificHandymanModel = await empService.getHandymanByEmpID(empID);
        if (specificHandymanModel != null) {
          specificHandymanServiceNames = await empService
              .getAssignedServicesByHandymanID(
                specificHandymanModel!.handymanID,
              );
        }
      } else if (empType == 'admin') {
        specificServiceProviderModel = await empService
            .getServiceProviderByEmpID(empID);
      }

      isDetailsLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading specific employee details: $e');
      isDetailsLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllEmployeeDataForView() async {
    final rawDataList = await empService.getAllEmployeesWithUserInfo();

    final uiReadyList = <Map<String, dynamic>>[];

    for (final dataMap in rawDataList) {
      final employee = EmployeeModel(
        empID: dataMap['empID'] ?? '',
        empStatus: dataMap['empStatus'] ?? '',
        empSalary: (dataMap['empSalary'] as num? ?? 0.0).toDouble(),
        empType: dataMap['empType'] ?? '',
        empHireDate: (dataMap['empHireDate'] is Timestamp)
            ? (dataMap['empHireDate'] as Timestamp).toDate()
            : DateTime.now(),
        userID: dataMap['userID'] ?? '',
      );

      final user = UserModel(
        authID: dataMap['authID'],
        userID: dataMap['userID'] ?? '',
        userName: dataMap['userName'] ?? '',
        userEmail: dataMap['userEmail'] ?? '',
        userContact: dataMap['userContact'] ?? '',
        userPicName: dataMap['userPicName'],
        userType: dataMap['userType'] ?? '',
        userGender: dataMap['userGender'],
        userCreatedAt: dataMap['userCreatedAt'],
      );

      uiReadyList.add({'employee': employee, 'user': user});
    }

    return uiReadyList;
  }

  Future<Map<String, String>> getAllServicesMap() {
    return empService.getAllServicesMap();
  }

  Future<Map<String, String>> getAssignedServicesMap(String empID) async {
    try {
      final handyman = await empService.getHandymanByEmpID(empID);
      if (handyman == null) {
        return {};
      }
      return empService.getAssignedServicesMap(handyman.handymanID);
    } catch (e) {
      print('Error getAssignedServicesMap: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>?> getHandymanDetails(String empID) async {
    try {
      final handyman = await empService.getHandymanByEmpID(empID);
      if (handyman == null) return null;
      return {
        'handymanID': handyman.handymanID,
        'empID': handyman.empID,
        'handymanBio': handyman.handymanBio,
        'handymanRating': handyman.handymanRating,
      };
    } catch (e) {
      print('Error getHandymanDetails: $e');
      return null;
    }
  }

  Future<String> addNewEmployee(
    Map<String, dynamic> data,
    File? newImageFile,
  ) async {
    try {
      String? downloadUrl;

      if (newImageFile != null) {
        final uniqueId = data['userEmail'].toString().split('@').first;
        downloadUrl = await imageService.uploadImage(
          imageFile: newImageFile,
          category: ImageCategory.profiles,
          uniqueId: uniqueId,
        );
      }

      return empService.addNewEmployee(data, downloadUrl);
    } catch (e) {
      print('Error in addNewEmployee controller: $e');
      rethrow;
    }
  }

  Future<void> updateEmployee(
    Map<String, dynamic> data,
    File? newImageFile,
    String? oldImageUrl,
  ) async {
    try {
      String? finalImageUrl = oldImageUrl;

      if (newImageFile != null) {
        finalImageUrl = await imageService.updateImage(
          newImageFile: newImageFile,
          category: ImageCategory.profiles,
          uniqueId: data['empID'],
          oldImageUrl: oldImageUrl,
        );
      }

      return empService.updateEmployee(data, finalImageUrl);
    } catch (e) {
      print('Error in updateEmployee controller: $e');
      rethrow;
    }
  }

  // Delete employee
  Future<void> updateEmployeeStatus(String empID, String status) {
    try {
      if (!['inactive', 'resigned', 'retired'].contains(status)) {
        throw ArgumentError('Invalid status: $status');
      }
      return empService.updateEmployeeStatus(empID, status);
    } catch (e) {
      print('Error in updateEmployeeStatus controller: $e');
      rethrow;
    }
  }

  // OLD METHOD - kept for backward compatibility
  Future<void> loadHandymanAvailability(
    String handymanID,
    DateTime weekStart,
  ) async {
    isLoadingAvailability = true;
    notifyListeners();

    try {
      final weekEnd = weekStart.add(const Duration(days: 7));
      handymanAvailabilities = await empService.getHandymanAvailability(
        handymanID,
        weekStart,
        weekEnd,
      );
    } catch (e) {
      print('Error loading handyman availability: $e');
    }

    isLoadingAvailability = false;
    notifyListeners();
  }

  // Load availability and service requests for timetable view
  Future<void> loadHandymanTimetableData(String handymanID) async {
    await availabilitySubscription?.cancel();
    await requestsSubscription?.cancel();

    isLoadingTimetable = true;
    notifyListeners();

    try {
      availabilitySubscription = empService
          .streamAllHandymanAvailability(handymanID)
          .listen(
            (data) {
              handymanAvailabilities = data;
              notifyListeners();
            },
            onError: (e) {
              print('Error: Availability stream error: $e');
            },
          );

      requestsSubscription = empService
          .streamHandymanServiceRequests(handymanID)
          .listen(
            (data) {
              handymanServiceRequests = data;
              isLoadingTimetable = false;

              notifyListeners();
            },
            onError: (e) {
              print('Error: Request stream error: $e');
              isLoadingTimetable = false;
              notifyListeners();
            },
          );
    } catch (e) {
      print('Error: General controller error: $e');
      isLoadingTimetable = false;
      notifyListeners();
    }
  }

  List<HandymanAvailabilityModel> getUnavailabilitiesForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return handymanAvailabilities.where((avail) {
      return (avail.availabilityStartDateTime.isBefore(endOfDay) &&
          avail.availabilityEndDateTime.isAfter(startOfDay));
    }).toList();
  }

  List<Map<String, dynamic>> getServiceRequestsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final results = handymanServiceRequests.where((data) {
      final request = data['request'] as ServiceRequestModel;
      final scheduledDate = request.scheduledDateTime;

      final isMatch =
          scheduledDate.isAfter(
            startOfDay.subtract(const Duration(seconds: 1)),
          ) &&
          scheduledDate.isBefore(endOfDay);

      return isMatch;
    }).toList();

    return results;
  }

  // Parse service duration string to hours
  double parseServiceDuration(String duration) {
    if (duration.isEmpty) return 1.0;

    final cleaned = duration
        .toLowerCase()
        .replaceAll('hours', '')
        .replaceAll('hour', '')
        .replaceAll('h', '')
        .trim();

    // Handle range number
    final rangePattern = RegExp(r'(\d+\.?\d*)\s*(?:to|-)\s*(\d+\.?\d*)');
    final rangeMatch = rangePattern.firstMatch(cleaned);

    if (rangeMatch != null) {
      final max = double.parse(rangeMatch.group(2)!);
      return max;
    }

    // Handle single number
    final singlePattern = RegExp(r'(\d+\.?\d*)');
    final singleMatch = singlePattern.firstMatch(cleaned);

    if (singleMatch != null) {
      return double.parse(singleMatch.group(1)!);
    }

    return 1.0;
  }

  Future<void> addHandymanUnavailability(
    String handymanID,
    DateTime startDateTime,
    DateTime endDateTime,
  ) async {
    try {
      await empService.addHandymanUnavailability(
        handymanID,
        startDateTime,
        endDateTime,
      );
    } catch (e) {
      print('Error in addHandymanUnavailability controller: $e');
      rethrow;
    }
  }

  Future<void> deleteHandymanUnavailability(String availabilityID) async {
    try {
      await empService.deleteHandymanUnavailability(availabilityID);
    } catch (e) {
      print('Error in deleteHandymanUnavailability controller: $e');
      rethrow;
    }
  }

  // Get handymanID from empID
  Future<String?> getHandymanIDByEmpID(String empID) async {
    try {
      final handyman = await empService.getHandymanByEmpID(empID);
      return handyman?.handymanID;
    } catch (e) {
      print('Error getting handymanID: $e');
      return null;
    }
  }

  @override
  void dispose() {
    availabilitySubscription?.cancel();
    requestsSubscription?.cancel();
    super.dispose();
  }
}
