import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/customer.dart';
import '../model/user.dart';

class FirestoreService {
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('User');
  final CollectionReference _customerCollection = FirebaseFirestore.instance.collection('Customer');

  // Fetch user data by authID (Firebase Authentication uid)
  Future<UserModel?> getUserByAuthID(String authID) async {
    try {
      print('Querying Firestore for authID: $authID');
      // Query the users collection where authID matches the provided Firebase uid
      QuerySnapshot query = await _usersCollection
          .where('authID', isEqualTo: authID)
          .limit(1)
          .get();

      print('Query returned ${query.docs.length} documents');

      if (query.docs.isNotEmpty) {
        var doc = query.docs.first;
        print('Found document: ${doc.id}, data: ${doc.data()}');
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      print('No document found for authID: $authID');
      return null;
    } catch (e) {
      print('Error fetching user by authID: $e');
      throw Exception('Failed to fetch user data: $e');
    }
  }

  // Fetch user data by userID
  Future<UserModel?> getUser(String userID) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(userID).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, userID);
      }
      return null;
    } catch (e) {
      print('Error fetching user: $e');
      throw Exception('Failed to fetch user: $e');
    }
  }

  Future<bool> isEmailTaken(String email, String excludeUserID) async {
    try {
      QuerySnapshot query = await _usersCollection
          .where('userEmail', isEqualTo: email.trim().toLowerCase())
          .where(FieldPath.documentId, isNotEqualTo: excludeUserID)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      throw Exception('Failed to check email: $e');
    }
  }

  Future<bool> isPhoneTaken(String phone, String excludeUserID) async {
    try {
      QuerySnapshot query = await _usersCollection
          .where('userContact', isEqualTo: phone.trim())
          .where(FieldPath.documentId, isNotEqualTo: excludeUserID)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking phone: $e');
      throw Exception('Failed to check phone: $e');
    }
  }

  // Add or update user in Firestore
  Future<void> addUser(UserModel user) async {
    try {
      await _usersCollection
          .doc(user.userID)
          .set(user.toMap());
      print("User ${user.userID} added successfully.");
    } catch (e) {
      print('Error adding user: $e');
      throw Exception('Failed to add user: $e');
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _usersCollection
          .doc(user.userID)
          .update(user.toMap());
      print("User ${user.userID} updated successfully.");
    } catch (e) {
      print('Error updating user: $e');
      throw Exception('Failed to update user: $e');
    }
  }

  // Add or update customer in Firestore
  Future<void> addCustomer(CustomerModel customer) async {
    try {
      await _customerCollection
          .doc(customer.custID) // enforce custom ID
          .set(customer.toMap());
      print("Customer ${customer.custID} added successfully.");
    } catch (e) {
      print('Error adding customer: $e');
      throw Exception('Failed to add customer: $e');
    }
  }

  // Delete user and associated customer data from Firestore
  Future<void> deleteUser(String authID) async {
    try {
      // Fetch the user by authID to get the userID
      QuerySnapshot userQuery = await _usersCollection
          .where('authID', isEqualTo: authID)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        print('No user found for authID: $authID');
        throw Exception('User not found');
      }

      var userDoc = userQuery.docs.first;
      String userID = userDoc.id;

      // Delete user document from User collection
      await _usersCollection.doc(userID).delete();
      print('User $userID deleted successfully');

      // Check if the user has a corresponding customer record
      String customerID = 'C${userID.substring(1)}'; // e.g., U0001 -> C0001
      DocumentSnapshot customerDoc = await _customerCollection.doc(customerID).get();

      if (customerDoc.exists) {
        await _customerCollection.doc(customerID).delete();
        print('Customer $customerID deleted successfully');
      } else {
        print('No customer record found for customerID: $customerID');
      }
    } catch (e) {
      print('Error deleting user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }
}