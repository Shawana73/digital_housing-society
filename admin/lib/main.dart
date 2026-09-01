import 'package:flutter/material.dart';  //flutter package , framework libraray
import 'package:firebase_core/firebase_core.dart'; //firebase core package// required for Firebase initialization
import 'firebase_options.dart'; //firebase configuration options
import 'app_routes.dart';  //routes names defined
import 'models/admin_models.dart';
import 'screens/admin_login/admin_login_screen.dart';
import 'screens/add_plot/add_plot_screen.dart';
import 'screens/applicants/applicant_verification_screen.dart';
import 'screens/dashboard/admin_dashboard_screen.dart';
import 'screens/applicant_details/applicant_details_screen.dart';
import 'screens/balloting/balloting_screen.dart';
import 'screens/dealers/dealer_verification_screen.dart';
import 'screens/notifications/notification_screen.dart';
import 'screens/payments/payment_verification_screen.dart';
import 'screens/plot_management/plot_management_screen.dart';
import 'screens/plot_visualization/plot_visualization_screen.dart';
import 'screens/admin_profile/profile_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/balloting_processing/balloting_processing_screen.dart';
import 'screens/result/result_screen.dart';
import 'theme/admin_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();  //Are flutter's required framework bindings initialized?

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,  //firebase configuration selected according to current platforms
  );

  runApp(const DigitalHousingAdminApp());
}

class DigitalHousingAdminApp extends StatelessWidget {
  const DigitalHousingAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Digital Housing Admin Panel',
      theme: AdminTheme.theme, //overall app visual config
      initialRoute: AdminRoutes.login, //specify initial route when app gets started
      routes: {  //maps named routes with their screens
        AdminRoutes.login: (_) => const AdminLoginScreen(),
        AdminRoutes.dashboard: (_) => const AdminDashboardScreen(),
        AdminRoutes.applicants: (_) => const ApplicantVerificationScreen(),
        AdminRoutes.payments: (_) => const PaymentVerificationScreen(),
        AdminRoutes.plots: (_) => const PlotManagementScreen(),
        AdminRoutes.addPlot: (_) => const AddPlotScreen(),
        AdminRoutes.balloting: (_) => const BallotingScreen(),
        AdminRoutes.ballotingProcessing: (context) {
          final args = ModalRoute.of(context)!.settings.arguments
          as Map<String, String>? ?? {};
          return BallotingProcessingScreen(
            schemeName: args['name'] ?? 'Green Valley Villas',
            schemeSize:  args['size'] ?? '5 Marla Villa',
          );
        },
        AdminRoutes.results: (_) => const ResultScreen(),
        AdminRoutes.reports: (_) => const ReportsScreen(),
        AdminRoutes.dealers: (_) => const DealerVerificationScreen(),
        AdminRoutes.plotVisualization: (_) => const PlotVisualizationScreen(),
        AdminRoutes.notifications: (_) => const NotificationScreen(),
        AdminRoutes.profile: (_) => const ProfileScreen(),
      },
      onGenerateRoute: (settings) {   //dynamic route handling
        if (settings.name == AdminRoutes.applicantDetails && settings.arguments is Applicant) {
          final applicant = settings.arguments! as Applicant;
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => ApplicantDetailsScreen(applicant: applicant),
          );
        }
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      },
    );
  }
}
