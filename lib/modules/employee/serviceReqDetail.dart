import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controller/serviceRequest.dart';
import '../../controller/user.dart';
import '../../model/billDetailViewModel.dart';
import '../../model/databaseModel.dart';
import '../../model/serviceRequestViewModel.dart';
import '../../shared/fullScreenImage.dart';
import '../../shared/helper.dart';
import '../../service/image_service.dart';
import '../../service/nlp_service.dart';
import '../../service/bill.dart';
import 'handymanServiceReqMap.dart';
import 'providerServiceReqMap.dart';
import 'addNewBill.dart';
import 'addNewPayment.dart';
import 'editBill.dart';
import 'editPayment.dart';

class EmpRequestDetailScreen extends StatefulWidget {
  final String reqID;
  final ServiceRequestController controller;

  const EmpRequestDetailScreen({
    super.key,
    required this.reqID,
    required this.controller,
  });

  @override
  State<EmpRequestDetailScreen> createState() => EmpRequestDetailScreenState();
}

class EmpRequestDetailScreenState extends State<EmpRequestDetailScreen> {
  static final currencyFormat = NumberFormat("#,##0.00", "en_MY");
  static final dateTimeFormat = DateFormat('MMMM dd, yyyy hh:mm a');
  static final dateFormat = DateFormat('MMMM dd, yyyy');

  ComprehensiveAnalysis? nlpAnalysis;
  bool isLoadingAnalysis = false;
  String? customerName;
  bool isLoadingCustomerName = false;
  UserController? userController;
  final BillService billService = BillService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Billing & Payment data
  BillingModel? billingData;
  BillDetailViewModel? billDetailViewModel;
  PaymentModel? paymentData;
  bool isLoadingBilling = false;
  bool isLoadingPayment = false;

  @override
  void initState() {
    super.initState();
    userController = UserController(
      showErrorSnackBar: (error) => print('Error: $error'),
    );
    loadNLPAnalysis();
    loadCustomerName();
    loadBillingAndPayment();
  }

