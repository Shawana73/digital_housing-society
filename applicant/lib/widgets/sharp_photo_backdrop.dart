import 'package:flutter/material.dart';

/// Clean full-bleed photo backdrop used by all hero banners.
/// Desktop and mobile both render one sharp photograph edge-to-edge,
/// without blur, duplicate side panels, or contained strip layouts.
class SharpPhotoBackdrop extends StatelessWidget {
  const SharpPhotoBackdrop({
    super.key,
    required this.asset,
    required this.compact,
    required this.background,
    this.desktopPhotoWidth = .55,
    this.desktopFit = BoxFit.cover,
    this.mobileFit = BoxFit.cover,
    this.mobileAlignment = Alignment.center,
    this.desktopAlignment = Alignment.center,
  });

  final String asset;
  final bool compact;
  final Color background;
  final double desktopPhotoWidth;
  final BoxFit desktopFit;
  final BoxFit mobileFit;
  final Alignment mobileAlignment;
  final Alignment desktopAlignment;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background,
      child: Image.asset(
        asset,
        width: double.infinity,
        height: double.infinity,
        fit: compact ? mobileFit : desktopFit,
        alignment: compact ? mobileAlignment : desktopAlignment,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      ),
    );
  }
}
