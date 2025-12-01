
import 'package:flutter/material.dart';

class HeatmapWidget extends StatelessWidget {
  final Map<String, int> data;
  final Color baseColor;

  const HeatmapWidget({super.key, required this.data, required this.baseColor});

  static const List<String> _dias = [
    'SEG',
    'TER',
    'QUA',
    'QUI',
    'SEX',
    'SAB',
    'DOM',
  ];
  static const List<String> _periodos = ['MANHÃ', 'TARDE', 'NOITE'];

  @override
  Widget build(BuildContext context) {
    final int maxValue = data.values.fold(0, (max, v) => v > max ? v : max);
    if (maxValue == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Nenhum serviço prestado neste período."),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade300, width: 1),
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: [
          // --- Linha de Cabeçalho (Dias da Semana) ---
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade200),
            children: [
              const TableCell(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Período",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              for (final dia in _dias)
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      dia,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          // --- Linhas de Dados (Manhã, Tarde, Noite) ---
          for (final periodo in _periodos)
            TableRow(
              children: [
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      periodo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Células de dados
                for (final dia in _dias)
                  _buildHeatmapCell(
                    data['$dia-$periodo'] ?? 0,
                    maxValue,
                    baseColor,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// UI: Helper que constrói uma célula colorida do Heatmap
  TableCell _buildHeatmapCell(int value, int maxValue, Color baseColor) {
    final double opacity = (maxValue == 0) ? 0.0 : (value / maxValue);
    // Garante opacidade mínima de 0.1 se > 0
    final Color cellColor = baseColor.withValues(
      alpha: value == 0 ? 0.0 : (opacity < 0.1 ? 0.1 : opacity),
    );
    // Cor do texto (branco ou preto) para contraste
    final Color textColor = opacity > 0.6 ? Colors.white : Colors.black;

    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Container(
        color: value > 0 ? cellColor : Colors.grey.shade50,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Text(
          value.toString(),
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
      ),
    );
  }
}
