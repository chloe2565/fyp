import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/databaseModel.dart';
import '../../shared/billPaymentController.dart';
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
  late BillPaymentController controller;
  final TextEditingController searchController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;
  double? minAmount;
  double? maxAmount;
  Map<String, String> statusFilter = {};
  Map<String, String> paymentMethodFilter = {};

  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    controller = BillPaymentController();
    initializeController();
    searchController.addListener(onSearchChanged);
  }

  Future<void> initializeController() async {
    await controller.initializeForEmployee();
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
                _currentTabIndex = tabController.index;
              });
            }
          });

          return ListenableBuilder(
            listenable: controller,
            builder: (context, child) {
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
                          final RenderBox button =
                              context.findRenderObject() as RenderBox;
                          final RenderBox overlay =
                              Overlay.of(context).context.findRenderObject()
                                  as RenderBox;

                          final RelativeRect position = RelativeRect.fromRect(
                            Rect.fromPoints(
                              button.localToGlobal(
                                Offset(0, button.size.height),
                              ),
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
                                    initializeController();
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
                                    initializeController();
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
  }

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
                builder: (context) => EmpPaymentDetailScreen(payment: payment),
              ),
            ).then((_) {
              print("Returned to Payment List, refreshing...");
              initializeController();
            });
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
