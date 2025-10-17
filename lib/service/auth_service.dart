import 'package:firebase_auth/firebase_auth.dart';
import '../model/user.dart';
import 'firestore_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  // Handle login with email and password
  Future<UserModel?> loginWithEmailAndPassword(String email, String password) async {
    try {
      // Ensure SafetyNet or reCAPTCHA is handled (Firebase handles it automatically with SafetyNet)
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      UserModel? user = await _firestoreService.getUserByAuthID(userCredential.user!.uid);
      if (user == null) {
        throw Exception('User data not found in Firestore.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e.code);
    } catch (e) {
      throw 'An unexpected error occurred: ${e.toString()}';
    }
  }

  // Map FirebaseAuth error codes to user-friendly messages
  String _getErrorMessage(String code) {
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
      // Create user in Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Create UserModel with the Firebase Authentication uid as authID
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

      // Add user to Firestore
      await _firestoreService.addUser(newUser);

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e.code);
    } catch (e) {
      throw 'An unexpected error occurred during registration: ${e.toString()}';
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In cancelled.');
      }

      // Get Google authentication credentials
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credentials
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Fetch or create user in Firestore
      UserModel? user = await _firestoreService.getUserByAuthID(userCredential.user!.uid);
      if (user == null) {
        // Create a new user in Firestore if they don't exist
        user = UserModel(
          userID: userCredential.user!.uid,
          userEmail: userCredential.user!.email ?? '',
          userName: userCredential.user!.displayName ?? '',
          userGender: '', // Default or prompt user later
          userContact: '', // Default or prompt user later
          userType: 'customer', // Default to customer
          userCreatedAt: DateTime.now(),
          authID: userCredential.user!.uid,
        );
        await _firestoreService.addUser(user);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e.code);
    } catch (e) {
      throw 'Google Sign-In failed: ${e.toString()}';
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      User? user = _auth.currentUser;
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
    } on FirebaseAuthException catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAccount(String email) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      if (user.email != email) {
        throw Exception('Provided email does not match the current user');
      }

      // Delete user data from Firestore
      await _firestoreService.deleteUser(user.uid);

      // Delete Firebase Auth account
      await user.delete();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  Future<bool> isEmailVerified() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    await user.reload(); // Refresh user data
    return user.emailVerified;
  }
}