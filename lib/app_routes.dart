class AdminRoutes {
  static const String ballotingProcessing = '/balloting-processing';
  static const String results             = '/balloting-result';
  static const String dashboard = '/';
  static const String applicants = '/applicants';
  static const String applicantDetails = '/applicant-details';
  static const String payments = '/payments';
  static const String plots = '/plots';
  static const String addPlot = '/add-plot';
  static const String balloting = '/balloting';
  static const String reports = '/reports';
  static const String dealers = '/dealers';
  static const String plotVisualization = '/plot-visualization';
  static const String notifications = '/notifications';
  static const String profile = '/profile';

  static const List<String> bottomRoutes = [
    dashboard,
    applicants,
    balloting,
    reports,
    profile,
  ];
}
