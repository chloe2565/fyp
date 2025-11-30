import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import '../../model/billDetailViewModel.dart';
import '../../model/databaseModel.dart';
import '../../shared/helper.dart';

class StripeCheckoutScreen extends StatefulWidget {
  final BillingModel billingModel;
  final BillDetailViewModel billDetailViewModel;
  final String paymentMethodType;
  final String paymentMethodName;
  final String firebaseAuthId;

  const StripeCheckoutScreen({
    super.key,
    required this.billingModel,
    required this.billDetailViewModel,
    required this.paymentMethodType,
    required this.paymentMethodName,
    required this.firebaseAuthId,
  });

  @override
  State<StripeCheckoutScreen> createState() => StripeCheckoutScreenState();
}

class StripeCheckoutScreenState extends State<StripeCheckoutScreen> {
  late final FirebaseFunctions functions;

  @override
  void initState() {
    super.initState();
    functions = FirebaseFunctions.instance;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        initiatePayment();
      }
    });
  }

  Future<void> initiatePayment() async {
    showLoadingDialog(context, "Connecting to payment gateway...");

    try {
      // Verify user is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("User not authenticated");
      }

      await currentUser.getIdToken(true);

      final int amountInCents = (widget.billingModel.billAmt * 100).toInt();
      final callable = functions.httpsCallable('createPaymentIntent');
      final response = await callable.call<Map<String, dynamic>>({
        'amount': amountInCents,
        'currency': 'myr',
        'paymentMethodType': widget.paymentMethodType,
        'billingID': widget.billingModel.billingID,
      });

      if (mounted) Navigator.pop(context);

      final data = response.data;
      if (!data.containsKey('clientSecret')) {
        throw Exception("Failed to create payment: Invalid response");
      }

      final String clientSecret = data['clientSecret'];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'HandyApp',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      if (mounted) {
        showSuccessDialog(
          context,
          title: "Payment Successful!",
          message:
              "You have successfully paid RM ${widget.billingModel.billAmt.toStringAsFixed(2)} using ${widget.paymentMethodName}.",
          primaryButtonText: "Back to Home",
          onPrimary: () {
            Navigator.of(context).pop();
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/custHome',
              (route) => false,
            );
          },
        );
      }
    } on FirebaseFunctionsException catch (e) {
      final isDialogShowing = ModalRoute.of(context)?.isCurrent != true;
      if (mounted && isDialogShowing) Navigator.pop(context);

      if (mounted) {
        showErrorDialog(
          context,
          title: "Payment Failed",
          message: e.message ?? "An error occurred with the payment service.",
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        );
      }
    } on StripeException catch (e) {
      final isDialogShowing = ModalRoute.of(context)?.isCurrent != true;
      if (mounted && isDialogShowing) Navigator.pop(context);

      if (e.error.code == FailureCode.Canceled) {
        if (mounted) Navigator.pop(context);
        return;
      }

      if (mounted) {
        showErrorDialog(
          context,
          title: "Payment Failed",
          message:
              e.error.localizedMessage ?? "An unknown Stripe error occurred.",
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        );
      }
    } catch (e) {
      final isDialogShowing = ModalRoute.of(context)?.isCurrent != true;
      if (mounted && isDialogShowing) Navigator.pop(context);

      if (mounted) {
        showErrorDialog(
          context,
          title: "Error",
          message: "An error occurred: ${e.toString()}",
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pay with ${widget.paymentMethodName}")),
      body: const Center(),
    );
  }
}
