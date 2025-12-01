// lib/widgets/home/menu_grid.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Importe o pacote de animação
import 'menu_card.dart';

class MenuGrid extends StatelessWidget {
  final List<MenuCardData> menuItems;

  const MenuGrid({
    super.key,
    required this.menuItems,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // Ajuste no aspect ratio para acomodar melhor o texto com fontes maiores
    final aspect = width > 600 ? 1.1 : 0.85;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: aspect,
      children: List.generate(menuItems.length, (index) {
        final item = menuItems[index];
        return Animate(
          delay: (index * 80).ms,
          effects: [
            FadeEffect(duration: 500.ms, curve: Curves.easeOut),
            SlideEffect(begin: const Offset(0, 0.2), duration: 400.ms),
          ],
          // O Widget que será animado
          child: MenuCard(
            icon: item.icon,
            title: item.title,
            subtitle: item.subtitle,
            color: item.color,
            onTap: item.onTap,
          ),
        );
      }),
    );
  }
}

class MenuCardData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  MenuCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}