import 'package:flutter/material.dart';

import '../../../models/relatorio_ministro_model.dart';
import '../heat_map_widget.dart';

class DetalheMinistroModal extends StatelessWidget {
  final UserEngagementDetailsMinistros details;

  const DetalheMinistroModal({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              details.userName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              "Total de ${details.totalServices} serviços de ministro no período.",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
            ),
            const Divider(height: 32),
            Text(
              "Perfil de Engajamento Pessoal (Dia x Horário)",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            // Reutiliza o HeatmapWidget
            HeatmapWidget(
              data: details.horarioDiaMap,
              baseColor:
                  Theme.of(context).colorScheme.secondary, // Cor diferente
            ),
          ],
        ),
      ),
    );
  }
}
