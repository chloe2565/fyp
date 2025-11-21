import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../model/billDetailViewModel.dart';
import '../../model/databaseModel.dart';
import '../../shared/helper.dart';
import 'stripeCheckoutScreen.dart';
import 'billplzCheckoutScreen.dart';

class PaymentMethodScreen extends StatefulWidget {
  final BillingModel billingModel;
  final BillDetailViewModel billDetailViewModel;

  const PaymentMethodScreen({
    super.key,
    required this.billingModel,
    required this.billDetailViewModel,
  });

  @override
  State<PaymentMethodScreen> createState() => PaymentMethodScreenState();
}

class PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String selectedMethod = 'Credit Card';

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showErrorDialog(
          context,
          title: "Authentication Required",
          message: "Please sign in to continue with payment.",
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/custHome');
            }
          },
        ),
        title: const Text(
          'Payment Method',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select payment method",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 15),

            buildPaymentOption(
              title: "Credit Card",
              subtitle: "Pay with Visa, Mastercard, etc.",
              icon: Icons.credit_card,
              value: "Credit Card",
            ),
            const SizedBox(height: 12),

            buildPaymentOption(
              title: "Online Banking",
              subtitle: "FPX - Pay with Malaysian banks",
              icon: Icons.account_balance,
              value: "Online Banking",
            ),
            const SizedBox(height: 12),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  print("Selected method: $selectedMethod");
                  final currentUser = FirebaseAuth.instance.currentUser;
                  final firebaseAuthId = currentUser?.uid;
                  print(
                    "Current Firebase User ID on PayMethodScreen: $firebaseAuthId",
                  );

                  Widget nextPage;
                  switch (selectedMethod) {
                    case "Credit Card":
                      nextPage = StripeCheckoutScreen(
                        billingModel: widget.billingModel,
                        billDetailViewModel: widget.billDetailViewModel,
                        paymentMethodType: 'card',
                        paymentMethodName: 'Credit Card',
                        firebaseAuthId: firebaseAuthId!,
                      );
                      break;
                    case "Online Banking":
                      nextPage = BillplzCheckoutScreen(
                        billingModel: widget.billingModel,
                        billDetailViewModel: widget.billDetailViewModel,
                        paymentMethodName: 'Online Banking (FPX)',
                        firebaseAuthId: firebaseAuthId!,
                      );
                      break;
                    default:
                      return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => nextPage),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text("Next"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPaymentOption({
    required String title,
    required String value,
    String? subtitle,
    IconData? icon,
    Widget? iconWidget,
  }) {
    final bool isSelected = selectedMethod == value;
    final Color iconColor = const Color(0xFF004AAD);
    final Color selectedBgColor = const Color(0xFFEBF3FF);
    final Color selectedBorderColor = const Color(0xFF004AAD);
    final Color unselectedBorderColor = Colors.grey.shade300;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? selectedBgColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? selectedBorderColor : unselectedBorderColor,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            iconWidget ?? Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? selectedBorderColor : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}