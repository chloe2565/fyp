import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/databaseModel.dart';
import 'user.dart';

class PaymentService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final UserService userService = UserService();

  Future<String> generateNextID() async {
    const String prefix = 'PY';
    const int padding = 4;

    final query = await db
        .collection('Payment')
        .where('payID', isGreaterThanOrEqualTo: prefix)
        .where('payID', isLessThan: '${prefix}Z')
        .orderBy('payID', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return '$prefix${'1'.padLeft(padding, '0')}';
    }

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

  // Customer side
  Future<List<PaymentModel>> getPayments() async {
    try {
      final String? custID = await userService.getCurrentCustomerID();
      if (custID == null) {
        print(
          "No customer ID found. User might not be logged in or have a customer profile.",
        );
        return [];
      }

      final requestQuery = await db
          .collection('ServiceRequest')
          .where('custID', isEqualTo: custID)
          .get();

      if (requestQuery.docs.isEmpty) {
        return [];
      }

      final List<String> reqIDs = requestQuery.docs
          .map((doc) => doc.id)
          .toList();

      final billingQuery = await db
          .collection('Billing')
          .where('reqID', whereIn: reqIDs)
          .get();

      if (billingQuery.docs.isEmpty) {
        return [];
      }

      final List<String> billingIDs = billingQuery.docs
          .map((doc) => doc.id)
          .toList();

      final paymentQuery = await db
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
      final query = await db
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

  // Employee side
  Future<List<PaymentModel>> empGetPayments() async {
    try {
      final paymentQuery = await db.collection('Payment').get();

      if (paymentQuery.docs.isEmpty) {
        return [];
      }

      return paymentQuery.docs
          .map((doc) => PaymentModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print("Error fetching payments: $e");
      return [];
    }
  }

  Future<PaymentModel?> getPaymentById(String payID) async {
    try {
      final doc = await db.collection('Payment').doc(payID).get();
      if (doc.exists) {
        return PaymentModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print("Error fetching payment $payID: $e");
      return null;
    }
  }

  Future<void> createNewPayment({
    required String billingID,
    required double payAmt,
    required String payMethod,
    required String providerID,
    required String payStatus,
    required String payMediaProof,
    required String adminRemark,
  }) async {
    try {
      final batch = db.batch();
      final newPaymentID = await generateNextID();
      final newPaymentRef = db.collection('Payment').doc(newPaymentID);

      final newPayment = PaymentModel(
        payID: newPaymentID,
        payStatus: payStatus,
        payAmt: payAmt,
        payMethod: payMethod,
        payCreatedAt: DateTime.now(),
        adminRemark: adminRemark,
        payMediaProof: payMediaProof,
        providerID: providerID,
        billingID: billingID,
      );

      batch.set(newPaymentRef, newPayment.toMap());

      final billingRef = db.collection('Billing').doc(billingID);
      String billStatus = (payStatus.toLowerCase() == 'paid')
          ? 'paid'
          : 'pending';
      batch.update(billingRef, {'billStatus': billStatus});

      await batch.commit();
    } catch (e) {
      print("Error creating new payment: $e");
      rethrow;
    }
  }

  Future<void> updatePayment(
    String payID,
    String billingID,
    Map<String, dynamic> data,
    String newPayStatus,
  ) async {
    try {
      final batch = db.batch();

      final paymentRef = db.collection('Payment').doc(payID);
      batch.update(paymentRef, data);

      final billingRef = db.collection('Billing').doc(billingID);
      final String statusToSync = newPayStatus.toLowerCase();
      if (statusToSync == 'paid') {
        batch.update(billingRef, {'billStatus': 'paid'});
      } else if (statusToSync == 'pending') {
        batch.update(billingRef, {'billStatus': 'pending'});
      }

      await batch.commit();
    } catch (e) {
      print("Error updating payment $payID: $e");
      rethrow;
    }
  }
}
