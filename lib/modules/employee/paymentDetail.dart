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
  static final dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

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
            'Payment Record Details',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildDetailItem('Payment ID', payment.payID),
          buildDetailItem('Billing ID', payment.billingID),
          buildDetailItem(
            'Admin Remark',
            (payment.adminRemark.trim().isNotEmpty)
                ? payment.adminRemark
                : 'None',
          ),
          payment.payMediaProof.isEmpty
              ? buildDetailItem('Media Proof', 'None')
              : buildMediaProof(payment.payMediaProof),
          buildDetailItem(
            'Service Price (RM)',
            currencyFormat.format(vm.serviceBasePrice),
          ),
          buildDetailItem(
            'Outstation Fee (RM)',
            currencyFormat.format(vm.outstationFee),
          ),
          buildDetailItem(
            'Total Price (RM)',
            currencyFormat.format(payment.payAmt),
          ),
          buildDetailItem(
            'Payment Created At',
            dateTimeFormat.format(payment.payCreatedAt),
          ),
          buildDetailItem('Payment Status', payment.payStatus),

          Padding(
            padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
            child: ElevatedButton.icon(
              label: const Text('Edit'),
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
                          final parentController =
                              Provider.of<PaymentController>(
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
          ),
        ],
      ),
    );
  }

  Widget buildMediaProof(String mediaProofUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Media Proof',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 8),
          if (mediaProofUrl.isEmpty)
            Container(
              height: 100,
              width: MediaQuery.of(context).size.width * 0.5,
              child: const Center(
                child: Text(
                  'No Proof Uploaded',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
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
                width: MediaQuery.of(context).size.width * 0.5,
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: mediaProofUrl.toNetworkImage(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildDetailItem(String label, String value) {
    final isStatusField = label.toLowerCase().contains('status');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            isStatusField ? capitalizeFirst(value) : value,
            style: TextStyle(
              color: isStatusField ? getStatusColor(value) : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
