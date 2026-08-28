import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/app_assets.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_text_styles.dart';
import '../widgets/branded_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    Future.delayed(const Duration(seconds: 3), _routeNext);
  }

  void _routeNext() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().take(1).listen((user) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, user == null ? AppConstants.loginRoute : AppConstants.dashboardRoute);
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandedImageBackground(
        imagePath: AppAssets.heroBackground,
        overlayOpacity: .72,
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                width: 260,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: .94),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: AppColors.darkNavy.withValues(alpha: .18), blurRadius: 30, offset: const Offset(0, 18))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Hero(tag: 'app-logo', child: Image.asset(AppAssets.logo, width: 176, fit: BoxFit.contain)),
                    const SizedBox(height: 16),
                    Text('Digital Housing Society', textAlign: TextAlign.center, style: AppTextStyles.headingSmall.copyWith(color: AppColors.primaryText)),
                    const SizedBox(height: 6),
                    Text('Communities. Connected. Better Living.', textAlign: TextAlign.center, style: AppTextStyles.captionText),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
