import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/applicant_provider.dart';
import 'screens/applicant_dashboard_screen.dart';
import 'screens/application_submission_screen.dart';
import 'screens/balloting_screen.dart';
import 'screens/file_upload_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/login_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/plot_map_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/result_checking_screen.dart';
import 'screens/splash_screen.dart';
import 'utils/app_constants.dart';
import 'utils/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const DigitalHousingSocietyApp());
}

class DigitalHousingSocietyApp extends StatelessWidget {
  const DigitalHousingSocietyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApplicantProvider()),
        StreamProvider<User?>.value(
          initialData: FirebaseAuth.instance.currentUser,
          value: FirebaseAuth.instance.authStateChanges(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        title: 'Digital Housing Society',
        theme: AppTheme.lightTheme,
        initialRoute: AppConstants.splashRoute,
        routes: {
          AppConstants.splashRoute: (_) => const SplashScreen(),
          AppConstants.loginRoute: (_) => const LoginScreen(),
          AppConstants.registerRoute: (_) => const RegisterScreen(),
          AppConstants.forgotPasswordRoute: (_) => const ForgotPasswordScreen(),
          AppConstants.dashboardRoute: (_) => const ApplicantDashboardScreen(),
          AppConstants.applicationRoute: (_) => const ApplicationSubmissionScreen(),
          AppConstants.uploadRoute: (_) => const FileUploadScreen(),
          AppConstants.paymentRoute: (_) => const PaymentScreen(),
          AppConstants.ballotingRoute: (_) => const BallotingScreen(),
          AppConstants.resultRoute: (_) => const ResultCheckingScreen(),
          AppConstants.notificationsRoute: (_) => const NotificationsScreen(),
          AppConstants.mapRoute: (_) => const PlotMapScreen(),
          AppConstants.profileRoute: (_) => const ProfileScreen(),
        },
      ),
    );
  }
}
