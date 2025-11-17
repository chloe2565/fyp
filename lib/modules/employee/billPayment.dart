import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/databaseModel.dart';
import '../../controller/bill.dart';
import '../../controller/payment.dart';
import '../../shared/billPaymentFilterDialog.dart';
import '../../shared/helper.dart';
import 'addNewBill.dart';
import 'addNewPayment.dart';
import 'billDetail.dart';
import 'paymentDetail.dart';

class EmpBillPaymentScreen extends StatefulWidget {
  const EmpBillPaymentScreen({super.key});

  @override
  State<EmpBillPaymentScreen> createState() => EmpBillPaymentScreenState();
}

class EmpBillPaymentScreenState extends State<EmpBillPaymentScreen> {
  bool isInitialized = false;
  late BillController billController;
  late PaymentController paymentController;
  final TextEditingController searchController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;
  double? minAmount;
  double? maxAmount;
  Map<String, String> statusFilter = {};
  Map<String, String> paymentMethodFilter = {};

  @override
  void initState() {
    super.initState();
    billController = BillController();
    paymentController = PaymentController();
    initializeControllers();
    searchController.addListener(onSearchChanged);
  }

  Future<void> initializeControllers() async {
    await Future.wait([
      billController.initializeForEmployee(),
      paymentController.initializeForEmployee(),
    ]);
    if (mounted) {
      setState(() {
        isInitialized = true;
      });
    }
  }

  void onSearchChanged() {
    final query = searchController.text;
    billController.onSearchChanged(query);
    paymentController.onSearchChanged(query);
  }

  void showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: BillPaymentFilterDialog(
            initialStartDate: startDate,
            initialEndDate: endDate,
            initialMinAmount: minAmount,
            initialMaxAmount: maxAmount,
            initialStatusFilter: statusFilter,
            initialPaymentMethodFilter: paymentMethodFilter,
            onApply: ({
              DateTime? startDate,
              DateTime? endDate,
              double? minAmount,
              double? maxAmount,
              Map<String, String>? statusFilter,
              Map<String, String>? paymentMethodFilter,
            }) {
              if (mounted) {
                setState(() {
                  this.startDate = startDate;
                  this.endDate = endDate;
                  this.minAmount = minAmount;
                  this.maxAmount = maxAmount;
                  this.statusFilter = statusFilter ?? {};
                  this.paymentMethodFilter = paymentMethodFilter ?? {};
                });
              }
            },
            onReset: () {
              if (mounted) {
                setState(() {
                  startDate = null;
                  endDate = null;
                  minAmount = null;
                  maxAmount = null;
                  statusFilter = {};
                  paymentMethodFilter = {};
                });
              }
            },
          ),
        );
      },
    );
  }

  int get numberOfFilters {
    int count = 0;
    if (startDate != null || endDate != null) count++;
    if (minAmount != null || maxAmount != null) count++;
    if (statusFilter.isNotEmpty) count++;
    if (paymentMethodFilter.isNotEmpty) count++;
    return count;
  }

  @override
  void dispose() {
    billController.dispose();
    paymentController.dispose();
    searchController.removeListener(onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFilter = numberOfFilters > 0;

    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (BuildContext tabContext) {
          final TabController tabController = DefaultTabController.of(tabContext);
          tabController.addListener(() {
            if (!tabController.indexIsChanging && mounted) {
              setState(() {});
            }
          });

          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/empHome');
                  }
                },
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: const Text(
                'Bill and Payment',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
              actions: [
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.black,
                      size: 28,
                    ),
                    onPressed: () async {
                      final RenderBox button = context.findRenderObject() as RenderBox;
                      final RenderBox overlay =
                          Overlay.of(context).context.findRenderObject() as RenderBox;

                      final RelativeRect position = RelativeRect.fromRect(
                        Rect.fromPoints(
                          button.localToGlobal(Offset(0, button.size.height)),
                          button.localToGlobal(button.size.bottomRight(Offset.zero)),
                        ),
                        Offset.zero & overlay.size,
                      );

                      final selected = await showMenu<String>(
                        context: context,
                        position: position,
                        items: [
                          PopupMenuItem<String>(
                            value: 'bill',
                            child: Row(
                              children: const [
                                SizedBox(width: 8),
                                Text('Add Bill'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'payment',
                            child: Row(
                              children: const [
                                SizedBox(width: 8),
                                Text('Add Payment'),
                              ],
                            ),
                          ),
                        ],
                      );

                      if (selected == 'bill') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EmpAddBillScreen(
                              onBillAdded: () {
                                initializeControllers();
                              },
                            ),
                          ),
                        );
                      } else if (selected == 'payment') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EmpAddPaymentScreen(
                              onPaymentAdded: () {
                                initializeControllers();
                              },
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            body: !isInitialized
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      buildSearchField(
                        context: context,
                        controller: searchController,
                        onFilterPressed: showFilterDialog,
                        hasFilter: hasFilter,
                        numberOfFilters: numberOfFilters,
                      ),
                      const SizedBox(height: 16),
                      buildPrimaryTabBar(
                        context: context,
                        tabs: ['Billing', 'Payment'],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            ListenableBuilder(
                              listenable: billController,
                              builder: (context, child) => buildBillingList(),
                            ),
                            ListenableBuilder(
                              listenable: paymentController,
                              builder: (context, child) => buildPaymentList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget buildBillingList() {
    if (billController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final bills = billController.filteredBills;

    if (bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              searchController.text.isNotEmpty || numberOfFilters > 0
                  ? 'No billing records found.'
                  : 'No billing records found.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bills.length,
      itemBuilder: (context, index) {
        final bill = bills[index];
        return EnhancedBillingCard(
          bill: bill,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmpBillDetailScreen(bill: bill),
              ),
            ).then((_) {
              print("Returned to Bill List, refreshing...");
              initializeControllers();
            });
          },
        );
      },
    );
  }

  Widget buildPaymentList() {
    if (paymentController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final payments = paymentController.filteredPayments;

    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              searchController.text.isNotEmpty || numberOfFilters > 0
                  ? 'No payment records found.'
                  : 'No payment records found.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return EnhancedPaymentCard(
          payment: payment,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmpPaymentDetailScreen(payment: payment),
              ),
            ).then((_) {
              print("Returned to Payment List, refreshing...");
              initializeControllers();
            });
          },
        );
      },
    );
  }
}

