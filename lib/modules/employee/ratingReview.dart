import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controller/bill.dart';
import '../../controller/payment.dart';
import '../../model/databaseModel.dart';
import '../../shared/helper.dart';
import 'billDetail.dart';
import 'paymentDetail.dart';

class EmpRatingReviewScreen extends StatefulWidget {
  const EmpRatingReviewScreen({super.key});

  @override
  State<EmpRatingReviewScreen> createState() => EmpRatingReviewScreenState();
}

class EmpRatingReviewScreenState extends State<EmpRatingReviewScreen> {
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
      child: ListenableBuilder(
        listenable: Listenable.merge([billingController, paymentController]),
        builder: (context, child) {
          return Scaffold(
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
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.black,
                    size: 28,
                  ),
                  onPressed: () {
                    // TODO: Implement create new bill/payment action
                  },
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
          );
        },
      ),
    );
  }

  Widget buildBillingList() {
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
                builder: (context) => ChangeNotifierProvider.value(
                  value: billingController,
                  child: EmpBillDetailScreen(bill: bill),
                ),
              ),
            );
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
