import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        initiatePayment();
      }
    });
  }

  Future<void> initiatePayment() async {
    bool isLoadingDialogShowing = false;
    showLoadingDialog(context, "Connecting to payment gateway...");

    try {
      final String userId = widget.firebaseAuthId;
      final int amountInCents = (widget.billingModel.billAmt * 100).toInt();

      if (userId == null) throw Exception("User not logged in");

      final response = await supabase.functions.invoke(
        'create-payment-intent',
        body: {
          'amount': amountInCents,
          'currency': 'myr',
          'userId': userId,
          'paymentMethodType': widget.paymentMethodType,
          'billingID': widget.billingModel.billingID,
        },
      );

      // Pop loading dialog before show any error
      if (mounted) Navigator.pop(context);

      if (response.status != 200) {
        final errorMessage =
            response.data['error'] as String? ?? "Unknown function error";
        throw Exception("Failed to create payment: $errorMessage");
      }

      final String clientSecret = response.data['clientSecret'];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'HandyApp',
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      print("DEBUG: Stripe payment sheet presented and completed/closed.");

      print("DEBUG: Attempting to show success dialog...");
      if (mounted) {
        showSuccessDialog(
          context,
          title: "Payment Successful!",
          message:
              "You have successfully paid RM ${widget.billingModel.billAmt.toStringAsFixed(2)} using ${widget.paymentMethodName}.",
          primaryButtonText: "Back to Home",
          onPrimary: () {
            Navigator.of(context).pop();
            print("DEBUG: Success dialog 'Back to Home' clicked.");
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
            print("DEBUG: Success dialog shown.");
          },
        );
      } else {
        print("DEBUG: Context not mounted when trying to show success dialog.");
      }
    } on StripeException catch (e) {
      print(
        "DEBUG: Caught StripeException: ${e.error.code} - ${e.error.message}",
      );
      final isDialogShowing = ModalRoute.of(context)?.isCurrent != true;
      if (mounted && isDialogShowing) Navigator.pop(context);

      if (e.error.code == FailureCode.Canceled) {
        print("DEBUG: Payment cancelled by user.");
        if (mounted) Navigator.pop(context);
        return;
      }

      if (mounted) {
        print("DEBUG: Showing payment failed dialog (StripeException).");
        showErrorDialog(
          context,
          title: "Payment Failed",
          message:
              e.error.localizedMessage ?? "An unknown Stripe error occurred.",
          onPressed: () {
            print("DEBUG: Payment failed dialog OK clicked.");
            Navigator.of(context).pop(); // Close error dialog
            Navigator.of(context).pop(); // Go back from checkout screen
          },
        );
      }
    } catch (e) {
      print("DEBUG: Caught generic Exception: $e");
      final isDialogShowing = ModalRoute.of(context)?.isCurrent != true;
      if (mounted && isDialogShowing) Navigator.pop(context);

      if (mounted) {
        print("DEBUG: Showing generic error dialog.");
        showErrorDialog(
          context,
          title: "Error",
          message: "An error occurred: ${e.toString()}",
          onPressed: () {
            print("DEBUG: Generic error dialog OK clicked.");
            Navigator.of(context).pop(); // Close error dialog
            Navigator.of(context).pop(); // Go back from checkout screen
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
