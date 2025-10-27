import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controller/bill.dart';
import '../../controller/payment.dart';
import '../../model/databaseModel.dart';
import '../../shared/helper.dart';
import 'billDetail.dart';

class BillPaymentHistoryScreen extends StatefulWidget {
  const BillPaymentHistoryScreen({super.key});

  @override
  State<BillPaymentHistoryScreen> createState() =>
      BillPaymentHistoryScreenState();
}

class BillPaymentHistoryScreenState extends State<BillPaymentHistoryScreen> {
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
      billingController.initialize(),
      paymentController.initialize(),
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
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
              ),
              title: const Text(
                'Bill and Payment History',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
            ),
            body: !isInitialized
                ? const Center(child: CircularProgressIndicator())
                : (billingController.isFiltering ||
                      paymentController.isFiltering)
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  )
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

  // build billing list
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
      padding: const EdgeInsets.all(12),
      itemCount: bills.length,
      itemBuilder: (context, index) {
        final bill = bills[index];
        return BillingCard(
          bill: bill,
          onPayPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider.value(
                  value: billingController, 
                  child: BillDetailScreen(bill),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // build payment list
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
      padding: const EdgeInsets.all(12.0),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return PaymentCard(payment: payment);
      },
    );
  }
}

// Billing card widget
class BillingCard extends StatelessWidget {
  final BillingModel bill;
  final VoidCallback onPayPressed;

  const BillingCard({required this.bill, required this.onPayPressed});

  @override
  Widget build(BuildContext context) {
    final String status = bill.billStatus.toLowerCase();
    final bool isPaid = status == 'paid';
    final bool isCancelled = status == 'cancelled';
    final bool isCompleted = status == 'completed';
    final bool showPayButton = !isPaid && !isCancelled && !isCompleted;
    final currencyFormat = NumberFormat.currency(
      locale: 'ms_MY',
      symbol: 'RM ',
    );
    final dateFormat = DateFormat.yMMMd();

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2.0,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Billing ID: ${bill.billingID}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            buildInfoRow(
              Icons.attach_money,
              'Amount: ${currencyFormat.format(bill.billAmt)}',
            ),
            const SizedBox(height: 6),
            buildInfoRow(
              Icons.calendar_today,
              'Due Date: ${dateFormat.format(bill.billDueDate)}',
            ),
            const SizedBox(height: 6),
            buildInfoRow(
              isPaid || isCompleted
                  ? Icons.check_circle
                  : (isCancelled ? Icons.cancel : Icons.info_outline),
              'Status: ${bill.billStatus}',
              color: (isPaid || isCompleted)
                  ? Colors.green
                  : (isCancelled ? Colors.red[700] : Colors.orange[700]),
            ),
            
            if (showPayButton) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: onPayPressed, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text('Pay Now'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildInfoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: color ?? Colors.black87, fontSize: 14),
        ),
      ],
    );
  }
}

class PaymentCard extends StatelessWidget {
  final PaymentModel payment;

  const PaymentCard({required this.payment});

  Widget buildStatusBadge(String status) {
    Color backgroundColor;
    Color foregroundColor;
    switch (status.toLowerCase()) {
      case 'success':
        backgroundColor = Colors.green[50]!;
        foregroundColor = Colors.green[700]!;
        break;
      case 'pending':
        backgroundColor = Colors.orange[50]!;
        foregroundColor = Colors.orange[700]!;
        break;
      default:
        backgroundColor = Colors.red[50]!;
        foregroundColor = Colors.red[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'ms_MY',
      symbol: 'RM ',
    );
    final dateFormat = DateFormat('d MMM yyyy'); // e.g., 17 Sep 2024
    final timeFormat = DateFormat.jm(); // e.g., 11:21 AM

    return Card(
      margin: const EdgeInsets.only(bottom: 10.0),
      elevation: 1.5,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Icon(
                Icons.camera_alt_outlined,
                color: Colors.blueGrey[400],
                size: 28,
              ),
            ),
            const SizedBox(width: 16.0),
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
                    'Billing ID ${payment.billingID}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${dateFormat.format(payment.payCreatedAt)}   ${timeFormat.format(payment.payCreatedAt)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  currencyFormat.format(payment.payAmt),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                buildStatusBadge(payment.payStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
