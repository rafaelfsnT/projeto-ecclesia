// Em: lib/widgets/app/app_list_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppListItem extends StatelessWidget {
  final IconData leadingIcon;
  final String title;
  final Widget subtitle;
  final int index; // Para o delay da animação em cascata
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AppListItem({
    super.key,
    required this.leadingIcon,
    required this.title,
    required this.subtitle,
    required this.index,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Animate(
      delay: (index * 50).ms,
      effects: [
        FadeEffect(duration: 400.ms, curve: Curves.easeIn),
        SlideEffect(begin: const Offset(-0.1, 0), duration: 300.ms),
      ],
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Icon(leadingIcon, color: theme.colorScheme.primary),
          ),
          title: Text(title, style: textTheme.titleMedium),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: subtitle,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit),
                  color: theme.colorScheme.primary,
                  tooltip: 'Editar',
                  onPressed: onEdit,
                ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: theme.colorScheme.error,
                  tooltip: 'Excluir',
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}