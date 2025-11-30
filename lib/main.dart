import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fyp/modules/customer/billPaymentHistory.dart';
import 'package:fyp/modules/employee/allService.dart';
import 'package:fyp/modules/employee/homepage.dart';
import 'package:fyp/modules/employee/serviceReq.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'modules/customer/profile.dart';
import 'modules/customer/rateReviewHistory.dart';
import 'modules/customer/reqHistory.dart';
import 'modules/customer/register.dart';
import 'modules/customer/homepage.dart';
import 'modules/employee/allEmployee.dart';
import 'modules/employee/allReport.dart';
import 'modules/employee/billPayment.dart';
import 'modules/employee/empProfile.dart';
import 'modules/employee/ratingReview.dart';
import 'service/firebase_options.dart';
import 'service/notification_service.dart';
import 'shared/theme.dart';
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const stripePublishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Stripe.publishableKey = stripePublishableKey;
  await Stripe.instance.applySettings();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Handyman Service Optimization System',
      theme: customAppTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/custHome': (context) => const CustHomepage(),
        '/profile': (context) => const ProfileScreen(),
        '/request': (context) => const RequestHistoryScreen(),
        // '/favorite': (context) => const FavoriteScreen(),
        '/rating': (context) => const RateReviewHistoryScreen(),
        '/billPayment': (context) => const BillPaymentHistoryScreen(),
        '/empHome': (context) => const EmpHomepage(),
        '/empAllService': (context) => const EmpAllServicesScreen(),
        '/empRequest': (context) => const EmpRequestScreen(),
        '/empBillPayment': (context) => const EmpBillPaymentScreen(),
        '/empRating': (context) => const EmpRatingReviewScreen(),
        '/empEmployee': (context) => const EmpEmployeeScreen(),
        '/empProfile': (context) => const EmpProfileScreen(),
        '/empReport': (context) => const EmpReportScreen(),
      },
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => WelcomeScreenState();
}

class WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor.withValues(alpha: 0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.auto_fix_high,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Neurofix',
                  style: textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome to your smart service solution.',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text('Log In'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text('Sign Up'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}