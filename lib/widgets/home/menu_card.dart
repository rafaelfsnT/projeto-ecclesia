// lib/widgets/home/menu_card.dart

import 'package:flutter/material.dart';

class MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const MenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Obtém o tema atual
    final theme = Theme.of(context);
    final cardTheme = theme.cardTheme; // Pega o tema do card definido no theme_app.dart
    final textTheme = theme.textTheme;

    return Card(
      // Usa a elevação e a forma (shape) definidas no CardTheme
      elevation: cardTheme.elevation,
      shape: cardTheme.shape,
      // Define a cor da sombra baseada na cor do card para um efeito mais suave
      shadowColor: color.withOpacity(0.4),
      clipBehavior: Clip.antiAlias, // Garante que o gradiente não "vaze" das bordas arredondadas
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32, // Um pouco maior para melhor visibilidade
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                // Usa o estilo de fonte do tema como base, mas com cor branca
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                // Usa o estilo de fonte do tema como base, mas com cor branca e opacidade
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13, // Tamanho ligeiramente maior para legibilidade
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}