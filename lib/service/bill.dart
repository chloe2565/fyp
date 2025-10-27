import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/billDetailViewModel.dart';
import '../model/databaseModel.dart';
import 'payment.dart';
import 'user.dart';

class BillService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserService _userService = UserService();
  final PaymentService paymentService = PaymentService();

  Future<List<BillingModel>> getBills() async {
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

      return billingQuery.docs
          .map((doc) => BillingModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print("Error fetching bills: $e");
      return [];
    }
  }

  Future<BillDetailViewModel> getBillDetails(BillingModel bill) async {
    try {
      // Get ServiceRequest
      final reqDoc = await _db
          .collection('ServiceRequest')
          .doc(bill.reqID)
          .get();
      if (!reqDoc.exists) throw Exception("Service Request not found");
      final request = ServiceRequestModel.fromMap(reqDoc.data()!);

      // Get Service
      final serviceDoc = await _db
          .collection('Service')
          .doc(request.serviceID)
          .get();
      if (!serviceDoc.exists) throw Exception("Service not found");
      final service = ServiceModel.fromMap(serviceDoc.data()!);

      // Get Customer User Details
      final customerDoc = await _db
          .collection('Customer')
          .doc(request.custID)
          .get();
      if (!customerDoc.exists) throw Exception("Customer not found");
      final customer = CustomerModel.fromMap(customerDoc.data()!);

      final customerUserDoc = await _db
          .collection('User')
          .doc(customer.userID)
          .get();
      if (!customerUserDoc.exists) throw Exception("Customer User not found");
      final customerUser = UserModel.fromMap(customerUserDoc.data()!);

      // Get Handyman User Details
      final handymanDoc = await _db
          .collection('Handyman')
          .doc(request.handymanID)
          .get();
      if (!handymanDoc.exists) throw Exception("Handyman not found");
      final handyman = HandymanModel.fromMap(handymanDoc.data()!);

      final employeeDoc = await _db
          .collection('Employee')
          .doc(handyman.empID)
          .get();
      if (!employeeDoc.exists) throw Exception("Employee not found");
      final employee = EmployeeModel.fromMap(employeeDoc.data()!);

      final handymanUserDoc = await _db
          .collection('User')
          .doc(employee.userID)
          .get();
      if (!handymanUserDoc.exists) throw Exception("Handyman User not found");
      final handymanUser = UserModel.fromMap(handymanUserDoc.data()!);

      // Get Payment (if it exists)
      final payment = await paymentService.getPaymentForBill(bill.billingID);

      // Assemble View Model
      final String serviceRate =
          "RM ${service.servicePrice?.toStringAsFixed(2) ?? '0.00'} / ${service.serviceDuration}";

      return BillDetailViewModel(
        totalPrice: bill.billAmt,
        billStatus: bill.billStatus,
        billingID: bill.billingID,
        customerAddress: request.reqAddress,
        bookingTimestamp: request.reqDateTime,
        serviceTimestamp: request.scheduledDateTime,
        customerName: customerUser.userName,
        customerContact: customerUser.userContact,
        serviceName: service.serviceName,
        serviceRate: serviceRate,
        serviceBasePrice: service.servicePrice ?? 0.0,
        handymanName: handymanUser.userName,
        paymentTimestamp: payment?.payCreatedAt,
      );
    } catch (e) {
      print("Error in getBillDetails: $e");
      rethrow;
    }
  }
}
