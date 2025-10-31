import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fyp/modules/customer/billPaymentHistory.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'modules/customer/favoriteHandyman.dart';
import 'modules/customer/profile.dart';
import 'modules/customer/rateReviewHistory.dart';
import 'modules/customer/reqHistory.dart';
import 'modules/customer/register.dart';
import 'modules/customer/homepage.dart';
import 'service/firebase_options.dart';
import 'shared/theme.dart';
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const supabaseUrl = 'https://aaytrvrlwimcvguqrogw.supabase.co';
  const supabaseKey = String.fromEnvironment('SUPABASE_KEY');
  const stripePublishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Stripe.publishableKey = stripePublishableKey;
  await Stripe.instance.applySettings();
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
      initialRoute: '/login',
      routes: {
        // '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const CustHomepage(),
        '/profile': (context) => const ProfileScreen(),
        '/request': (context) => const RequestHistoryScreen(),
        '/favorite': (context) => const FavoriteScreen(),
        '/rating': (context) => const RateReviewHistoryScreen(),
        '/billPayment': (context) => const BillPaymentHistoryScreen(),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.handyman,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Handyman Connect',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your trusted solution for all your service needs.',
                style: Theme.of(context).textTheme.bodyMedium,
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
                child: OutlinedButton(
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
    );
  }
}
