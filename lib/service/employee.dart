import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import '../model/databaseModel.dart';

class EmployeeService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  // Get Employee by userID
  Future<EmployeeModel?> getEmployeeByUserID(String userID) async {
    final snap = await db
        .collection('Employee')
        .where('userID', isEqualTo: userID)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return EmployeeModel.fromMap(snap.docs.first.data());
  }

  // Get Handyman profile
  Future<HandymanModel?> getHandymanByEmpID(String empID) async {
    final snap = await db
        .collection('Handyman')
        .where('empID', isEqualTo: empID)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return HandymanModel.fromMap(snap.docs.first.data());
  }

  // Get ServiceProvider profile
  Future<ServiceProviderModel?> getServiceProviderByEmpID(String empID) async {
    final snap = await db
        .collection('ServiceProvider')
        .where('empID', isEqualTo: empID)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return ServiceProviderModel.fromMap(snap.docs.first.data());
  }

  Future<List<String>> getAssignedServicesByHandymanID(
    String handymanID,
  ) async {
    final db = FirebaseFirestore.instance;

    try {
      final handymanServiceSnap = await db
          .collection('HandymanService')
          .where('handymanID', isEqualTo: handymanID)
          .get();

      if (handymanServiceSnap.docs.isEmpty) return [];

      final serviceIDs = handymanServiceSnap.docs
          .map((doc) => doc.data()['serviceID'] as String?)
          .whereType<String>()
          .toList();

      if (serviceIDs.isEmpty) return [];

      final serviceSnap = await db
          .collection('Service')
          .where(FieldPath.documentId, whereIn: serviceIDs)
          .get();

      final serviceNames = serviceSnap.docs
          .map((doc) => doc.data()['serviceName'] as String? ?? 'N/A')
          .toList();

      return serviceNames;
    } catch (e) {
      print('Error in getAssignedServicesByHandymanID: $e');
      return [];
    }
  }

  // Get all employees
  Future<List<Map<String, dynamic>>> getAllEmployeesWithUserInfo() async {
    try {
      final employeesSnap = await db.collection('Employee').get();

      if (employeesSnap.docs.isEmpty) return [];

      List<Map<String, dynamic>> employeesList = [];

      for (var empDoc in employeesSnap.docs) {
        final empData = empDoc.data();
        final userID = empData['userID'] as String?;

        if (userID != null) {
          final userSnap = await db.collection('User').doc(userID).get();

          if (userSnap.exists) {
            final userData = userSnap.data() as Map<String, dynamic>;
            employeesList.add({
              'empID': empData['empID'] ?? empDoc.id,
              'empType': empData['empType'] ?? 'N/A',
              'empStatus': empData['empStatus'] ?? 'N/A',
              'empSalary': (empData['empSalary'] as num? ?? 0.0).toDouble(),
              'empHireDate': empData['empHireDate'] ?? Timestamp.now(),
              'userID': userID,
              'userName': userData['userName'] ?? 'N/A',
              'userEmail': userData['userEmail'] ?? 'N/A',
              'userContact': userData['userContact'] ?? 'N/A',
              'userPicName': userData['userPicName'],
              'userGender': userData['userGender'],
              'userType': userData['userType'] ?? 'N/A',
              'userCreatedAt': userData['userCreatedAt'],
            });
          }
        }
      }

      return employeesList;
    } catch (e) {
      print('Error in getAllEmployeesWithUserInfo: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getOneEmployeeWithUserInfo(String empID) async {
    try {
      final empQuery = await db
          .collection('Employee')
          .where('empID', isEqualTo: empID)
          .limit(1)
          .get();
      if (empQuery.docs.isEmpty) return null;

      final empData = empQuery.docs.first.data();
      final userID = empData['userID'] as String?;
      if (userID == null) return empData;

      final userSnap = await db.collection('User').doc(userID).get();
      if (!userSnap.exists) return empData;

      final userData = userSnap.data() as Map<String, dynamic>;

      final empDocId = empQuery.docs.first.id;
      final fullData = {
        ...empData,
        ...userData,
        'empID': empData['empID'] ?? empDocId,
      };

      return fullData;
    } catch (e) {
      print('Error in getOneEmployeeWithUserInfo: $e');
      return null;
    }
  }

  Future<Map<String, String>> getAllServicesMap() async {
    try {
      final snap = await db
          .collection('Service')
          .where('serviceStatus', isEqualTo: 'active')
          .get();
      if (snap.docs.isEmpty) return {};

      final Map<String, String> serviceMap = {};
      for (var doc in snap.docs) {
        serviceMap[doc.id] = doc.data()['serviceName'] as String? ?? 'N/A';
      }
      return serviceMap;
    } catch (e) {
      print('Error getAllServicesMap: $e');
      return {};
    }
  }

  Future<Map<String, String>> getAssignedServicesMap(String handymanID) async {
    try {
      final snap = await db
          .collection('HandymanService')
          .where('handymanID', isEqualTo: handymanID)
          .get();

      if (snap.docs.isEmpty) return {};

      final serviceIDs = snap.docs
          .map((doc) => doc.data()['serviceID'] as String)
          .toList();
      if (serviceIDs.isEmpty) return {};

      final servicesSnap = await db
          .collection('Service')
          .where(FieldPath.documentId, whereIn: serviceIDs)
          .get();

      final Map<String, String> serviceMap = {};
      for (var doc in servicesSnap.docs) {
        serviceMap[doc.id] = doc.data()['serviceName'] as String? ?? 'N/A';
      }
      return serviceMap;
    } catch (e) {
      print('Error getAssignedServicesMap: $e');
      return {};
    }
  }

  // Generate random secure password
  String generateRandomPassword() {
    const length = 12;
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final random = Random.secure();
    return List.generate(
      length,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // Generate manual IDs
  Future<String> generateUserID() async {
    final snapshot = await db
        .collection('User')
        .orderBy('userID', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return 'U0001';

    final lastID = snapshot.docs.first.data()['userID'] as String;
    final number = int.parse(lastID.substring(1)) + 1;
    return 'U${number.toString().padLeft(4, '0')}';
  }

  Future<String> generateEmployeeID() async {
    final snapshot = await db
        .collection('Employee')
        .orderBy('empID', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return 'E0001';

    final lastID = snapshot.docs.first.data()['empID'] as String;
    final number = int.parse(lastID.substring(1)) + 1;
    return 'E${number.toString().padLeft(4, '0')}';
  }

  Future<String> generateHandymanID() async {
    final snapshot = await db
        .collection('Handyman')
        .orderBy('handymanID', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return 'H0001';

    final lastID = snapshot.docs.first.data()['handymanID'] as String;
    final number = int.parse(lastID.substring(1)) + 1;
    return 'H${number.toString().padLeft(4, '0')}';
  }

  Future<String> generateServiceProviderID() async {
    final snapshot = await db
        .collection('ServiceProvider')
        .orderBy('providerID', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return 'A0001';

    final lastID = snapshot.docs.first.data()['providerID'] as String;
    final number = int.parse(lastID.substring(2)) + 1;
    return 'A${number.toString().padLeft(4, '0')}';
  }

  Future<void> sendEmail({
    required String to,
    required String subject,
    required String userName,
    required String password,
  }) async {
    const backendUrl = 'https://fyp-backend-738r.onrender.com/send-email';

    final response = await http.post(
      Uri.parse(backendUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'to': to,
        'subject': subject,
        'user_name': userName,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      print('Email sent successfully!');
    } else {
      throw Exception('Failed to send email: ${response.body}');
    }
  }

  Future<bool> isUserIDTaken(String userID) async {
    final snap = await db.collection('User').doc(userID).get();
    return snap.exists;
  }

  Future<bool> isEmpIDTaken(String empID) async {
    final snap = await db.collection('Employee').doc(empID).get();
    return snap.exists;
  }

  // Check in user table for userEmail
  Future<bool> isEmailInUse(String email) async {
    final snap = await db
        .collection('User')
        .where('userEmail', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<String> addNewEmployee(
    Map<String, dynamic> data,
    String? imageUrl,
  ) async {
    String generatedPassword = generateRandomPassword();

    final email = data['userEmail'] as String;

    if (await isEmailInUse(email)) {
      throw Exception('This email is already in use by another account.');
    }

    final String tempAppName =
        'temp_user_creation_${DateTime.now().millisecondsSinceEpoch}';
    FirebaseApp tempApp;
    FirebaseAuth tempAuth;
    String authID;

    try {
      tempApp = await Firebase.initializeApp(
        name: tempAppName,
        options: Firebase.app().options,
      );
      tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      UserCredential userCredential;
      try {
        userCredential = await tempAuth.createUserWithEmailAndPassword(
          email: data['userEmail'],
          password: generatedPassword,
        );
      } catch (e) {
        throw Exception('Failed to create auth user: $e');
      }

      authID = userCredential.user!.uid;
      await tempApp.delete();
    } catch (e) {
      if (Firebase.apps.any((app) => app.name == tempAppName)) {
        await Firebase.app(tempAppName).delete();
      }
      print('Error during temporary app user creation: $e');
      rethrow;
    }

    try {
      // Generate IDs manually
      final userID = await generateUserID();
      final empID = await generateEmployeeID();

      await db.runTransaction((transaction) async {
        // Create User document
        final userDocRef = db.collection('User').doc(userID);
        transaction.set(userDocRef, {
          'userID': userID,
          'authID': authID,
          'userName': data['userName'],
          'userEmail': data['userEmail'],
          'userContact': data['userContact'],
          'userGender': data['userGender'],
          'userPicName': imageUrl,
          'userType': 'employee',
          'userCreatedAt': FieldValue.serverTimestamp(),
        });

        // Create Employee document
        final empDocRef = db.collection('Employee').doc(empID);
        transaction.set(empDocRef, {
          'empID': empID,
          'userID': userID,
          'empType': data['empType'],
          'empStatus': data['empStatus'],
          'empSalary': data['empSalary'],
          'empHireDate': FieldValue.serverTimestamp(),
        });

        // Create role-specific documents
        if (data['empType'] == 'handyman') {
          final handymanID = await generateHandymanID();
          final handymanDocRef = db.collection('Handyman').doc(handymanID);
          transaction.set(handymanDocRef, {
            'handymanID': handymanID,
            'empID': empID,
            'handymanBio': data['handymanBio'],
            'handymanRating': 0.0,
            'currentLocation': const GeoPoint(0, 0),
          });

          // Create HandymanService documents
          final List<String> serviceIDs = data['assignedServiceIDs'];
          for (var serviceID in serviceIDs) {
            final hsDocRef = db.collection('HandymanService').doc();
            transaction.set(hsDocRef, {
              'handymanID': handymanID,
              'serviceID': serviceID,
              'yearExperience': 1,
            });
          }
        } else if (data['empType'] == 'admin') {
          final providerID = await generateServiceProviderID();
          final providerDocRef = db
              .collection('ServiceProvider')
              .doc(providerID);
          transaction.set(providerDocRef, {
            'providerID': providerID,
            'empID': empID,
            'contactPersonName': data['contactPersonName'],
          });
        }
      });
      await sendEmail(
        to: data['userEmail'],
        subject: 'Welcome to Smart Handyman Services!',
        userName: data['userName'],
        password: generatedPassword,
      );

      return generatedPassword;
    } catch (e) {
      print('Error in addNewEmployee (CRITICAL): $e');
      rethrow;
    }
  }

  Future<void> updateEmployee(
    Map<String, dynamic> data,
    String? imageUrl,
  ) async {
    try {
      final userID = data['userID'] as String;
      final empID = data['empID'] as String;

      final userDocRef = db.collection('User').doc(userID);
      final Map<String, dynamic> userUpdates = {
        'userName': data['userName'],
        'userContact': data['userContact'],
        'userEmail': data['userEmail'],
        'userGender': data['userGender'],
      };
      if (imageUrl != null) {
        userUpdates['userPicName'] = imageUrl;
      }
      await userDocRef.update(userUpdates);

      final empDocRef = db.collection('Employee').doc(empID);
      await empDocRef.update({
        'empType': data['empType'],
        'empStatus': data['empStatus'],
      });

      if (data['empType'] == 'handyman') {
        final handyman = await getHandymanByEmpID(empID);
        if (handyman == null) throw 'Handyman profile not found';

        final handymanID = handyman.handymanID;
        final newServiceIDs = data['assignedServiceIDs'] as List<String>;

        await db.collection('Handyman').doc(handymanID).update({
          'handymanBio': data['handymanBio'] ?? '',
        });

        // Delete old service assignments
        final oldServicesSnap = await db
            .collection('HandymanService')
            .where('handymanID', isEqualTo: handymanID)
            .get();
        for (var doc in oldServicesSnap.docs) {
          await doc.reference.delete();
        }

        // Create new service assignments
        for (var serviceID in newServiceIDs) {
          await db.collection('HandymanService').add({
            'handymanID': handymanID,
            'serviceID': serviceID,
            'yearExperience': 1,
          });
        }
      }
    } catch (e) {
      print('Error in updateEmployee service: $e');
      rethrow;
    }
  }

  // Update employee status
  Future<void> updateEmployeeStatus(String empID, String status) async {
    try {
      final docRef = db.collection('Employee').doc(empID);
      await docRef.update({'empStatus': status});
    } catch (e) {
      print('Error in updateEmployeeStatus service: $e');
      rethrow;
    }
  }

  // Get handyman availability for a date range (for fallback)
  Future<List<HandymanAvailabilityModel>> getHandymanAvailability(
    String handymanID,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snap = await db
          .collection('HandymanAvailability')
          .where('handymanID', isEqualTo: handymanID)
          .where(
            'availabilityStartDateTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where(
            'availabilityStartDateTime',
            isLessThan: Timestamp.fromDate(endDate),
          )
          .orderBy('availabilityStartDateTime')
          .get();

      if (snap.docs.isEmpty) return [];

      return snap.docs
          .map((doc) => HandymanAvailabilityModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error in getHandymanAvailability: $e');
      return [];
    }
  }

  // Get all handyman availability records
  Future<List<HandymanAvailabilityModel>> getAllHandymanAvailability(
    String handymanID,
  ) async {
    try {
      final snap = await db
          .collection('HandymanAvailability')
          .where('handymanID', isEqualTo: handymanID)
          .get();

      if (snap.docs.isEmpty) {
        print('No availability records found for handyman: $handymanID');
        return [];
      }

      final results = snap.docs
          .map((doc) => HandymanAvailabilityModel.fromMap(doc.data()))
          .toList();

      results.sort(
        (a, b) =>
            a.availabilityStartDateTime.compareTo(b.availabilityStartDateTime),
      );

      return results;
    } catch (e) {
      print('Error in getAllHandymanAvailability: $e');
      return [];
    }
  }

  Stream<List<HandymanAvailabilityModel>> streamAllHandymanAvailability(
    String handymanID,
  ) {
    return db
        .collection('HandymanAvailability')
        .where('handymanID', isEqualTo: handymanID)
        .snapshots()
        .map((snap) {
          final results = snap.docs
              .map((doc) => HandymanAvailabilityModel.fromMap(doc.data()))
              .toList();

          results.sort(
            (a, b) => a.availabilityStartDateTime.compareTo(
              b.availabilityStartDateTime,
            ),
          );

          return results;
        });
  }

  Stream<List<Map<String, dynamic>>> streamHandymanServiceRequests(
    String handymanID,
  ) {
    return db
        .collection('ServiceRequest')
        .where('handymanID', isEqualTo: handymanID)
        .snapshots()
        .asyncMap((snap) async {
          List<Map<String, dynamic>> result = [];

          for (var doc in snap.docs) {
            final reqData = ServiceRequestModel.fromMap(doc.data());
            final status = reqData.reqStatus.toLowerCase();

            // Filter logic
            if (status != 'confirmed' &&
                status != 'departed' &&
                status != 'completed') {
              continue;
            }

            // Fetch Service Details
            String serviceName = 'Unknown Service';
            String serviceDuration = '1 hour';

            final serviceDoc = await db
                .collection('Service')
                .doc(reqData.serviceID)
                .get();

            if (serviceDoc.exists) {
              final serviceData = serviceDoc.data();
              serviceName = serviceData?['serviceName'] ?? 'Unknown Service';
              serviceDuration = serviceData?['serviceDuration'] ?? '1 hour';
            }

            result.add({
              'request': reqData,
              'serviceName': serviceName,
              'serviceDuration': serviceDuration,
            });
          }

          result.sort((a, b) {
            final reqA = a['request'] as ServiceRequestModel;
            final reqB = b['request'] as ServiceRequestModel;
            return reqA.scheduledDateTime.compareTo(reqB.scheduledDateTime);
          });

          return result;
        });
  }

  Future<List<Map<String, dynamic>>> getHandymanServiceRequests(
    String handymanID,
  ) async {
    try {
      final snap = await db
          .collection('ServiceRequest')
          .where('handymanID', isEqualTo: handymanID)
          .get();

      if (snap.docs.isEmpty) {
        print('No service requests found for handyman: $handymanID');
        return [];
      }

      print(
        'Found ${snap.docs.length} total service requests for handyman: $handymanID',
      );

      List<Map<String, dynamic>> result = [];

      for (var doc in snap.docs) {
        final reqData = ServiceRequestModel.fromMap(doc.data());

        final status = reqData.reqStatus.toLowerCase();
        if (status != 'confirmed' &&
            status != 'departed' &&
            status != 'completed') {
          continue;
        }

        final serviceDoc = await db
            .collection('Service')
            .doc(reqData.serviceID)
            .get();

        String serviceName = 'Unknown Service';
        String serviceDuration = '1 hour';

        if (serviceDoc.exists) {
          final serviceData = serviceDoc.data();
          serviceName = serviceData?['serviceName'] ?? 'Unknown Service';
          serviceDuration = serviceData?['serviceDuration'] ?? '1 hour';
        }

        result.add({
          'request': reqData,
          'serviceName': serviceName,
          'serviceDuration': serviceDuration,
        });
      }

      result.sort((a, b) {
        final reqA = a['request'] as ServiceRequestModel;
        final reqB = b['request'] as ServiceRequestModel;
        return reqA.scheduledDateTime.compareTo(reqB.scheduledDateTime);
      });

      return result;
    } catch (e) {
      print('Error in getHandymanServiceRequests: $e');
      return [];
    }
  }

  // Generate availability ID
  Future<String> generateAvailabilityID() async {
    final snapshot = await db
        .collection('HandymanAvailability')
        .orderBy('availabilityID', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return 'HA0001';

    final lastID = snapshot.docs.first.data()['availabilityID'] as String;
    final number = int.parse(lastID.substring(2)) + 1;
    return 'HA${number.toString().padLeft(4, '0')}';
  }

  // Add handyman unavailability
  Future<void> addHandymanUnavailability(
    String handymanID,
    DateTime startDateTime,
    DateTime endDateTime,
  ) async {
    try {
      final availabilityID = await generateAvailabilityID();

      await db.collection('HandymanAvailability').doc(availabilityID).set({
        'availabilityID': availabilityID,
        'handymanID': handymanID,
        'availabilityStartDateTime': Timestamp.fromDate(startDateTime),
        'availabilityEndDateTime': Timestamp.fromDate(endDateTime),
        'availabilityCreatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error in addHandymanUnavailability: $e');
      rethrow;
    }
  }

  // Delete handyman unavailability
  Future<void> deleteHandymanUnavailability(String availabilityID) async {
    try {
      await db.collection('HandymanAvailability').doc(availabilityID).delete();
    } catch (e) {
      print('Error in deleteHandymanUnavailability: $e');
      rethrow;
    }
  }
}
