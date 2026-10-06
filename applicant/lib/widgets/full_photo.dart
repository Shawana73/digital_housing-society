import 'package:flutter/material.dart';

/// Shows a sharp plot photo that fills the card naturally.
/// No blurred background, no duplicate layers, and no contain-mode empty bars.
class FullPhoto extends StatelessWidget {
  const FullPhoto({super.key, required this.asset, this.networkUrl});

  final String asset;
  final String? networkUrl;

  @override
  Widget build(BuildContext context) {
    final url = networkUrl?.trim() ?? '';
    Widget fallback() => Image.asset(
          asset,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          filterQuality: FilterQuality.high,
          alignment: Alignment.center,
          gaplessPlayback: true,
        );

    return ColoredBox(
      color: const Color(0xFFF1F3F9),
      child: ClipRect(
        child: url.isEmpty
            ? fallback()
            : Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                filterQuality: FilterQuality.high,
                alignment: Alignment.center,
                gaplessPlayback: true,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  // Keep a real local property photo visible while the live
                  // network image is downloading instead of flashing a flat
                  // placeholder colour.
                  return fallback();
                },
                errorBuilder: (_, __, ___) => fallback(),
              ),
      ),
    );
  }
}
