import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/databaseModel.dart';

class CustomerService {
  final CollectionReference customerCollection = FirebaseFirestore.instance
      .collection('Customer');
  final CollectionReference userCollection = FirebaseFirestore.instance
      .collection('User');

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
        return CustomerModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error fetching customer: $e');
      throw Exception('Failed to fetch customer: $e');
    }
  }

  Future<Map<String, Map<String, String>>> fetchUserDetailsByCustomerIDs(
    List<String> custIDs,
  ) async {
    final validIds = custIDs.where((id) => id.isNotEmpty).toSet().toList();

    if (validIds.isEmpty) {
      return {};
    }

    try {
      final customerFutures = validIds
          .map((custID) => customerCollection.doc(custID).get())
          .toList();

      final customerDocs = await Future.wait(customerFutures);

      final Map<String, String> custToUserMap = {};
      for (int i = 0; i < customerDocs.length; i++) {
        final doc = customerDocs[i];
        if (doc.exists) {
          final custID = validIds[i];
          final userID =
              (doc.data() as Map<String, dynamic>?)?['userID'] as String?;
          if (userID != null && userID.isNotEmpty) {
            custToUserMap[custID] = userID;
          }
        }
      }

      if (custToUserMap.isEmpty) {
        print('No userIDs found for the given customer IDs');
        return {};
      }

      final userIDs = custToUserMap.values.toSet().toList();
      final userFutures = userIDs
          .map((userID) => userCollection.doc(userID).get())
          .toList();

      final userDocs = await Future.wait(userFutures);

      final Map<String, Map<String, String>> userDetailsMap = {};
      for (int i = 0; i < userDocs.length; i++) {
        final doc = userDocs[i];
        if (doc.exists) {
          final userID = userIDs[i];
          final data = doc.data() as Map<String, dynamic>;
          userDetailsMap[userID] = {
            'name': data['userName'] ?? 'Unknown',
            'contact': data['userContact'] ?? 'N/A',
          };
        }
      }

      final Map<String, Map<String, String>> customerDetailsMap = {};
      for (var entry in custToUserMap.entries) {
        final custID = entry.key;
        final userID = entry.value;

        if (userDetailsMap.containsKey(userID)) {
          customerDetailsMap[custID] = userDetailsMap[userID]!;
        } else {
          customerDetailsMap[custID] = {'name': 'Unknown', 'contact': 'N/A'};
        }
      }

      print('Fetched user details for ${customerDetailsMap.length} customers');
      return customerDetailsMap;
    } catch (e) {
      print('Error fetching user details by customer IDs: $e');
      return {};
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
