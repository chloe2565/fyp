import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/billDetailViewModel.dart';
import '../../model/databaseModel.dart';
import '../../shared/helper.dart';

class BillplzCheckoutScreen extends StatefulWidget {
  final BillingModel billingModel;
  final BillDetailViewModel billDetailViewModel;
  final String paymentMethodName;
  final String firebaseAuthId;

  const BillplzCheckoutScreen({
    super.key,
    required this.billingModel,
    required this.billDetailViewModel,
    required this.paymentMethodName,
    required this.firebaseAuthId,
  });

  @override
  State<BillplzCheckoutScreen> createState() => BillplzCheckoutScreenState();
}

class BillplzCheckoutScreenState extends State<BillplzCheckoutScreen> {
  late final FirebaseFunctions functions;
  late WebViewController webViewController;
  bool isLoading = true;
  bool isPaymentProcessing = false;
  String? billplzUrl;
  String? billplzBillId;

  @override
  void initState() {
    super.initState();
    functions = FirebaseFunctions.instance;

    // Initialize WebView controller
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.contains('billplz-payment-success')) {
              print("DEBUG: Success URL intercepted. Preventing redirect.");

              handlePaymentSuccessUrl(request.url);

              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            print("Page started: $url");
          },
          onPageFinished: (String url) {
            print("Page finished: $url");
            if (!isPaymentProcessing && mounted) {
              setState(() {
                isLoading = false;
              });
            }
          },
        ),
      );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        initiatePayment();
      }
    });
  }

  Future<void> initiatePayment() async {
    showLoadingDialog(context, "Connecting to Billplz...");

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("User not authenticated");
      }
      await currentUser.getIdToken(true);

      final int amountInCents = (widget.billingModel.billAmt * 100).toInt();
      final callable = functions.httpsCallable('createBillplzBill');
      final response = await callable.call<Map<String, dynamic>>({
        'amount': amountInCents,
        'billingID': widget.billingModel.billingID,
        'customerEmail': currentUser.email ?? 'customer@example.com',
        'customerName': widget.billDetailViewModel.customerName,
        'description': 'Payment for ${widget.billDetailViewModel.serviceName}',
      });

      if (mounted) Navigator.pop(context);

      final data = response.data;
      if (!data.containsKey('url')) {
        throw Exception("Failed to create Billplz bill: Invalid response");
      }

      setState(() {
        billplzUrl = data['url'];
        billplzBillId = data['billId'];
      });

      print("DEBUG: Billplz URL: $billplzUrl");

      // Load the payment page
      webViewController.loadRequest(Uri.parse(billplzUrl!));
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        showErrorDialog(
          context,
          title: "Error",
          message: e.toString(),
          onPressed: () => Navigator.pop(context),
        );
      }
    }
  }

  void handlePaymentSuccessUrl(String url) {
    if (isPaymentProcessing) return;

    setState(() {
      isPaymentProcessing = true;
    });

    Uri uri = Uri.parse(url);
    final billId = uri.queryParameters['billplz[id]'];
    final paid = uri.queryParameters['billplz[paid]'];
    final transactionId = uri.queryParameters['billplz[transaction_id]'];

    if (paid == 'false') {
      manualFailureProcessing(billId!, transactionId);
      if (mounted) {
        showErrorDialog(
          context,
          title: "Payment Failed",
          message: "The payment was not successful. Please try again.",
          onPressed: () {
            Navigator.pop(context);
          },
        );
      }
      return;
    }

    showLoadingDialog(context, "Verifying Payment...");

    final transactionStatus =
        uri.queryParameters['billplz[transaction_status]'];

    if (paid == 'true' && transactionStatus == 'completed') {
      manualCallbackProcessing(billId!, transactionId!);
    } else {
      verifyPaymentStatus();
    }
  }

  Future<void> manualCallbackProcessing(
    String billId,
    String transactionId,
  ) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'processBillplzPayment',
      );
      await callable.call({
        'billId': billId,
        'transactionId': transactionId,
        'billingID': widget.billingModel.billingID,
      });
    } catch (e) {
      print("Manual processing error: $e");
    } finally {
      if (mounted) verifyPaymentStatus();
    }
  }

  Future<void> manualFailureProcessing(
    String billId,
    String? transactionId,
  ) async {
    showLoadingDialog(context, "Processing Payment Failure...");

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'logBillplzPaymentFailure',
      );
      await callable.call({
        'billId': billId,
        'transactionId': transactionId,
        'billingID': widget.billingModel.billingID,
      });

      if (mounted) Navigator.of(context).pop(); // Close loading dialog

      if (mounted) {
        showErrorDialog(
          context,
          title: "Payment Failed",
          message: "The payment was not successful. Please try again.",
          onPressed: () {
            Navigator.of(context).pop(); // Close the error dialog
            Navigator.of(context).pop(); // Close the BillplzCheckoutScreen
          },
        );
      }
    } catch (e) {
      print("Manual failure processing error: $e");
      if (mounted) Navigator.of(context).pop(); // Close loading dialog
      if (mounted) {
        showErrorDialog(
          context,
          title: "Processing Error",
          message: "Failed to log payment failure: $e",
          onPressed: () => Navigator.of(context).pop(),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isPaymentProcessing = false;
        });
      }
    }
  }

  Future<void> verifyPaymentStatus() async {
    try {
      int attempts = 0;
      const maxAttempts = 5;

      while (attempts < maxAttempts) {
        final billDoc = await FirebaseFirestore.instance
            .collection('Billing')
            .doc(widget.billingModel.billingID)
            .get();

        if (billDoc.exists && billDoc.data()?['billStatus'] == 'paid') {
          if (mounted) Navigator.of(context).pop();

          if (mounted) {
            showSuccessDialog(
              context,
              title: "Payment Successful!",
              message:
                  "You have successfully paid RM ${widget.billingModel.billAmt.toStringAsFixed(2)} using ${widget.paymentMethodName}.",
              primaryButtonText: "Back to Home",
              onPrimary: () {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/custHome', (route) => false);
              },
            );
          }
          return;
        }
        attempts++;
        await Future.delayed(const Duration(seconds: 2));
      }

      if (mounted) Navigator.of(context).pop(); // Close loading dialog

      if (mounted) {
        showErrorDialog(
          context,
          title: "Verification Timeout",
          message:
              "We couldn't verify the payment status automatically. Please check your history.",
          onPressed: () {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/custHome', (route) => false);
          },
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // Close loading dialog
      print("Verification error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pay with ${widget.paymentMethodName}"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showConfirmDialog(
              context,
              title: 'Cancel Payment?',
              message: 'Are you sure you want to cancel this payment?',
              affirmativeText: 'Yes, Cancel',
              negativeText: 'No, Continue',
              onAffirmative: () {
                Navigator.pop(context); // Close payment screen
              },
            );
          },
        ),
      ),
      body: Stack(
        children: [
          if (billplzUrl != null) WebViewWidget(controller: webViewController),

          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
