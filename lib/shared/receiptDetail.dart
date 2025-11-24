import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/databaseModel.dart';
import '../../model/paymentDetailViewModel.dart';
import '../../controller/payment.dart';
import '../../shared/fullScreenImage.dart';
import '../../service/image_service.dart';
import 'helper.dart';

class ReceiptDetailScreen extends StatefulWidget {
  final PaymentModel payment;

  const ReceiptDetailScreen({super.key, required this.payment});

  @override
  State<ReceiptDetailScreen> createState() => ReceiptDetailScreenState();
}

class ReceiptDetailScreenState extends State<ReceiptDetailScreen> {
  final PaymentController controller = PaymentController();
  static final currencyFormat = NumberFormat("#,##0.00", "en_MY");
  static final dateTimeFormat = DateFormat('MMMM dd, yyyy hh:mm a');

  @override
  void initState() {
    super.initState();
    controller.loadPaymentDetails(widget.payment);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Payment Receipt'),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          if (controller.detailLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.detailErrorText != null) {
            return Center(
              child: Text(
                controller.detailErrorText!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (controller.detailModel == null) {
            return const Center(child: Text('Receipt details not available'));
          }

          return buildReceiptBody(context, controller.detailModel!);
        },
      ),
    );
  }

  Widget buildReceiptBody(
    BuildContext context,
    PaymentDetailViewModel details,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Receipt Header (Success Icon & Total)
                buildReceiptHeader(details),

                const Divider(height: 1, color: Colors.grey),

                // Customer Info Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: buildCustomerInfoSection(context, details),
                ),

                const Divider(height: 1, indent: 20, endIndent: 20),

                // Service Info Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: buildServiceInfoSection(context, details),
                ),

                const Divider(height: 1, indent: 20, endIndent: 20),

                // Payment Info Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: buildPaymentInfoSection(context, details),
                ),

                buildDashedLine(),

                // Price Breakdown Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: buildPriceBreakdownSection(context, details),
                ),

                // Payment Proof (If exists)
                if (widget.payment.payMediaProof.isNotEmpty) ...[
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: buildPaymentProofSection(
                      context,
                      widget.payment.payMediaProof,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget buildReceiptHeader(PaymentDetailViewModel details) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.green, size: 35),
          ),
          const SizedBox(height: 16),
          Text(
            "Payment Success",
            style: TextStyle(
              fontSize: 16,
              color: Colors.green[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "RM ${currencyFormat.format(details.totalPrice)}",
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPaymentInfoSection(
    BuildContext context,
    PaymentDetailViewModel details,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PAYMENT DETAILS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        buildInfoRow(
          Icons.info_outline,
          'Status',
          capitalizeFirst(details.payStatus),
          valueColor: getStatusColor(details.payStatus),
        ),
        const SizedBox(height: 12),
        buildInfoRow(Icons.credit_card, 'Method', details.payMethod),
        const SizedBox(height: 12),
        buildInfoRow(
          Icons.access_time,
          'Date',
          Formatter.formatDateTime(details.paymentTimestamp),
        ),
      ],
    );
  }

  Widget buildServiceInfoSection(
    BuildContext context,
    PaymentDetailViewModel details,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SERVICE DETAILS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        buildInfoRow(Icons.home_repair_service, 'Service', details.serviceName),
        const SizedBox(height: 12),
        buildInfoRow(Icons.person, 'Handyman', details.handymanName),
        const SizedBox(height: 12),
        buildInfoRow(
          Icons.calendar_today,
          'Service Date',
          Formatter.formatDateTime(details.bookingTimestamp),
        ),
      ],
    );
  }

  Widget buildCustomerInfoSection(
    BuildContext context,
    PaymentDetailViewModel details,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CUSTOMER',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        buildInfoRow(Icons.person, 'Name', details.customerName),
        const SizedBox(height: 12),
        buildInfoRow(
          Icons.phone,
          'Contact',
          Formatter.formatPhoneNumber(details.customerContact),
        ),
        const SizedBox(height: 12),
        buildInfoRow(Icons.location_on, 'Address', details.customerAddress),
      ],
    );
  }

  Widget buildPaymentProofSection(BuildContext context, String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ATTACHMENT',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullScreenGalleryViewer(
                  imagePaths: [imageUrl],
                  initialIndex: 0,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.toNetworkImage(
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildPriceBreakdownSection(
    BuildContext context,
    PaymentDetailViewModel details,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Service Price',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(
              'RM ${currencyFormat.format(details.serviceBasePrice)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Outstation Fee',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(
              'RM ${currencyFormat.format(details.outstationFee)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Paid',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'RM ${currencyFormat.format(details.totalPrice)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildDashedLine() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 6.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.horizontal,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: dashHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.grey[300]),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    controller.clearDetails();
    super.dispose();
  }
}
