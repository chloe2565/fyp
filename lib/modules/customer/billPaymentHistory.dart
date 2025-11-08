import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/billPaymentController.dart';
import '../../model/databaseModel.dart';
import '../../shared/billPaymentFilterDialog.dart';
import '../../shared/helper.dart';
import 'billDetail.dart';
import 'paymentDetail.dart';

class BillPaymentHistoryScreen extends StatefulWidget {
  const BillPaymentHistoryScreen({super.key});

  @override
  State<BillPaymentHistoryScreen> createState() =>
      BillPaymentHistoryScreenState();
}

class BillPaymentHistoryScreenState extends State<BillPaymentHistoryScreen> {
  bool isInitialized = false;
  late BillPaymentController controller;
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
    controller = BillPaymentController();
    initializeController();
    searchController.addListener(onSearchChanged);
  }

  Future<void> initializeController() async {
    await controller.initializeForCustomer();
    if (mounted) {
      setState(() {
        isInitialized = true;
      });
    }
  }

  void onSearchChanged() {
    applyFilters();
  }

  void applyFilters() {
    final query = searchController.text;

    controller.applyFilters(
      searchQuery: query,
      startDate: startDate,
      endDate: endDate,
      minAmount: minAmount,
      maxAmount: maxAmount,
      statusFilter: statusFilter,
      paymentMethodFilter: paymentMethodFilter,
    );
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
            onApply:
                ({
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
                    applyFilters();
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
                applyFilters();
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
    controller.dispose();
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
          final TabController tabController = DefaultTabController.of(
            tabContext,
          );
          tabController.addListener(() {
            if (!tabController.indexIsChanging && mounted) {
              setState(() {
              });
            }
          });

          return ListenableBuilder(
            listenable: controller,
            builder: (context, child) {
              return Scaffold(
                appBar: AppBar(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacementNamed(context, '/custHome');
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
                                buildBillingList(),
                                buildPaymentList(),
                              ],
                            ),
                          ),
                        ],
                      ),
              );
            },
          );
        },
      ),
    );
  }

  // build billing list
  Widget buildBillingList() {
    if (controller.isLoadingBills) {
      return const Center(child: CircularProgressIndicator());
    }

    final bills = controller.filteredBills;

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
      padding: const EdgeInsets.all(12),
      itemCount: bills.length,
      itemBuilder: (context, index) {
        final bill = bills[index];
        return BillingCard(
          bill: bill,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BillDetailScreen(bill)),
            );
          },
        );
      },
    );
  }

  // build payment list
  Widget buildPaymentList() {
    if (controller.isLoadingPayments) {
      return const Center(child: CircularProgressIndicator());
    }

    final payments = controller.filteredPayments;

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
      padding: const EdgeInsets.all(12),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return PaymentCard(
          payment: payment,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentDetailScreen(payment),
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
  static final dateFormat = DateFormat.yMMMMd('en_US');

  @override
  Widget build(BuildContext context) {
    final status = capitalizeFirst(bill.billStatus);
    final statusColor = getStatusColor(bill.billStatus);
    final isPaid = status == 'Paid';
    final isCancelled = status == 'Cancelled';
    final showPayButton = !isPaid && !isCancelled;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Colors.blueGrey,
                      size: 45,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // All text rows
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Billing ID: ${bill.billingID}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        infoRow(
                          Icons.attach_money,
                          'Amount: ${currencyFormat.format(bill.billAmt)}',
                        ),
                        const SizedBox(height: 6),
                        infoRow(
                          Icons.calendar_today,
                          'Due Date: ${dateFormat.format(bill.billDueDate)}',
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            infoRow(
                              isPaid
                                  ? Icons.check_circle
                                  : (isCancelled
                                        ? Icons.cancel
                                        : Icons.info_outline),
                              'Status:',
                              color: statusColor,
                            ),
                            const SizedBox(width: 8),
                            buildStatusBadge(status),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (showPayButton) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Pay Now'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget infoRow(IconData icon, String text, {Color? color}) => Row(
    children: [
      Icon(icon, size: 16, color: color ?? Colors.grey[700]),
      const SizedBox(width: 8),
      Text(
        text,
        style: TextStyle(color: color ?? Colors.grey[600], fontSize: 14),
      ),
    ],
  );
}

class PaymentCard extends StatelessWidget {
  final PaymentModel payment;
  final VoidCallback? onTap;
  static final currencyFormat = NumberFormat.currency(
    locale: 'ms_MY',
    symbol: 'RM ',
  );
  static final dateFormat = DateFormat.yMMMMd('en_US');

  const PaymentCard({required this.payment, this.onTap, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat.jm();
    final status = capitalizeFirst(payment.payStatus);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10.0),
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
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
                child: Icon(Icons.paid, color: Colors.blueGrey[400], size: 28),
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
                      'Billing ID',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      payment.billingID,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),

                  buildStatusBadge(status),
                  const SizedBox(height: 4),

                  Text(
                    dateFormat.format(payment.payCreatedAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    timeFormat.format(payment.payCreatedAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