  Future<void> loadBillingAndPayment() async {
    setState(() {
      isLoadingBilling = true;
      isLoadingPayment = true;
    });

    try {
      // Load billing
      final billingQuery = await _db
          .collection('Billing')
          .where('reqID', isEqualTo: widget.reqID)
          .limit(1)
          .get();

      if (billingQuery.docs.isNotEmpty) {
        final billingModel = BillingModel.fromMap(
          billingQuery.docs.first.data(),
        );
        billingData = billingModel;

        try {
          billDetailViewModel = await billService.getBillDetails(billingModel);
        } catch (e) {
          print('Error loading BillDetailViewModel: $e');
          billDetailViewModel = null;
        }

        // Load payment if billing exists
        final paymentQuery = await _db
            .collection('Payment')
            .where('billingID', isEqualTo: billingData!.billingID)
            .limit(1)
            .get();

        if (paymentQuery.docs.isNotEmpty) {
          paymentData = PaymentModel.fromMap(paymentQuery.docs.first.data());
        }
      }
    } catch (e) {
      print('Error loading billing/payment: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingBilling = false;
          isLoadingPayment = false;
        });
      }
    }
  }

  Future<void> loadNLPAnalysis() async {
    if (!mounted) return;
    setState(() => isLoadingAnalysis = true);

    final viewModel = widget.controller.getRequestById(widget.reqID);
    if (viewModel != null && viewModel.requestModel.reqDesc.isNotEmpty) {
      final analysis = await NLPService.analyzeDescription(
        viewModel.requestModel.reqDesc,
      );
      if (!mounted) return;
      setState(() {
        nlpAnalysis = analysis;
        isLoadingAnalysis = false;
      });
    } else {
      if (!mounted) return;
      setState(() => isLoadingAnalysis = false);
    }
  }

  Future<void> loadCustomerName() async {
    if (!mounted) return;
    setState(() => isLoadingCustomerName = true);

    try {
      final viewModel = widget.controller.getRequestById(widget.reqID);
      if (viewModel != null && userController != null) {
        final name = await userController!.getCustomerNameByCustID(
          viewModel.requestModel.custID,
        );

        if (!mounted) return;
        setState(() {
          customerName = name;
          isLoadingCustomerName = false;
        });
      } else {
        if (!mounted) return;
        setState(() => isLoadingCustomerName = false);
      }
    } catch (e) {
      print('Error in loadCustomerName: $e');
      if (!mounted) return;
      setState(() {
        customerName = null;
        isLoadingCustomerName = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final RequestViewModel? viewModel = widget.controller.getRequestById(
          widget.reqID,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Request Details'),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            titleTextStyle: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            centerTitle: true,
          ),
          backgroundColor: Colors.grey[50],
          body: viewModel == null
              ? const Center(
                  child: Text(
                    'Service request not found.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : buildDetailsBody(context, viewModel),
        );
      },
    );
  }

  Widget buildDetailsBody(BuildContext context, RequestViewModel viewModel) {
    final model = viewModel.requestModel;
    final icon = ServiceHelper.getIconForService(viewModel.title);
    final bgColor = ServiceHelper.getColorForService(viewModel.title);
    final isAdmin = widget.controller.currentEmployeeType == 'admin';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Header Card
          buildServiceHeaderCard(context, viewModel, icon, bgColor),
          const SizedBox(height: 12),

          // Status Card
          buildStatusCard(context, viewModel),
          const SizedBox(height: 12),

          // Customer & Booking Details Card
          buildBookingDetailsCard(context, viewModel),
          const SizedBox(height: 12),

          // Location Card
          buildLocationCard(context, model.reqAddress),
          const SizedBox(height: 12),

          // Photos Card
          if (model.reqPicName.isNotEmpty)
            buildPhotosCard(context, model.reqPicName),
          if (model.reqPicName.isNotEmpty) const SizedBox(height: 12),

          // Description Card
          buildDescriptionCard(context, model.reqDesc, model.reqRemark),
          const SizedBox(height: 12),

          if (isLoadingAnalysis)
            Container(
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
              child: const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Analyzing request...'),
                ],
              ),
            ),
          if (isLoadingAnalysis) const SizedBox(height: 12),

          // NLP Insights Card
          if (nlpAnalysis != null) buildNLPInsightsCard(),
          if (nlpAnalysis != null) const SizedBox(height: 12),

          // Billing Section (only show if completed or if admin)
          if (viewModel.reqStatus.toLowerCase() == 'completed' || isAdmin)
            buildBillingSection(context, viewModel, isAdmin),
          if (viewModel.reqStatus.toLowerCase() == 'completed' || isAdmin)
            const SizedBox(height: 12),

          // Payment Section (only show if billing exists or if admin)
          if ((billingData != null || isAdmin) &&
              (viewModel.reqStatus.toLowerCase() == 'completed' || isAdmin))
            buildPaymentSection(context, viewModel, isAdmin),
          if ((billingData != null || isAdmin) &&
              (viewModel.reqStatus.toLowerCase() == 'completed' || isAdmin))
            const SizedBox(height: 12),

          // Cancellation Info (if cancelled)
          if (viewModel.reqStatus.toLowerCase() == 'cancelled' &&
              model.reqCustomCancel != null &&
              model.reqCustomCancel!.isNotEmpty)
            buildCancellationCard(context, model),
          if (viewModel.reqStatus.toLowerCase() == 'cancelled' &&
              model.reqCustomCancel != null &&
              model.reqCustomCancel!.isNotEmpty)
            const SizedBox(height: 12),

          // Action Buttons
          ...buildBottomActions(context, viewModel, widget.controller),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget buildBillingSection(
    BuildContext context,
    RequestViewModel viewModel,
    bool isAdmin,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long, color: Colors.blue[700], size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Billing Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (isAdmin && billingData != null)
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmpEditBillScreen(
                          bill: billingData!,
                          onBillUpdated: loadBillingAndPayment,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (isLoadingBilling)
            const Center(child: CircularProgressIndicator())
          else if (billingData == null) ...[
            Text(
              'No billing record found for this service request.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            if (isAdmin &&
                viewModel.reqStatus.toLowerCase() == 'completed') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Bill'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmpAddBillScreen(
                          onBillAdded: loadBillingAndPayment,
                          serviceRequestID: viewModel.reqID,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else if (isAdmin &&
                viewModel.reqStatus.toLowerCase() != 'completed') ...[
              const SizedBox(height: 12),
              Text(
                'A bill can only be created after the service request is marked as "Completed".',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ] else ...[
            if (billDetailViewModel != null) ...[
              buildInfoRow(
                Icons.info_outline,
                'Bill Status',
                capitalizeFirst(billDetailViewModel!.billStatus),
                valueColor: getStatusColor(billDetailViewModel!.billStatus),
              ),
              const SizedBox(height: 12),
              buildInfoRow(
                Icons.calendar_today,
                'Due Date',
                dateFormat.format(billingData!.billDueDate),
              ),
              if (billDetailViewModel!.adminRemark != null &&
                  billDetailViewModel!.adminRemark!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                buildAdminRemarksCard(
                  context,
                  billDetailViewModel!.adminRemark!,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Service Price',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  Text(
                    'RM ${currencyFormat.format(billDetailViewModel!.serviceBasePrice ?? 0.0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Outstation Fee',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  Text(
                    'RM ${currencyFormat.format(billDetailViewModel!.outstationFee)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'RM ${currencyFormat.format(billDetailViewModel!.totalPrice)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ] else if (billingData != null) ...[
              buildInfoRow(
                Icons.info_outline,
                'Bill Status',
                capitalizeFirst(billingData!.billStatus),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'RM ${currencyFormat.format(billingData!.billAmt)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              buildInfoRow(
                Icons.calendar_today,
                'Due Date',
                dateFormat.format(billingData!.billDueDate),
              ),
              const SizedBox(height: 12),
              buildInfoRow(
                Icons.access_time,
                'Created At',
                dateTimeFormat.format(billingData!.billCreatedAt),
              ),
            ] else ...[
              const Text('Error displaying bill details.'),
            ],
          ],
        ],
      ),
    );
  }

  Widget buildPaymentSection(
    BuildContext context,
    RequestViewModel viewModel,
    bool isAdmin,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.payment, color: Colors.green[700], size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Payment Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (isAdmin && paymentData != null)
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmpEditPaymentScreen(
                          payment: paymentData!,
                          onPaymentUpdated: loadBillingAndPayment,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (isLoadingPayment)
            const Center(child: CircularProgressIndicator())
          else if (paymentData == null) ...[
            Text(
              billingData == null
                  ? 'Create a billing record first to add payment.'
                  : 'No payment record found for this bill.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            if (isAdmin && billingData != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmpAddPaymentScreen(
                          onPaymentAdded: loadBillingAndPayment,
                          billingID: billingData!.billingID,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ] else ...[
            buildInfoRow(
              Icons.info_outline,
              'Payment Status',
              capitalizeFirst(paymentData!.payStatus),
              valueColor: getStatusColor(paymentData!.payStatus),
            ),
            const SizedBox(height: 12),
            buildInfoRow(
              Icons.payment,
              'Payment Method',
              paymentData!.payMethod,
            ),
            const SizedBox(height: 12),
            buildInfoRow(
              Icons.access_time,
              'Payment Date',
              dateTimeFormat.format(paymentData!.payCreatedAt),
            ),
            if (paymentData!.payMediaProof.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Payment Media Proof:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenGalleryViewer(
                        imagePaths: [paymentData!.payMediaProof],
                        initialIndex: 0,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: paymentData!.payMediaProof.toNetworkImage(
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Amount Paid:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'RM ${currencyFormat.format(paymentData!.payAmt)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ],
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
                'Admin Remark',
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

  Widget buildNLPInsightsCard() {
    if (nlpAnalysis == null) return const SizedBox.shrink();

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
              Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 24),
              const SizedBox(width: 8),
              const Text(
                'AI Insights',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Urgency: ',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: getUrgencyColor(nlpAnalysis!.urgency),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  nlpAnalysis!.urgency.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (nlpAnalysis!.insights['complexity'] != null) ...[
            Row(
              children: [
                const Text(
                  'Difficulty: ',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  capitalizeFirst(nlpAnalysis!.insights['complexity']),
                  style: TextStyle(
                    color: getComplexityColor(
                      nlpAnalysis!.insights['complexity'],
                    ),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (nlpAnalysis!.recommendations.isNotEmpty) ...[
            const Text(
              'Recommended Tools & Parts:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...nlpAnalysis!.recommendations.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(
                        r,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildServiceHeaderCard(
    BuildContext context,
    RequestViewModel viewModel,
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
                  viewModel.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatusCard(BuildContext context, RequestViewModel viewModel) {
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
            color: getStatusColor(viewModel.reqStatus),
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Service Request Status: ',
            style: TextStyle(fontSize: 15, color: Colors.grey[700]),
          ),
          Text(
            capitalizeFirst(viewModel.reqStatus),
            style: TextStyle(
              color: getStatusColor(viewModel.reqStatus),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBookingDetailsCard(
    BuildContext context,
    RequestViewModel viewModel,
  ) {
    final model = viewModel.requestModel;
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
            'Service Request Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          buildInfoRow(
            Icons.person,
            'Customer Name',
            isLoadingCustomerName
                ? 'Loading...'
                : (customerName != null && customerName!.isNotEmpty
                      ? customerName!
                      : 'Unknown Customer'),
          ),
          const SizedBox(height: 12),
          buildInfoRow(
            Icons.person,
            'Customer Contact',
            Formatter.formatPhoneNumber(viewModel.customerContact),
          ),
          const SizedBox(height: 12),
          buildInfoRow(
            Icons.schedule,
            'Service Request Created At',
            Formatter.formatDateTime(model.reqDateTime),
          ),
          const SizedBox(height: 12),
          buildInfoRow(
            Icons.calendar_today,
            'Service Request Scheduled At',
            Formatter.formatDateTime(viewModel.scheduledDateTime),
          ),
          const SizedBox(height: 12),
          if (viewModel.reqStatus.toLowerCase() == "completed")
            buildInfoRow(
              Icons.calendar_today,
              'Service Request Completed At',
              Formatter.formatDateTime(model.reqCompleteTime),
            ),
          const SizedBox(height: 12),
          buildInfoRow(
            Icons.person_outline,
            'Handyman Assigned',
            viewModel.handymanName.isNotEmpty
                ? viewModel.handymanName
                : 'Not Assigned',
          ),
        ],
      ),
    );
  }

  Widget buildLocationCard(BuildContext context, String address) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on, color: Colors.red[400], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service Request Location',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPhotosCard(BuildContext context, List<String> imageUrls) {
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
            'Service Request Photos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imageUrls.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final imageUrl = imageUrls[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenGalleryViewer(
                          imagePaths: imageUrls,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: imageUrl.toNetworkImage(
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
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

  Widget buildDescriptionCard(
    BuildContext context,
    String description,
    String? remark,
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
            'Service Request Description',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          if (remark != null && remark.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Additional Remarks',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              remark,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildCancellationCard(
    BuildContext context,
    ServiceRequestModel model,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red[700], size: 24),
              const SizedBox(width: 8),
              Text(
                'Cancellation Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Reason:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.red[900],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            model.reqCustomCancel!,
            style: TextStyle(fontSize: 14, color: Colors.red[800], height: 1.4),
          ),
          if (model.reqCancelDateTime != null) ...[
            const SizedBox(height: 12),
            Text(
              'Cancelled At:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.red[900],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat(
                'MMMM dd, yyyy hh:mm a',
              ).format(model.reqCancelDateTime!),
              style: TextStyle(fontSize: 14, color: Colors.red[800]),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> buildBottomActions(
    BuildContext context,
    RequestViewModel viewModel,
    ServiceRequestController controller,
  ) {
    final status = viewModel.reqStatus.toLowerCase();
    final now = DateTime.now();
    final scheduledDate = DateUtils.dateOnly(viewModel.scheduledDateTime);
    final today = DateUtils.dateOnly(now);
    final differenceInDays = scheduledDate.difference(today).inDays;
    final isHandyman = controller.currentEmployeeType == 'handyman';

    List<Widget> actions = [];

    // Depart button for handyman when status is confirmed
    if (isHandyman && status == 'confirmed') {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              showConfirmDialog(
                context,
                title: 'Confirm Departure',
                message:
                    'Are you sure you want to mark this service request as departed?',
                affirmativeText: 'Depart',
                negativeText: 'Cancel',
                onAffirmative: () async {
                  showLoadingDialog(context, 'Updating status...');
                  try {
                    await controller.updateRequestStatus(
                      viewModel.reqID,
                      'departed',
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      showSuccessDialog(
                        context,
                        title: 'Success!',
                        message: 'Status updated to Departed',
                        primaryButtonText: 'OK',
                        onPrimary: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      showErrorDialog(
                        context,
                        title: 'Error',
                        message: 'Failed to update status: $e',
                      );
                    }
                  }
                },
              );
            },
            label: const Text('Depart'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      );
      actions.add(const SizedBox(height: 12));
    }

    // View map
    if (status == 'departed') {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final String? empType = controller.currentEmployeeType;

              if (empType == 'handyman') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        HandymanServiceReqMapScreen(reqID: viewModel.reqID),
                  ),
                );
              } else if (empType == 'admin') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProviderServiceReqMapScreen(reqID: viewModel.reqID),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: Could not determine user role.'),
                  ),
                );
              }
            },
            label: const Text('Track Handyman'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      );
      actions.add(const SizedBox(height: 12));

      // Complete button for handyman when status is departed
      if (isHandyman) {
        actions.add(
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                showConfirmDialog(
                  context,
                  title: 'Complete Service',
                  message:
                      'Are you sure you want to mark this service request as completed?',
                  affirmativeText: 'Complete',
                  negativeText: 'Cancel',
                  onAffirmative: () async {
                    showLoadingDialog(context, 'Completing service...');
                    try {
                      await controller.updateRequestStatus(
                        viewModel.reqID,
                        'completed',
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        showSuccessDialog(
                          context,
                          title: 'Success!',
                          message: 'Service completed successfully!',
                          primaryButtonText: 'OK',
                          onPrimary: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        showErrorDialog(
                          context,
                          title: 'Error',
                          message: 'Failed to complete service: $e',
                        );
                      }
                    }
                  },
                );
              },
              label: const Text('Complete Service Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        );
        actions.add(const SizedBox(height: 12));
      }
    }

    // Reschedule and cancel button
    if ((status == 'pending' || status == 'confirmed') &&
        differenceInDays >= 1) {
      actions.add(
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => controller.rescheduleRequest(viewModel.reqID),
                label: const Text('Reschedule'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  showCancelRequestDialog(
                    context,
                    reqID: viewModel.reqID,
                    onConfirmCancel: controller.cancelRequest,
                    onSuccess: () {
                      Navigator.of(context).pop();
                    },
                  );
                },
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return actions;
  }
}
