import 'package:flutter/material.dart';

import 'plots_screen.dart';

class FavouritePlotsScreen extends StatelessWidget {
  const FavouritePlotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlotsScreen(initialFavouritesOnly: true);
  }
}
