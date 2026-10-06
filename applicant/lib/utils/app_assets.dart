class AppAssets {
  AppAssets._();

  static const String logo = 'assets/logos/dhs_logo.png';

  // User-approved photography.
  static const String splashBackground =
      'assets/backgrounds/splash_approved.png';
  static const String dashboardDesktopBackground =
      'assets/backgrounds/dashboard_purple_home_desktop.png';
  static const String dashboardMobileBackground =
      'assets/backgrounds/dashboard_purple_home_mobile.png';

  // Login photography remains unchanged.
  static const String authBackground =
      'assets/backgrounds/auth_hero_hd.jpg';

  static const String registrationBackground =
      'assets/backgrounds/registration_evening_villa.jpg';
  static const String explorePlotsMobileBackground =
      'assets/backgrounds/explore_aerial_community.jpg';
  static const String dealerRegistrationBackground =
      'assets/backgrounds/dealer_signup_sunset_entrance.jpg';
  static const String dealersBackground =
      'assets/backgrounds/dealers_desktop_building.jpg';
  static const String dealersMobileBackground =
      'assets/backgrounds/dealers_mobile_gate.jpg';
  static const String contactBackground =
      'assets/backgrounds/contact_modern_home.jpg';
  static const String passwordBackground =
      'assets/backgrounds/password_garden_home.jpg';
  static const String mapDesktopLandscapeBackground =
      'assets/backgrounds/dealers_banner_hd.jpg';

  // Balloting uses a different photograph for each state.
  static const String applyBackground =
      'assets/backgrounds/balloting_aerial_evening.jpg';
  static const String ballotingDrawBackground =
      'assets/backgrounds/balloting_lit_boulevard.jpg';
  static const String ballotingResultBackground =
      'assets/backgrounds/balloting_pool_evening.jpg';
  static const String heroBackground =
      'assets/backgrounds/featured_lakeside_home.jpg';

  // Fallbacks only; real Firestore image URLs always take precedence.
  static const List<String> plotFallbacks = <String>[
    'assets/backgrounds/plot_image_garden_cottage.jpg',
    'assets/backgrounds/plot_image_purple_street.jpg',
    'assets/backgrounds/plot_image_lavender_house.jpg',
    'assets/backgrounds/plot_image_blue_gates.jpg',
    'assets/backgrounds/plot_image_flowering_road.jpg',
    'assets/backgrounds/plot_image_glass_villa.jpg',
  ];

  // Reuse the already-needed plot photographs on the live map instead of
  // carrying a second set of unused gallery assets.
  static const List<String> mapGalleryFallbacks = plotFallbacks;

  /// Local images that are likely to appear during normal navigation.
  /// Splash pre-caches these while its animation is visible so moving between
  /// screens does not briefly show the backdrop colour before the asset frame.
  static const List<String> precacheAssets = <String>[
    logo,
    dashboardDesktopBackground,
    dashboardMobileBackground,
    explorePlotsMobileBackground,
    dealerRegistrationBackground,
    dealersBackground,
    dealersMobileBackground,
    mapDesktopLandscapeBackground,
  ];
}
