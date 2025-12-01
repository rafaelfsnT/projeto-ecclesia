import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeekdayChartWidget extends StatelessWidget {
  final Map<int, int> weekdayData;
  final Color barColor;

  const WeekdayChartWidget({
    super.key,
    required this.weekdayData,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final maxYValue = weekdayData.values.fold(0.0, (max, v) => v > max ? v.toDouble() : max);
    final maxY = (maxYValue < 5 ? 5 : maxYValue) * 1.2; // Garante um teto mínimo

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barGroups: weekdayData.entries
              .map(
                (entry) => BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.toDouble(),
                  color: barColor,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          )
              .toList(),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  );
                  String text;
                  switch (value.toInt()) {
                    case 1: text = 'SEG'; break;
                    case 2: text = 'TER'; break;
                    case 3: text = 'QUA'; break;
                    case 4: text = 'QUI'; break;
                    case 5: text = 'SEX'; break;
                    case 6: text = 'SAB'; break;
                    case 7: text = 'DOM'; break;
                    default: text = '';
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(text, style: style),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}