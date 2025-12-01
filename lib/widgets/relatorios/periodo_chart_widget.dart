import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PeriodoChartWidget extends StatelessWidget {
  final Map<String, int> horarioData;
  const PeriodoChartWidget({super.key, required this.horarioData});

  @override
  Widget build(BuildContext context) {
    final List<Color> pieColors = [
      Colors.blue.shade400, // Manhã
      Colors.orange.shade400, // Tarde
      Colors.indigo.shade400, // Noite
    ];

    final total = horarioData.values.fold(0, (a, b) => a + b);
    if (total == 0) {
      return const Center(child: Text("Nenhum serviço prestado."));
    }

    final pieSections =
    horarioData.entries.toList().asMap().entries.map((entry) {
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
    horarioData.entries.toList().asMap().entries.map((entry) {
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
              "${data.key} (${data.value})",
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