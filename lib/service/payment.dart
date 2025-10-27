import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/databaseModel.dart';
import 'user.dart';

class PaymentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserService _userService = UserService();

Future<String> generateNextID() async {
    const String prefix = 'PY';
    const int padding = 4;

    final query = await _db
        .collection('Payment')
        .where('payID', isGreaterThanOrEqualTo: prefix)
        .where('payID', isLessThan: '${prefix}Z')
        .orderBy('payID', descending: true)
        .limit(1)
        .get();

    // Start from 1 if no service request record
    if (query.docs.isEmpty) {
      return '$prefix${'1'.padLeft(padding, '0')}';
    }

    // Find recent service request record ID
    final lastID = query.docs.first.id;

    try {
      final numericPart = lastID.substring(prefix.length);
      final lastNumber = int.parse(numericPart);
      final nextNumber = lastNumber + 1;

      return '$prefix${nextNumber.toString().padLeft(padding, '0')}';
    } catch (e) {
      print("Error parsing last request ID '$lastID': $e");
      return '$prefix${'1'.padLeft(padding, '0')}';
    }
  }

  Future<List<PaymentModel>> getPayments() async {
    try {
      final String? custID = await _userService.getCurrentCustomerID();
      if (custID == null) {
        print(
          "No customer ID found. User might not be logged in or have a customer profile.",
        );
        return [];
      }

      final requestQuery = await _db
          .collection('ServiceRequest')
          .where('custID', isEqualTo: custID)
          .get();

      if (requestQuery.docs.isEmpty) {
        return [];
      }

      final List<String> reqIDs = requestQuery.docs
          .map((doc) => doc.id)
          .toList();

      final billingQuery = await _db
          .collection('Billing')
          .where('reqID', whereIn: reqIDs)
          .get();

      if (billingQuery.docs.isEmpty) {
        return [];
      }

      final List<String> billingIDs = billingQuery.docs
          .map((doc) => doc.id)
          .toList();

      final paymentQuery = await _db
          .collection('Payment')
          .where('billingID', whereIn: billingIDs)
          .get();

      return paymentQuery.docs
          .map((doc) => PaymentModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print("Error fetching payments: $e");
      return [];
    }
  }

  Future<PaymentModel?> getPaymentForBill(String billingID) async {
    try {
      final query = await _db
          .collection('Payment')
          .where('billingID', isEqualTo: billingID)
          .orderBy('payCreatedAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      return PaymentModel.fromMap(query.docs.first.data());
    } catch (e) {
      print("Error fetching payment for bill $billingID: $e");
      return null;
    }
  }

  Future<void> createNewPayment({
    required String billingID,
    required double amount,
    required String method,
    required String providerID,
  }) async {
    try {
      final batch = _db.batch();
      final newPaymentRef = _db.collection('payment').doc();
      final newPaymentID = newPaymentRef.id;

      final newPayment = PaymentModel(
        payID: newPaymentID,
        payStatus: 'Success', 
        payAmt: amount,
        payMethod: method,
        payCreatedAt: DateTime.now(),
        adminRemark: '',
        payMediaProof: '', 
        providerID: providerID,
        billingID: billingID,
      );

      batch.set(newPaymentRef, newPayment.toMap());

      final billingRef = _db.collection('billing').doc(billingID);
      batch.update(billingRef, {'billStatus': 'paid'});

      await batch.commit();
    } catch (e) {
      print("Error creating new payment: $e");
      rethrow;
    }
  }
}