// Enhanced Billing Card with service request details
class EnhancedBillingCard extends StatefulWidget {
  final BillingModel bill;
  final VoidCallback onTap;

  const EnhancedBillingCard({
    required this.bill,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  State<EnhancedBillingCard> createState() => _EnhancedBillingCardState();
}

class _EnhancedBillingCardState extends State<EnhancedBillingCard> {
  static final currencyFormat = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
  static final dateFormat = DateFormat('dd MMM yyyy');
  static final timeFormat = DateFormat('hh:mm a');
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? serviceName;
  String? customerName;
  String? handymanName;
  DateTime? scheduledDate;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServiceRequestDetails();
  }

  Future<void> _loadServiceRequestDetails() async {
    try {
      // Get Service Request
      final reqDoc = await _db.collection('ServiceRequest').doc(widget.bill.reqID).get();
      if (!reqDoc.exists) throw Exception('Service Request not found');
      final request = ServiceRequestModel.fromMap(reqDoc.data()!);

      // Get Service Name
      final serviceDoc = await _db.collection('Service').doc(request.serviceID).get();
      if (serviceDoc.exists) {
        final service = ServiceModel.fromMap(serviceDoc.data()!);
        serviceName = service.serviceName;
      }

      // Get Customer Name
      final customerDoc = await _db.collection('Customer').doc(request.custID).get();
      if (customerDoc.exists) {
        final customer = CustomerModel.fromMap(customerDoc.data()!);
        final customerUserDoc = await _db.collection('User').doc(customer.userID).get();
        if (customerUserDoc.exists) {
          final customerUser = UserModel.fromMap(customerUserDoc.data()!);
          customerName = customerUser.userName;
        }
      }

      // Get Handyman Name
      if (request.handymanID!.isNotEmpty) {
        final handymanDoc = await _db.collection('Handyman').doc(request.handymanID).get();
        if (handymanDoc.exists) {
          final handyman = HandymanModel.fromMap(handymanDoc.data()!);
          final employeeDoc = await _db.collection('Employee').doc(handyman.empID).get();
          if (employeeDoc.exists) {
            final employee = EmployeeModel.fromMap(employeeDoc.data()!);
            final handymanUserDoc = await _db.collection('User').doc(employee.userID).get();
            if (handymanUserDoc.exists) {
              final handymanUser = UserModel.fromMap(handymanUserDoc.data()!);
              handymanName = handymanUser.userName;
            }
          }
        }
      }

      scheduledDate = request.scheduledDateTime;

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading service request details: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = capitalizeFirst(widget.bill.billStatus);
    final icon = serviceName != null ? ServiceHelper.getIconForService(serviceName!) : Icons.receipt_long;
    final bgColor = serviceName != null ? ServiceHelper.getColorForService(serviceName!) : Colors.blueGrey[50]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with Icon and Amount
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.black87),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLoading ? 'Loading...' : (serviceName ?? 'Unknown Service'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.bill.billingID,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(widget.bill.billAmt),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      buildStatusBadge(status),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Service Request Details
              if (!isLoading) ...[
                _buildDetailRow(Icons.person, 'Customer', customerName ?? 'Unknown'),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.engineering, 'Handyman', handymanName ?? 'Not Assigned'),
                const SizedBox(height: 8),
                _buildDetailRow(
                  Icons.calendar_today,
                  'Service Date',
                  scheduledDate != null
                      ? '${dateFormat.format(scheduledDate!)} at ${timeFormat.format(scheduledDate!)}'
                      : 'N/A',
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  Icons.access_time,
                  'Due Date',
                  '${dateFormat.format(widget.bill.billDueDate)} at ${timeFormat.format(widget.bill.billDueDate)}',
                ),
              ] else ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// Enhanced Payment Card with service request details
class EnhancedPaymentCard extends StatefulWidget {
  final PaymentModel payment;
  final VoidCallback? onTap;

  const EnhancedPaymentCard({
    required this.payment,
    this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  State<EnhancedPaymentCard> createState() => _EnhancedPaymentCardState();
}

class _EnhancedPaymentCardState extends State<EnhancedPaymentCard> {
  static final currencyFormat = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
  static final dateFormat = DateFormat('dd MMM yyyy');
  static final timeFormat = DateFormat('hh:mm a');
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? serviceName;
  String? customerName;
  String? reqID;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentDetails();
  }

  Future<void> _loadPaymentDetails() async {
    try {
      // Get Billing to find reqID
      final billingDoc = await _db.collection('Billing').doc(widget.payment.billingID).get();
      if (!billingDoc.exists) throw Exception('Billing not found');
      final billing = BillingModel.fromMap(billingDoc.data()!);
      reqID = billing.reqID;

      // Get Service Request
      final reqDoc = await _db.collection('ServiceRequest').doc(billing.reqID).get();
      if (!reqDoc.exists) throw Exception('Service Request not found');
      final request = ServiceRequestModel.fromMap(reqDoc.data()!);

      // Get Service Name
      final serviceDoc = await _db.collection('Service').doc(request.serviceID).get();
      if (serviceDoc.exists) {
        final service = ServiceModel.fromMap(serviceDoc.data()!);
        serviceName = service.serviceName;
      }

      // Get Customer Name
      final customerDoc = await _db.collection('Customer').doc(request.custID).get();
      if (customerDoc.exists) {
        final customer = CustomerModel.fromMap(customerDoc.data()!);
        final customerUserDoc = await _db.collection('User').doc(customer.userID).get();
        if (customerUserDoc.exists) {
          final customerUser = UserModel.fromMap(customerUserDoc.data()!);
          customerName = customerUser.userName;
        }
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading payment details: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = capitalizeFirst(widget.payment.payStatus);
    final icon = serviceName != null ? ServiceHelper.getIconForService(serviceName!) : Icons.paid;
    final bgColor = serviceName != null ? ServiceHelper.getColorForService(serviceName!) : Colors.blueGrey[50]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with Icon and Amount
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.black87),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLoading ? 'Loading...' : (serviceName ?? 'Unknown Service'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.payment.payID,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(widget.payment.payAmt),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      buildStatusBadge(status),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Payment Details
              if (!isLoading) ...[
                _buildDetailRow(Icons.person, 'Customer', customerName ?? 'Unknown'),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.payment, 'Method', widget.payment.payMethod),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.receipt, 'Request ID', reqID ?? 'N/A'),
                const SizedBox(height: 8),
                _buildDetailRow(
                  Icons.access_time,
                  'Paid On',
                  '${dateFormat.format(widget.payment.payCreatedAt)} at ${timeFormat.format(widget.payment.payCreatedAt)}',
                ),
              ] else ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}