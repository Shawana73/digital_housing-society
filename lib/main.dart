import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app_routes.dart';
import 'models/admin_models.dart';
import 'screens/add_plot_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/applicant_details_screen.dart';
import 'screens/applicant_verification_screen.dart';
import 'screens/balloting_screen.dart';
import 'screens/dealer_verification_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/payment_verification_screen.dart';
import 'screens/plot_management_screen.dart';
import 'screens/plot_visualization_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/balloting_processing_screen.dart';
import 'screens/result_screen.dart';
import 'theme/admin_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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
      theme: AdminTheme.theme,
      initialRoute: AdminRoutes.dashboard,
      routes: {
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
      onGenerateRoute: (settings) {
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
