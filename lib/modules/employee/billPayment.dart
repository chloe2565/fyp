import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controller/bill.dart';
import '../../controller/payment.dart';
import '../../model/databaseModel.dart';
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
  late BillController billingController;
  late PaymentController paymentController;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    billingController = BillController();
    paymentController = PaymentController();
    initializeController();
    searchController.addListener(onSearchChanged);
  }

  Future<void> initializeController() async {
    await Future.wait([
      billingController.initializeForEmployee(),
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
    billingController.onSearchChanged(query);
    paymentController.onSearchChanged(query);
  }

  @override
  void dispose() {
    billingController.dispose();
    paymentController.dispose();
    searchController.removeListener(onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
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
                  final RenderBox button =
                      context.findRenderObject() as RenderBox;
                  final RenderBox overlay =
                      Overlay.of(context).context.findRenderObject()
                          as RenderBox;

                  final RelativeRect position = RelativeRect.fromRect(
                    Rect.fromPoints(
                      button.localToGlobal(Offset(0, button.size.height)),
                      button.localToGlobal(
                        button.size.bottomRight(Offset.zero),
                      ),
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
                            billingController.initializeForEmployee();
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
                            paymentController.initializeForEmployee();
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
                  ),
                  buildPrimaryTabBar(
                    context: context,
                    tabs: ['Billing', 'Payment'],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [buildBillingList(), buildPaymentList()],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget buildBillingList() {
    return ListenableBuilder(
      listenable: billingController,
      builder: (context, child) {
        if (billingController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final bills = billingController.filteredBills;

        if (bills.isEmpty) {
          return const Center(
            child: Text(
              'No billing records found.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bills.length,
          itemBuilder: (context, index) {
            final bill = bills[index];
            return BillingCard(
              bill: bill,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmpBillDetailScreen(bill: bill),
                  ),
                ).then((_) {
                  print("Returned to Bill List, refreshing...");
                  initializeController();
                });
              },
            );
          },
        );
      },
    );
  }

  Widget buildPaymentList() {
    return ListenableBuilder(
      listenable: paymentController,
      builder: (context, child) {
        if (paymentController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final payments = paymentController.filteredPayments;

        if (payments.isEmpty) {
          return const Center(
            child: Text(
              'No payment records found.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            return PaymentCard(
              payment: payment,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider.value(
                      value: paymentController,
                      child: EmpPaymentDetailScreen(payment: payment),
                    ),
                  ),
                ).then((_) {
                  print("Returned to Payment List, refreshing...");
                  initializeController();
                });
              },
            );
          },
        );
      },
    );
  }
}

class BillingCard extends StatelessWidget {
  final BillingModel bill;
  final VoidCallback onTap;
  const BillingCard({required this.bill, required this.onTap, Key? key})
    : super(key: key);

  static final currencyFormat = NumberFormat.currency(
    locale: 'ms_MY',
    symbol: 'RM ',
  );

  static final dateFormat = DateFormat('dd MMM yyyy');
  static final timeFormat = DateFormat('hh:mm a');

  @override
  Widget build(BuildContext context) {
    final status = capitalizeFirst(bill.billStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blueGrey[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.receipt_long, color: Colors.blueGrey),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.billingID,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Service Request ID',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bill.reqID,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(bill.billAmt),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  buildStatusBadge(status),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(bill.billDueDate),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    timeFormat.format(bill.billDueDate),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentCard extends StatelessWidget {
  final PaymentModel payment;
  final VoidCallback? onTap;

  const PaymentCard({required this.payment, this.onTap, Key? key})
    : super(key: key);

  static final currencyFormat = NumberFormat.currency(
    locale: 'ms_MY',
    symbol: 'RM ',
  );
  static final dateFormat = DateFormat('dd MMM yyyy');
  static final timeFormat = DateFormat('hh:mm a');

  @override
  Widget build(BuildContext context) {
    final status = capitalizeFirst(payment.payStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blueGrey[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.paid, color: Colors.blueGrey),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.payMethod,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Billing ID',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      payment.billingID,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(payment.payAmt),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  buildStatusBadge(status),
                  const SizedBox(height: 4),
                  Text(
                    '${dateFormat.format(payment.payCreatedAt)} ${timeFormat.format(payment.payCreatedAt)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
