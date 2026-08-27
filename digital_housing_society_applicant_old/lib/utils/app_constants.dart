class AppConstants {
  AppConstants._();

  static const String splashRoute = '/splash';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String dashboardRoute = '/dashboard';
  static const String applicationRoute = '/application';
  static const String uploadRoute = '/upload';
  static const String paymentRoute = '/payment';
  static const String ballotingRoute = '/balloting';
  static const String resultRoute = '/result';
  static const String notificationsRoute = '/notifications';
  static const String mapRoute = '/map';
  static const String profileRoute = '/profile';

  static const Map<String, int> plotFeeMap = {
    '3 Marla': 50000,
    '5 Marla': 80000,
    '10 Marla': 120000,
  };

  static const List<String> plotTypes = ['3 Marla', '5 Marla', '10 Marla'];

  static const List<String> pakistaniCities = [
    'Gujranwala',
    'Lahore',
    'Faisalabad',
    'Rawalpindi',
    'Islamabad',
    'Karachi',
    'Multan',
    'Sialkot',
    'Gujrat',
    'Other',
  ];

  static const List<String> bottomNavRoutes = [
    dashboardRoute,
    applicationRoute,
    uploadRoute,
    paymentRoute,
    profileRoute,
  ];
}
