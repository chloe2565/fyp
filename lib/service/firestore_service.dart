import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();
  final FirebaseFirestore db = FirebaseFirestore.instance;
}