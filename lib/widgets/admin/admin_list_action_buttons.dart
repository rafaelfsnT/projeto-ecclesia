import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';


class HomeAdminButton extends StatelessWidget {
  const HomeAdminButton({super.key});

  @override
  Widget build(BuildContext context) {

    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: 'Painel Principal',
      onPressed: () => context.go('/homeA'),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }
}


class AddActionButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onPressed;

  const AddActionButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.add_circle_outline),
      iconSize: 28,
      tooltip: tooltip,
      onPressed: onPressed,
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 400.ms)
        .slideX(begin: 0.5, end: 0);
  }
}