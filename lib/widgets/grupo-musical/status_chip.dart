import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // Define a cor com base no status
    final Color backgroundColor;
    final Color textColor;
    final IconData iconData;

    switch (status.toLowerCase()) {
      case 'ativo':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        iconData = Icons.check_circle_outline;
        break;
      case 'inativo':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        iconData = Icons.highlight_off;
        break;
      case 'pausa': // <-- Adicionado case para Pausa
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        iconData = Icons.pause_circle_outline;
        break;
      default: // Caso desconhecido ou nulo
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        iconData = Icons.help_outline;
    }

    return Chip(
      avatar: Icon(iconData, color: textColor, size: 16),
      label: Text(
        status.isEmpty ? 'Desconhecido' : status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 0),
      labelPadding: const EdgeInsets.only(left: 2.0, right: 4.0),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
