import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controller/bill.dart';
import '../../model/billDetailViewModel.dart';
import '../../model/databaseModel.dart';
import '../../shared/helper.dart';

class BillDetailScreen extends StatefulWidget {
  final BillingModel bill;
  const BillDetailScreen(this.bill, {super.key});

  @override
  State<BillDetailScreen> createState() => BillDetailScreenState();
}

class BillDetailScreenState extends State<BillDetailScreen> {
  late BillController controller;

  @override
  void initState() {
    super.initState();
    controller = BillController();
    controller.addListener(onControllerChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadBillDetails(widget.bill);
    });
  }

  void onControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Billing Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: buildBody(context),
    );
  }

  Widget buildBody(BuildContext context) {
    if (controller.detailIsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.detailError != null) {
      return Center(child: Text(controller.detailError!));
    }
    if (controller.detailViewModel == null) {
      return const Center(child: Text('No details found.'));
    }

    return buildBillDetails(
      context,
      controller.detailViewModel!,
      controller,
    );
  }

  Widget buildBillDetails(
    BuildContext context,
    BillDetailViewModel viewModel,
    BillController controller,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'ms_MY',
      symbol: 'RM ',
    );
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address Section
                buildAddressCard(viewModel),
                const SizedBox(height: 15),

                buildServiceRequestCard(context, viewModel),
                const SizedBox(height: 15),

                // Price and time breakdown
                buildBillingSummaryCard(
                  context,
                  viewModel,
                  currencyFormat,
                  dateFormat,
                ),
              ],
            ),
          ),
        ),
        // Pay Now Button
        if (viewModel.isPaymentPending) buildPayNowButton(context, controller),
      ],
    );
  }
}

Widget buildAddressCard(BillDetailViewModel viewModel) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(5),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          spreadRadius: 2,
          blurRadius: 5,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.location_on_outlined, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                viewModel.customerAddress,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${viewModel.customerName} ${viewModel.customerContact}',
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildPayNowButton(BuildContext context, BillController controller) {
  return Container(
    padding: const EdgeInsets.all(16.0),
    width: double.infinity,
    child: ElevatedButton(
      onPressed: () => controller.navigateToPayment(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        'Pay Now',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  );
}

Widget buildServiceRequestCard(
  BuildContext context,
  BillDetailViewModel viewModel,
) {
  final bookingDateFormat = DateFormat('MMMM dd, yyyy');
  final bookingTimeFormat = DateFormat('hh:mm a');
  final icon = ServiceHelper.getIconForService(viewModel.serviceName);
  final bgColor = ServiceHelper.getColorForService(viewModel.serviceName);

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(5),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          spreadRadius: 2,
          blurRadius: 5,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Request',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.black, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    viewModel.serviceName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    'Handyman',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    'Booking Date',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    'Booking Time',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RM ${viewModel.serviceBasePrice?.toStringAsFixed(2) ?? 0.00} / hour',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    viewModel.handymanName,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    bookingDateFormat.format(
                      viewModel.serviceCompleteTimestamp,
                    ),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    bookingTimeFormat.format(
                      viewModel.serviceCompleteTimestamp,
                    ),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget buildBillingSummaryCard(
  BuildContext context,
  BillDetailViewModel viewModel,
  NumberFormat currencyFormat,
  DateFormat dateFormat,
) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(5),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          spreadRadius: 2,
          blurRadius: 5,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Price Breakdown
        buildPriceRow(
          context,
          'Service Price',
          currencyFormat.format(viewModel.serviceBasePrice ?? 0.0),
        ),
        const SizedBox(height: 12),

        buildPriceRow(
          context,
          'Outstation Fee',
          currencyFormat.format(viewModel.outstationFee),
        ),
        const SizedBox(height: 12),

        buildPriceRow(
          context,
          'Total',
          currencyFormat.format(viewModel.totalPrice),
          isTotal: true,
        ),

        Divider(height: 24, thickness: 1, color: Colors.grey[300]),

        buildTimeRow(
          'Booking Time',
          dateFormat.format(viewModel.bookingTimestamp),
        ),
        const SizedBox(height: 12),

        buildTimeRow(
          'Service Completed Time',
          dateFormat.format(viewModel.serviceCompleteTimestamp),
        ),
        if (viewModel.paymentTimestamp != null) ...[
          const SizedBox(height: 12),
          buildTimeRow(
            'Payment Time',
            dateFormat.format(viewModel.paymentTimestamp!),
          ),
        ],
      ],
    ),
  );
}
