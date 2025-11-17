import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controller/payment.dart';
import '../../model/paymentDetailViewModel.dart';
import '../../model/databaseModel.dart';
import '../../shared/fullScreenImage.dart';
import '../../shared/helper.dart';
import '../../service/image_service.dart';
import 'editPayment.dart';

class EmpPaymentDetailScreen extends StatefulWidget {
  final PaymentModel payment;

  const EmpPaymentDetailScreen({super.key, required this.payment});

  @override
  State<EmpPaymentDetailScreen> createState() => EmpPaymentDetailScreenState();
}

class EmpPaymentDetailScreenState extends State<EmpPaymentDetailScreen> {
  static final currencyFormat = NumberFormat("#,##0.00", "en_MY");
  static final dateTimeFormat = DateFormat('MMMM dd, yyyy hh:mm a');

  late PaymentController controller;

  @override
  void initState() {
    super.initState();
    controller = PaymentController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadDetails();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void loadDetails() {
    controller.loadPaymentDetails(widget.payment);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: const BackButton(color: Colors.black),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: const Text(
            'Payment Details',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        backgroundColor: Colors.grey[50],
        body: Consumer<PaymentController>(
          builder: (context, controller, child) {
            if (controller.detailLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.detailError != null) {
              return Center(child: Text(controller.detailError!));
            }

            if (controller.detailModel == null) {
              return const Center(child: Text('No details found.'));
            }

            final displayPayment = controller.existingPayment ?? widget.payment;

            return buildDetailsBody(
              context,
              controller.detailModel!,
              displayPayment,
            );
          },
        ),
      ),
    );
  }

  Widget buildDetailsBody(
    BuildContext context,
    PaymentDetailViewModel vm,
    PaymentModel payment,
  ) {
    final icon = ServiceHelper.getIconForService(vm.serviceName ?? 'Unknown');
    final bgColor = ServiceHelper.getColorForService(vm.serviceName ?? 'Unknown');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Header Card
          buildServiceHeaderCard(context, vm, payment, icon, bgColor),
          const SizedBox(height: 12),

          // Status Card
          buildStatusCard(context, payment),
          const SizedBox(height: 12),

          // Customer Information Card
          buildCustomerInfoCard(context, vm),
          const SizedBox(height: 12),

          // Payment Method Card
          buildPaymentMethodCard(context, payment),
          const SizedBox(height: 12),

          // Pricing Breakdown Card
          buildPricingCard(context, vm, payment),
          const SizedBox(height: 12),

          // Timeline Card
          buildTimelineCard(context, vm, payment),
          const SizedBox(height: 12),

          // Media Proof Card
          if (payment.payMediaProof.isNotEmpty)
            buildMediaProofCard(context, payment.payMediaProof),
          if (payment.payMediaProof.isNotEmpty) const SizedBox(height: 12),

          // Admin Remarks Card
          if (payment.adminRemark.trim().isNotEmpty)
            buildAdminRemarksCard(context, payment.adminRemark),
          if (payment.adminRemark.trim().isNotEmpty) const SizedBox(height: 12),

          // Action Button
          buildActionButton(context, payment),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget buildServiceHeaderCard(
    BuildContext context,
    PaymentDetailViewModel vm,
    PaymentModel payment,
    IconData icon,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.black, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vm.serviceName ?? 'Unknown Service',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Payment ID: ${payment.payID}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Billing ID: ${payment.billingID}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatusCard(BuildContext context, PaymentModel payment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: getStatusColor(payment.payStatus),
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Payment Status: ',
            style: TextStyle(fontSize: 15, color: Colors.grey[700]),
          ),
          Text(
            capitalizeFirst(payment.payStatus),
            style: TextStyle(
              color: getStatusColor(payment.payStatus),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCustomerInfoCard(BuildContext context, PaymentDetailViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          buildInfoRow(Icons.person, 'Name', vm.customerName ?? 'Unknown'),
          const SizedBox(height: 12),
          buildInfoRow(Icons.phone, 'Contact', vm.customerContact ?? 'N/A'),
          const SizedBox(height: 12),
          buildInfoRow(Icons.location_on, 'Address', vm.customerAddress ?? 'N/A'),
        ],
      ),
    );
  }

  Widget buildPaymentMethodCard(BuildContext context, PaymentModel payment) {
    IconData methodIcon;
    Color methodColor;

    switch (payment.payMethod.toLowerCase()) {
      case 'cash':
        methodIcon = Icons.payments;
        methodColor = Colors.green;
        break;
      case 'card':
      case 'credit card':
      case 'debit card':
        methodIcon = Icons.credit_card;
        methodColor = Colors.blue;
        break;
      case 'online banking':
      case 'bank transfer':
        methodIcon = Icons.account_balance;
        methodColor = Colors.purple;
        break;
      case 'e-wallet':
      case 'ewallet':
        methodIcon = Icons.account_balance_wallet;
        methodColor = Colors.orange;
        break;
      default:
        methodIcon = Icons.payment;
        methodColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: methodColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(methodIcon, color: methodColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.payMethod,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Transaction completed',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
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

  Widget buildPricingCard(
    BuildContext context,
    PaymentDetailViewModel vm,
    PaymentModel payment,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPriceRow('Service Price', vm.serviceBasePrice),
          const SizedBox(height: 8),
          _buildPriceRow('Outstation Fee', vm.outstationFee),
          const Divider(height: 24),
          _buildPriceRow('Total Paid', payment.payAmt, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          'RM ${currencyFormat.format(amount)}',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? Colors.green[700] : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget buildTimelineCard(
    BuildContext context,
    PaymentDetailViewModel vm,
    PaymentModel payment,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Timeline',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          buildInfoRow(
            Icons.schedule,
            'Service Scheduled',
            dateTimeFormat.format(vm.bookingTimestamp),
          ),
          const SizedBox(height: 12),
          buildInfoRow(
            Icons.check_circle,
            'Service Completed',
            dateTimeFormat.format(vm.serviceCompleteTimestamp),
          ),
          const SizedBox(height: 12),
          buildInfoRow(
            Icons.paid,
            'Payment Created',
            dateTimeFormat.format(payment.payCreatedAt),
          ),
        ],
      ),
    );
  }

  Widget buildMediaProofCard(BuildContext context, String mediaProofUrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_camera, color: Colors.blue[600], size: 24),
              const SizedBox(width: 8),
              const Text(
                'Payment Proof',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenGalleryViewer(
                    imagePaths: [mediaProofUrl],
                    initialIndex: 0,
                  ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    mediaProofUrl.toNetworkImage(
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fullscreen,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Tap to view',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAdminRemarksCard(BuildContext context, String remark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note_alt, color: Colors.amber[700], size: 24),
              const SizedBox(width: 8),
              Text(
                'Admin Remarks',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            remark,
            style: TextStyle(
              fontSize: 14,
              color: Colors.amber[900],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildActionButton(BuildContext context, PaymentModel payment) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.edit, size: 18),
        label: const Text('Edit Payment'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (routeContext) => EmpEditPaymentScreen(
                payment: widget.payment,
                onPaymentUpdated: () {
                  loadDetails();
                  try {
                    final parentController = Provider.of<PaymentController>(
                      context,
                      listen: false,
                    );
                    parentController.initializeForEmployee();
                  } catch (e) {
                    print('Parent controller not available: $e');
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}