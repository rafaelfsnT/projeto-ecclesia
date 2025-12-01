import '/models/relatorio_leitores_model.dart';
import 'package:flutter/material.dart';

class TopLeitorTile extends StatelessWidget {
  final UserEngagementDetails details;
  final int rank;
  final VoidCallback onTap;

  const TopLeitorTile({
    super.key,
    required this.details,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: rank == 1 ? Colors.green.shade50 : null,
      child: ListTile(
        leading: Text(
          "$rankº",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: rank == 1 ? Colors.green.shade700 : null,
          ),
        ),
        title: Text(
          details.userName,
          style: TextStyle(
            fontWeight: rank == 1 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Text(
          "${details.totalServices} serviços",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}