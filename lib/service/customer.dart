import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/customer.dart';

class CustomerService {
    final CollectionReference customerCollection;

  // Default to use FirebaseFirestore.instance if none is provided
  CustomerService([FirebaseFirestore? db])
      : customerCollection = (db ?? FirebaseFirestore.instance).collection('Customer');

  // Add or update customer
  Future<void> addCustomer(CustomerModel customer) async {
    try {
      await customerCollection.doc(customer.custID).set(customer.toMap());
      print("Customer ${customer.custID} saved successfully.");
    } catch (e) {
      print('Error saving customer: $e');
      throw Exception('Failed to save customer: $e');
    }
  }

  // Get customer by ID
  Future<CustomerModel?> getCustomer(String custID) async {
    try {
      DocumentSnapshot doc = await customerCollection.doc(custID).get();
      if (doc.exists) {
        return CustomerModel.fromMap(doc.data() as Map<String, dynamic>, custID);
      }
      return null;
    } catch (e) {
      print('Error fetching customer: $e');
      throw Exception('Failed to fetch customer: $e');
    }
  }

  // Delete customer by ID
  Future<void> deleteCustomer(String custID) async {
    try {
      await customerCollection.doc(custID).delete();
      print('Customer $custID deleted successfully');
    } catch (e) {
      print('Error deleting customer: $e');
      throw Exception('Failed to delete customer: $e');
    }
  }
}