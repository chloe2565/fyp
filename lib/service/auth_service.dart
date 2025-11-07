import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../model/databaseModel.dart';
import 'user.dart';

class AuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final UserService userService = UserService();
  final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);

  // Handle login with email and password
  Future<UserModel?> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      UserModel? user = await userService.getUserByAuthID(
        userCredential.user!.uid,
      );
      if (user == null) throw Exception('User data not found in Firestore.');
      return user;
    } on FirebaseAuthException catch (e) {
      throw getErrorMessage(e.code);
    } catch (e) {
      throw 'An unexpected error occurred: ${e.toString()}';
    }
  }

  // Map FirebaseAuth error codes to user-friendly messages
  String getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  // Register with email and password
  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String gender,
    required String contact,
    required String type,
  }) async {
    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      UserModel newUser = UserModel(
        userID: userCredential.user!.uid,
        userEmail: email,
        userName: name,
        userGender: gender,
        userContact: contact,
        userType: type,
        userCreatedAt: DateTime.now(),
        authID: userCredential.user!.uid,
      );

      await userService.addUser(newUser);

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw getErrorMessage(e.code);
    } catch (e) {
      throw 'An unexpected error occurred during registration: ${e.toString()}';
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In cancelled.');
      }

      // Get Google authentication credentials
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credentials
      UserCredential userCredential = await auth.signInWithCredential(
        credential,
      );

      // Fetch or create user in Firestore
      UserModel? user = await userService.getUserByAuthID(
        userCredential.user!.uid,
      );
      if (user == null) {
        user = UserModel(
          userID: userCredential.user!.uid,
          userEmail: userCredential.user!.email ?? '',
          userName: userCredential.user!.displayName ?? '',
          userGender: '',
          userContact: '',
          userType: 'customer',
          userCreatedAt: DateTime.now(),
          authID: userCredential.user!.uid,
        );
        await userService.addUser(user);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw getErrorMessage(e.code);
    } catch (e) {
      throw 'Google Sign-In failed: ${e.toString()}';
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      User? user = auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> deleteAccount(String email) async {
    try {
      User? authUser = auth.currentUser;
      if (authUser == null) {
        throw Exception('No user is currently signed in');
      }

      if (authUser.email?.toLowerCase() != email.toLowerCase()) {
        throw Exception('Email does not match the current user');
      }

      final userSnapshot = await firestore
          .collection('User')
          .where('authID', isEqualTo: authUser.uid)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        throw Exception('User record not found');
      }

      final userID = userSnapshot.docs.first.id;
      final customerSnapshot = await firestore
          .collection('Customer')
          .where('userID', isEqualTo: userID)
          .limit(1)
          .get();

      if (customerSnapshot.docs.isNotEmpty) {
        final custID = customerSnapshot.docs.first.id;

        await firestore.collection('Customer').doc(custID).update({
          'custStatus': 'inactive',
        });
        print('Customer $custID status set to inactive');
      }

      await authUser.delete();
      print('Firebase Authentication user deleted successfully');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'This action requires recent authentication. Please log in again.',
        );
      }
      throw Exception('Failed to delete account: ${e.message}');
    } catch (e) {
      print('Error in deleteAccount: $e');
      throw Exception('Failed to delete account: $e');
    }
  }

  Future<bool> isEmailVerified() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    await user.reload();
    return user.emailVerified;
  }
}
