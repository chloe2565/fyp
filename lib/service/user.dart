import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/databaseModel.dart';

class UserService {
  final CollectionReference usersCollection;
  final FirebaseAuth auth = FirebaseAuth.instance;
  UserService([FirebaseFirestore? db])
    : usersCollection = (db ?? FirebaseFirestore.instance).collection('User');

  // Fetch user data by authID (Firebase Authentication uid)
  Future<UserModel?> getUserByAuthID(String authID) async {
    try {
      print('Querying User for authID: $authID');
      QuerySnapshot query = await usersCollection
          .where('authID', isEqualTo: authID)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        var doc = query.docs.first;
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      print('No document found for authID: $authID');
      return null;
    } catch (e) {
      print('Error fetching user by authID: $e');
      throw Exception('Failed to fetch user data: $e');
    }
  }

  Future<String?> getCurrentCustomerID() async {
    try {
      final userAuth = auth.currentUser;
      if (userAuth == null) {
        print("User not logged in");
        return null;
      }

      final userQuery = await usersCollection
          .where('authID', isEqualTo: userAuth.uid)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        print("No User document found for authID ${userAuth.uid}");
        return null;
      }

      final customerCollection = usersCollection.firestore.collection(
        'Customer',
      );

      final customerQuery = await customerCollection
          .where('userID', isEqualTo: userQuery.docs.first.id)
          .limit(1)
          .get();

      if (customerQuery.docs.isEmpty) {
        print("No customer profile found for user ${userQuery.docs.first.id}");
        return null;
      }
      return customerQuery.docs.first.id;
    } catch (e) {
      print("Error fetching customer ID: $e");
      return null;
    }
  }

  // Get current employee ID and type (admin or handyman)
  Future<Map<String, String>?> getCurrentEmployeeInfo() async {
    try {
      final userAuth = auth.currentUser;
      if (userAuth == null) {
        print("User not logged in");
        return null;
      }

      final userQuery = await usersCollection
          .where('authID', isEqualTo: userAuth.uid)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        print("No User document found for authID ${userAuth.uid}");
        return null;
      }

      final employeeCollection = usersCollection.firestore.collection(
        'Employee',
      );

      final employeeQuery = await employeeCollection
          .where('userID', isEqualTo: userQuery.docs.first.id)
          .limit(1)
          .get();

      if (employeeQuery.docs.isEmpty) {
        print("No employee profile found for user ${userQuery.docs.first.id}");
        return null;
      }

      final empDoc = employeeQuery.docs.first;
      final empData = empDoc.data();

      return {
        'empID': empDoc.id,
        'empType': empData['empType'] as String, // 'admin' or 'handyman'
      };
    } catch (e) {
      print("Error fetching employee info: $e");
      return null;
    }
  }

  // Get provider ID (admin ID)
  Future<String?> getCurrentProviderID() async {
    try {
      final userAuth = auth.currentUser;
      if (userAuth == null) {
        print("User not logged in");
        return null;
      }

      final userQuery = await usersCollection
          .where('authID', isEqualTo: userAuth.uid)
          .limit(1)
          .get();
      if (userQuery.docs.isEmpty) {
        print("No User document found for authID ${userAuth.uid}");
        return null;
      }
      final String userID = userQuery.docs.first.id;

      final firestore = usersCollection.firestore;
      final employeeQuery = await firestore
          .collection('Employee')
          .where('userID', isEqualTo: userID)
          .limit(1)
          .get();
      if (employeeQuery.docs.isEmpty) {
        print("No Employee document found for userID $userID");
        return null;
      }
      final String empID = employeeQuery.docs.first.id;

      final providerQuery = await firestore
          .collection('ServiceProvider')
          .where('empID', isEqualTo: empID)
          .limit(1)
          .get();
      if (providerQuery.docs.isEmpty) {
        print("No ServiceProvider document found for empID $empID");
        return null;
      }

      return providerQuery.docs.first.id;
    } catch (e) {
      print("Error fetching provider ID: $e");
      return null;
    }
  }

  // Fetch user data by userID
  Future<UserModel?> getUser(String userID) async {
    try {
      DocumentSnapshot doc = await usersCollection.doc(userID).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error fetching user: $e');
      throw Exception('Failed to fetch user: $e');
    }
  }

  Future<bool> isEmailTaken(String email, String excludeUserID) async {
    try {
      Query query = usersCollection.where(
        'userEmail',
        isEqualTo: email.trim().toLowerCase(),
      );

      if (excludeUserID.isNotEmpty) {
        query = query.where(FieldPath.documentId, isNotEqualTo: excludeUserID);
      }

      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isEmpty) {
        return false;
      }

      for (var doc in querySnapshot.docs) {
        String userID = doc.id;

        QuerySnapshot customerSnapshot = await usersCollection.firestore
            .collection('Customer')
            .where('userID', isEqualTo: userID)
            .limit(1)
            .get();

        if (customerSnapshot.docs.isNotEmpty) {
          String custStatus =
              customerSnapshot.docs.first.get('custStatus') ?? 'active';
          if (custStatus == 'active') {
            return true;
          }
        } else {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking email: $e');
      throw Exception('Failed to check email: $e');
    }
  }

  Future<bool> isPhoneTaken(String phone, String excludeUserID) async {
    try {
      Query query = usersCollection.where(
        'userContact',
        isEqualTo: phone.trim(),
      );

      if (excludeUserID.isNotEmpty) {
        query = query.where(FieldPath.documentId, isNotEqualTo: excludeUserID);
      }

      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isEmpty) {
        return false;
      }

      for (var doc in querySnapshot.docs) {
        String userID = doc.id;
        QuerySnapshot customerSnapshot = await usersCollection.firestore
            .collection('Customer')
            .where('userID', isEqualTo: userID)
            .limit(1)
            .get();

        if (customerSnapshot.docs.isNotEmpty) {
          String custStatus =
              customerSnapshot.docs.first.get('custStatus') ?? 'active';

          if (custStatus == 'active') {
            return true;
          }
        } else {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error checking phone: $e');
      throw Exception('Failed to check phone: $e');
    }
  }

  // Add or update user in Firestore
  Future<void> addUser(UserModel user) async {
    try {
      await usersCollection.doc(user.userID).set(user.toMap());
      print("User ${user.userID} saved successfully.");
    } catch (e) {
      print('Error saving user: $e');
      throw Exception('Failed to save user: $e');
    }
  }

  // Update user (only changes)
  Future<void> updateUser(String userID, Map<String, dynamic> updates) async {
    try {
      await usersCollection.doc(userID).update(updates);
      print("User $userID fields updated successfully.");
    } catch (e) {
      print('Error updating user fields: $e');
      throw Exception('Failed to update user fields: $e');
    }
  }

  // Delete user by authID
  Future<void> deleteUser(String authID) async {
    try {
      UserModel? user = await getUserByAuthID(authID);
      if (user == null) {
        throw Exception('User not found');
      }
      await usersCollection.doc(user.userID).delete();
      print('User ${user.userID} deleted successfully');
    } catch (e) {
      print('Error deleting user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }
}
