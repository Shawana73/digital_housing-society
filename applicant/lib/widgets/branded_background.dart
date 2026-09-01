import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class BrandedImageBackground extends StatelessWidget {
  const BrandedImageBackground({
    super.key,
    required this.imagePath,
    required this.child,
    this.overlayOpacity = 0.74,
    this.padding,
    this.fit = BoxFit.cover,
  });

  final String imagePath;
  final Widget child;
  final double overlayOpacity;
  final EdgeInsetsGeometry? padding;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: fit,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.infoBlue.withValues(alpha: overlayOpacity),
              AppColors.primaryPurple.withValues(alpha: overlayOpacity * .92),
              AppColors.deepPurple.withValues(alpha: overlayOpacity * .88),
            ],
          ),
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}
