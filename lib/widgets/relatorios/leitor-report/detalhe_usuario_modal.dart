import '/models/relatorio_leitores_model.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../heat_map_widget.dart';

class DetalheUsuarioModal extends StatelessWidget {
  final UserEngagementDetails details;
  final Function(String) formatarCargoCallback;

  const DetalheUsuarioModal({
    super.key,
    required this.details,
    required this.formatarCargoCallback,
  });

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
              "Total de ${details.totalServices} serviços de leitor no período.",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
            ),
            const Divider(height: 32),
            Text(
              "Cargos Mais Servidos",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            _buildCargosChart(details.cargoCount),
            // O gráfico de pizza continua
            const SizedBox(height: 32),

            // [RELATÓRIO ATUALIZADO]
            Text(
              "Perfil Pessoal (Dia x Horário)",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            // [MUDANÇA] Chama o HeatmapWidget
            HeatmapWidget(
              data: details.horarioDiaMap,
              baseColor: Theme.of(context).colorScheme.secondary,
            ),
            // [REMOVIDO] Gráfico de barras de dias da semana
          ],
        ),
      ),
    );
  }

  /// UI: Gráfico de Pizza para os Cargos (do Modal)
  Widget _buildCargosChart(Map<String, int> cargoData) {
    if (cargoData.isEmpty) {
      return const Text("Nenhum dado de cargo encontrado.");
    }
    final List<Color> pieColors = [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.red.shade400,
      Colors.purple.shade400,
    ];

    final total = cargoData.values.reduce((a, b) => a + b);
    if (total == 0) return const Text("Nenhum serviço prestado.");

    final pieSections =
        cargoData.entries.toList().asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final percentage = (data.value / total) * 100;

          return PieChartSectionData(
            value: data.value.toDouble(),
            title: "${percentage.toStringAsFixed(0)}%",
            radius: 100,
            color: pieColors[index % pieColors.length],
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList();

    final legendWidgets =
        cargoData.entries.toList().asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  color: pieColors[index % pieColors.length],
                ),
                const SizedBox(width: 8),
                Text(
                  // Usa a função de formatação passada como parâmetro
                  "${formatarCargoCallback(data.key)} (${data.value})",
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          );
        }).toList();

    return Row(
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: PieChart(PieChartData(sections: pieSections)),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: legendWidgets,
          ),
        ),
      ],
    );
  }
}
