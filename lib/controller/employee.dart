import 'package:flutter/material.dart';
import '../model/databaseModel.dart';
import '../service/user.dart';
import '../service/employee.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmployeeController extends ChangeNotifier {
  final UserService userService = UserService();
  final EmployeeService empService = EmployeeService();
  List<String> handymanServiceNames = [];

  UserModel? user;
  EmployeeModel? employee;
  HandymanModel? handyman;
  ServiceProviderModel? provider;

  bool isLoading = true;
  String? error;

  Future<void> loadProfile() async {
    isLoading = true;
    error = null;
    notifyListeners();

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
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }
}
