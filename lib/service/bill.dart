import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/billDetailViewModel.dart';
import '../model/databaseModel.dart';
import 'payment.dart';
import 'user.dart';

class BillService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final UserService userService = UserService();
  final PaymentService paymentService = PaymentService();

  static const double FIXED_OUTSTATION_FEE = 15.00;

  // Customer side
  Future<List<BillingModel>> getBills() async {
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

      final filteredBills = billingQuery.docs.where((doc) {
        return doc['billStatus'] != 'cancelled';
      }).toList();

      return filteredBills
          .map((doc) => BillingModel.fromMap({...doc.data(), 'billID': doc.id}))
          .toList();
    } catch (e) {
      print("Error fetching bills: $e");
      return [];
    }
  }

  Future<BillDetailViewModel> getBillDetails(BillingModel bill) async {
    try {
      // Get ServiceRequest
      final reqDoc = await db
          .collection('ServiceRequest')
          .doc(bill.reqID)
          .get();
      if (!reqDoc.exists) throw Exception("Service Request not found");
      final request = ServiceRequestModel.fromMap(reqDoc.data()!);

      // Get Service
      final serviceDoc = await db
          .collection('Service')
          .doc(request.serviceID)
          .get();
      if (!serviceDoc.exists) throw Exception("Service not found");
      final service = ServiceModel.fromMap(serviceDoc.data()!);

      // Get Customer Details
      final customerDoc = await db
          .collection('Customer')
          .doc(request.custID)
          .get();
      if (!customerDoc.exists) throw Exception("Customer not found");
      final customer = CustomerModel.fromMap(customerDoc.data()!);

      final customerUserDoc = await db
          .collection('User')
          .doc(customer.userID)
          .get();
      if (!customerUserDoc.exists) throw Exception("Customer User not found");
      final customerUser = UserModel.fromMap(customerUserDoc.data()!);

      // Get Handyman Details
      final handymanDoc = await db
          .collection('Handyman')
          .doc(request.handymanID)
          .get();
      if (!handymanDoc.exists) throw Exception("Handyman not found");
      final handyman = HandymanModel.fromMap(handymanDoc.data()!);

      final employeeDoc = await db
          .collection('Employee')
          .doc(handyman.empID)
          .get();
      if (!employeeDoc.exists) throw Exception("Employee not found");
      final employee = EmployeeModel.fromMap(employeeDoc.data()!);

      final handymanUserDoc = await db
          .collection('User')
          .doc(employee.userID)
          .get();
      if (!handymanUserDoc.exists) throw Exception("Handyman User not found");
      final handymanUser = UserModel.fromMap(handymanUserDoc.data()!);

      // Get Payment 
      final payment = await paymentService.getPaymentForBill(bill.billingID);

      // Calculate billing amounts
      double billServicePrice = service.servicePrice ?? 0.0;
      print("service price at service file is $billServicePrice");
      double billOutstationFee = FIXED_OUTSTATION_FEE;
      double totalPrice = bill.billAmt > 0 
          ? bill.billAmt 
          : billServicePrice + billOutstationFee;

      return BillDetailViewModel(
        totalPrice: totalPrice,
        billStatus: bill.billStatus,
        billingID: bill.billingID,
        customerAddress: request.reqAddress,
        bookingTimestamp: request.scheduledDateTime,
        serviceCompleteTimestamp: request.reqCompleteTime ?? DateTime.now(),
        customerName: customerUser.userName,
        customerContact: customerUser.userContact,
        serviceName: service.serviceName,
        serviceBasePrice: billServicePrice,
        outstationFee: billOutstationFee,
        handymanName: handymanUser.userName,
        paymentTimestamp: payment?.payCreatedAt,
        adminRemark: bill.adminRemark,
      );
    } catch (e) {
      print("Error in getBillDetails: $e");
      rethrow;
    }
  }

  // Employee side
  Future<List<BillingModel>> empGetBills() async {
    try {
      final billingQuery = await db.collection('Billing').get();
      return billingQuery.docs
          .map((doc) => BillingModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print("Error fetching bills: $e");
      return [];
    }
  }

  Future<String> generateNextBillID() async {
    const String prefix = 'BL';
    const int padding = 4;

    final query = await db
        .collection('Billing')
        .where('billingID', isGreaterThanOrEqualTo: prefix)
        .where('billingID', isLessThan: '${prefix}Z')
        .orderBy('billingID', descending: true)
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
      print("Error parsing last bill ID '$lastID': $e");
      return '$prefix${'1'.padLeft(padding, '0')}';
    }
  }

  Future<List<ServiceRequestModel>> getCompleteServiceRequests() async {
    try {
      final query = await db
          .collection('ServiceRequest')
          .where('reqStatus', isEqualTo: 'completed')
          .get();

      return query.docs
          .map((doc) => ServiceRequestModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print("Error fetching completed service requests: $e");
      return [];
    }
  }

  Future<void> addNewBill(BillingModel bill) async {
    try {
      await db.collection('Billing').doc(bill.billingID).set(bill.toMap());
    } catch (e) {
      print("Error adding new bill: $e");
      rethrow;
    }
  }

  Future<void> updateBillAndPayment(
    String billingID,
    Map<String, dynamic> billData,
  ) async {
    await db.runTransaction((transaction) async {
      final billingRef = db.collection('Billing').doc(billingID);
      transaction.update(billingRef, billData);
      final paymentRef = await getPaymentRefForBill(billingID);

      if (paymentRef != null) {
        final paymentData = {
          'payAmt': billData['billAmt'],
          'payStatus': billData['billStatus'],
        };

        if (billData.containsKey('adminRemark')) {
          paymentData['adminRemark'] = billData['adminRemark'];
        }
        transaction.update(paymentRef, paymentData);
      }
    });
  }

  Future<DocumentReference?> getPaymentRefForBill(String billingID) async {
    try {
      final query = await db
          .collection('Payment')
          .where('billingID', isEqualTo: billingID)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.reference;
      }
      return null;
    } catch (e) {
      print("Error finding payment for bill $billingID: $e");
      return null;
    }
  }

  Future<List<BillingModel>> getPendingBills() async {
    try {
      final billingQuery = await db
          .collection('Billing')
          .where('billStatus', isEqualTo: 'pending')
          .get();
      return billingQuery.docs
          .map((doc) => BillingModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print("Error fetching pending bills: $e");
      return [];
    }
  }

  Future<void> createBillingForCompletedRequest(String reqID) async {
    try {
      // Check if billing already exists for this request
      final existingBilling = await db
          .collection('Billing')
          .where('reqID', isEqualTo: reqID)
          .limit(1)
          .get();

      if (existingBilling.docs.isNotEmpty) {
        print('Billing already exists for request $reqID');
        return;
      }

      // Get the service request
      final reqDoc = await db.collection('ServiceRequest').doc(reqID).get();
      if (!reqDoc.exists) {
        throw Exception('Service request not found: $reqID');
      }
      final request = ServiceRequestModel.fromMap(reqDoc.data()!);

      // Get the service to fetch price
      final serviceDoc = await db
          .collection('Service')
          .doc(request.serviceID)
          .get();
      if (!serviceDoc.exists) {
        throw Exception('Service not found: ${request.serviceID}');
      }
      final service = ServiceModel.fromMap(serviceDoc.data()!);

      // Get provider ID (first active provider)
      final providerQuery = await db
          .collection('ServiceProvider')
          .where('providerStatus', isEqualTo: 'active')
          .limit(1)
          .get();

      String providerID = '';
      if (providerQuery.docs.isNotEmpty) {
        providerID = providerQuery.docs.first.data()['providerID'] ?? '';
      }

      // Calculate total amount
      final double servicePrice = service.servicePrice ?? 0.0;
      final double totalAmount = servicePrice + FIXED_OUTSTATION_FEE;

      // Generate billing ID
      final String billingID = await generateNextBillID();

      // Create billing model
      final newBill = BillingModel(
        billingID: billingID,
        reqID: reqID,
        billStatus: 'pending',
        billAmt: totalAmount,
        billDueDate: DateTime.now().add(const Duration(days: 3)),
        billCreatedAt: DateTime.now(),
        providerID: providerID,
        adminRemark: '',
      );

      // Save to Firestore
      await db.collection('Billing').doc(billingID).set(newBill.toMap());

      print('Billing $billingID created automatically for request $reqID');
    } catch (e) {
      print('Error creating billing for completed request: $e');
      rethrow;
    }
  }
}