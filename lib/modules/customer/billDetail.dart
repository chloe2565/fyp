import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controller/bill.dart';
import '../../model/billDetailViewModel.dart';
import '../../model/databaseModel.dart';

class BillDetailScreen extends StatefulWidget {
  final BillingModel bill;
  const BillDetailScreen(this.bill, {super.key});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<BillController>(
      context,
      listen: false,
    ).loadBillDetails(widget.bill);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Billing Details',
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
      body: Consumer<BillController>(
        builder: (context, controller, child) {
          if (controller.detailIsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.detailError != null) {
            return Center(child: Text(controller.detailError!));
          }
          if (controller.detailViewModel == null) {
            return const Center(child: Text('No details found.'));
          }

          return _buildBillDetails(
            context,
            controller.detailViewModel!,
            controller,
          );
        },
      ),
    );
  }

  Widget _buildBillDetails(
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
                _buildAddressCard(viewModel),
                const SizedBox(height: 24),
                // Service Request Section
                const Text(
                  'Service Request',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildServiceRequestCard(viewModel),
                const SizedBox(height: 24),
                // Price Breakdown
                _buildPriceRow(
                  'Service Price',
                  currencyFormat.format(viewModel.serviceBasePrice),
                ),
                const SizedBox(height: 12),
                _buildPriceRow(
                  'Outstation Fee',
                  currencyFormat.format(viewModel.outstationFee),
                ),
                const Divider(height: 24, thickness: 1),
                _buildPriceRow(
                  'Total',
                  currencyFormat.format(viewModel.totalPrice),
                  isTotal: true,
                ),
                const SizedBox(height: 32),
                // Time Breakdown
                _buildTimeRow(
                  'Booking Time',
                  dateFormat.format(viewModel.bookingTimestamp),
                ),
                const SizedBox(height: 12),
                _buildTimeRow(
                  'Service Completed Time',
                  dateFormat.format(viewModel.serviceTimestamp),
                ),
                const SizedBox(height: 12),
                if (viewModel.paymentTimestamp != null)
                  _buildTimeRow(
                    'Payment Time',
                    dateFormat.format(viewModel.paymentTimestamp!),
                  ),
              ],
            ),
          ),
        ),
        // Pay Now Button
        if (viewModel.isPaymentPending) _buildPayNowButton(context, controller),
      ],
    );
  }

  Widget _buildAddressCard(BillDetailViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
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
                    fontSize: 15,
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
          Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
        ],
      ),
    );
  }

  Widget _buildServiceRequestCard(BillDetailViewModel viewModel) {
    final bookingDateFormat = DateFormat('MMMM dd, yyyy');
    final bookingTimeFormat = DateFormat('hh:mm a');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.pink[50],
              borderRadius: BorderRadius.circular(12),
            ),
            // Placeholder icon as in the image
            child: Icon(Icons.person, color: Colors.pink[200], size: 40),
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
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                _buildServiceRow('Handyman', viewModel.handymanName),
                const SizedBox(height: 4),
                _buildServiceRow(
                  'Booking date',
                  bookingDateFormat.format(viewModel.serviceTimestamp),
                ),
                const SizedBox(height: 4),
                _buildServiceRow(
                  'Booking time',
                  bookingTimeFormat.format(viewModel.serviceTimestamp),
                ),
              ],
            ),
          ),
          Text(
            viewModel.serviceRate,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.black : Colors.grey[600],
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: isTotal ? Theme.of(context).primaryColor : Colors.black,
            fontSize: isTotal ? 20 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRow(String label, String time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(
          time,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildPayNowButton(BuildContext context, BillController controller) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => controller.navigateToPayment(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrange[400],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
}
