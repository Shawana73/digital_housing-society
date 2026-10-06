import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/app_assets.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/app_text_styles.dart';

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
  bool _didPrecacheAssets = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2000), _routeNext);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheAssets) return;
    _didPrecacheAssets = true;

    // Preload the local photography most likely to be used immediately after
    // splash. This avoids a temporary solid-colour frame when navigating to a
    // screen whose hero image has not been decoded yet.
    for (final asset in AppAssets.precacheAssets) {
      precacheImage(AssetImage(asset), context);
    }
  }

  void _routeNext() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().take(1).listen((user) async {
      if (user == null) {
        if (mounted) Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
        return;
      }
      // A verified cached Firebase session can route immediately. This avoids
      // an unnecessary network reload on every app start. If the cached user
      // is still unverified, reload once so a newly verified account is picked
      // up before deciding whether to sign out.
      if (user.emailVerified) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppConstants.dashboardRoute);
        }
        return;
      }

      await user.reload();
      final refreshed = FirebaseAuth.instance.currentUser;
      if (!mounted) return;
      if (refreshed?.emailVerified == true) {
        Navigator.pushReplacementNamed(context, AppConstants.dashboardRoute);
      } else {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please verify your email before continuing.')),
        );
        Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
      }
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
    final desktop = MediaQuery.sizeOf(context).width >= 850;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppAssets.splashBackground,
              fit: BoxFit.cover,
              // The approved source is portrait. On a wide Chrome window a
              // slightly lower focal point keeps both open gates and the
              // driveway visible instead of spending most of the crop on sky.
              alignment: desktop
                  ? const Alignment(0, .42)
                  : const Alignment(0, .08),
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
            ),
            ColoredBox(
              color: Colors.black.withValues(alpha: desktop ? .24 : .16),
            ),
            Align(
              alignment: Alignment.center,
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 260,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: .96),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkNavy.withValues(alpha: .18),
                        blurRadius: 30,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Hero(
                        tag: 'app-logo',
                        child: Image.asset(
                          AppAssets.logo,
                          width: 176,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Digital Housing Society',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headingSmall.copyWith(
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Communities. Connected. Better Living.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.captionText,
                      ),
                    ],
                  ),
                ),
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
