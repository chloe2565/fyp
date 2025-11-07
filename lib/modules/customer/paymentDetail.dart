import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controller/payment.dart';
import '../../model/databaseModel.dart';
import '../../model/paymentDetailViewModel.dart';
import '../../shared/helper.dart';

class PaymentDetailScreen extends StatefulWidget {
  final PaymentModel payment;
  const PaymentDetailScreen(this.payment, {super.key});

  @override
  State<PaymentDetailScreen> createState() => PaymentDetailScreenState();
}

class PaymentDetailScreenState extends State<PaymentDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PaymentController>(
        context,
        listen: false,
      ).loadPaymentDetails(widget.payment);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment Record Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      body: Consumer<PaymentController>(
        builder: (context, controller, child) {
          if (controller.detailIsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.detailError != null) {
            return Center(child: Text(controller.detailError!));
          }
          if (controller.detailModel == null) {
            return const Center(child: Text('No details found.'));
          }

          return buildPaymentDetails(
            context,
            controller.detailModel!,
            controller,
          );
        },
      ),
    );
  }

  Widget buildPaymentDetails(
    BuildContext context,
    PaymentDetailViewModel viewModel,
    PaymentController controller,
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
                // Payment status
                buildPaymentStatusCard(viewModel),
                const SizedBox(height: 15),

                // Address
                buildAddressCard(viewModel),
                const SizedBox(height: 15),

                buildServiceRequestCard(context, viewModel),
                const SizedBox(height: 15),

                // Price and time breakdown
                buildPaymentSummaryCard(
                  context,
                  viewModel,
                  currencyFormat,
                  dateFormat,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Widget buildPaymentStatusCard(PaymentDetailViewModel viewModel) {
  final String status = viewModel.payStatus.toLowerCase();
  final Color foregroundColor = getStatusColor(status);
  String text;

  switch (status) {
    case 'paid':
      text = 'Payment Successful';
      break;
    case 'failed':
      text = 'Payment Failed';
      break;
    case 'cancelled':
      text = 'Payment Cancelled';
      break;
    case 'pending':
      text = 'Payment Pending';
      break;
    default:
      text = capitalizeFirst(status);
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Row(
      children: [
        Icon(Icons.wallet, color: foregroundColor, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: foregroundColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}

Widget buildAddressCard(PaymentDetailViewModel viewModel) {
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

Widget buildServiceRequestCard(
  BuildContext context,
  PaymentDetailViewModel viewModel,
) {
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
                    'Handyman: ${viewModel.handymanName}',
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
                    'RM ${viewModel.serviceBasePrice.toStringAsFixed(2)} / hour',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget buildPaymentSummaryCard(
  BuildContext context,
  PaymentDetailViewModel viewModel,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Billing ID',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),

            Text(
              viewModel.billingID,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Price Breakdown
        buildPriceRow(
          context,
          'Service Price',
          currencyFormat.format(viewModel.serviceBasePrice),
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

        ...[
        const SizedBox(height: 12),
        buildTimeRow(
          'Payment Time',
          dateFormat.format(viewModel.paymentTimestamp),
        ),
      ],
      ],
    ),
  );
}
