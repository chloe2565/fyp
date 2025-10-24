import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../model/database_model.dart';

class UserService {
  final CollectionReference usersCollection;
  final FirebaseAuth auth = FirebaseAuth.instance;
  UserService([FirebaseFirestore? db])
    : usersCollection = (db ?? FirebaseFirestore.instance).collection('User');

  // Fetch user data by authID (Firebase Authentication uid)
  Future<UserModel?> getUserByAuthID(String authID) async {
    try {
      print('Querying User for authID: $authID');
      // Query the users collection where authID matches the provided Firebase uid
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

      // Get authID then find matched authID
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
      QuerySnapshot query = await usersCollection
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
      QuerySnapshot query = await usersCollection
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
      await usersCollection.doc(user.userID).set(user.toMap());
      print("User ${user.userID} saved successfully.");
    } catch (e) {
      print('Error saving user: $e');
      throw Exception('Failed to save user: $e');
    }
  }

  // Update user (only changes)
  Future<void> updateUser(UserModel user) async {
    try {
      await usersCollection.doc(user.userID).update(user.toMap());
      print("User ${user.userID} updated successfully.");
    } catch (e) {
      print('Error updating user: $e');
      throw Exception('Failed to update user: $e');
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
