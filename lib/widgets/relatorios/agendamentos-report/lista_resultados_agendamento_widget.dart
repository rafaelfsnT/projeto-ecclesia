import '/models/relatorio_agendamento_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../periodo_chart_widget.dart';
import '../weekday_chart_widget.dart';

class ListaResultadosAgendamentoWidget extends StatelessWidget {
  final AgendamentoReport report;
  final Map<String, String> userNames;

  const ListaResultadosAgendamentoWidget({
    super.key,
    required this.report,
    required this.userNames,
  });

  @override
  Widget build(BuildContext context) {
    if (report.listaCompleta.isEmpty) {
      return const Center(child: Text("Nenhum agendamento encontrado."));
    }

    final sortedAssuntos =
        report.topAssuntos.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final sortedHorarios =
        report.topHorariosEspecificos.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return ListView(
      children: [
        _buildKpiCard(context),

        _buildSectionTitle(context, "Assuntos Mais Procurados"),
        _buildTopAssuntosChart(context, sortedAssuntos),

        _buildSectionTitle(context, "Horários Mais Agendados"),
        _buildTopHorariosList(context, sortedHorarios),

        // --- 3. Gráfico de Período ---
        _buildSectionTitle(context, "Agendamentos por Período"),
        PeriodoChartWidget(horarioData: report.horarioEngagement),

        // --- 4. Gráfico de Dia da Semana ---
        _buildSectionTitle(context, "Agendamentos por Dia da Semana"),
        WeekdayChartWidget(
          weekdayData: report.weekdayEngagement,
          barColor: Theme.of(context).colorScheme.primary,
        ),

        // --- 5. Lista Detalhada ---
        const SizedBox(height: 16),
        ExpansionTile(
          title: Text(
            "Ver todos os ${report.totalAgendamentos} agendamentos",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          children: [_buildDetailedList(context, dateFormat)],
        ),
      ],
    );
  }

  Widget _buildTopHorariosList(
    BuildContext context,
    List<MapEntry<String, int>> sortedHorarios,
  ) {
    if (sortedHorarios.isEmpty) return const Text("Sem dados.");

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sortedHorarios.take(6).length, // Mostra top 6
        itemBuilder: (context, index) {
          final entry = sortedHorarios[index];
          return Card(
            color:
                index == 0
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null, // Destaque para o 1º lugar
            margin: const EdgeInsets.only(right: 12, bottom: 4),
            child: Container(
              width: 100,
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entry.key, // O Horário (ex: 08:00)
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "${entry.value} agend.",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildKpiCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Total de Agendamentos",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            Text(
              report.totalAgendamentos.toString(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAssuntosChart(
    BuildContext context,
    List<MapEntry<String, int>> sortedAssuntos,
  ) {
    // Calcula o total para fazer a porcentagem
    final total = report.topAssuntos.values.fold(0, (a, b) => a + b);

    // Se não tiver dados, não mostra nada
    if (total == 0) return const SizedBox.shrink();

    final List<Color> pieColors = [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.red.shade400,
      Colors.purple.shade400,
    ];

    // --- GERAÇÃO DAS FATIAS (COM A CORREÇÃO VISUAL) ---
    final pieSections =
        sortedAssuntos.take(5).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final percentage = (data.value / total) * 100;

          // [CORREÇÃO] Só mostra o texto se a fatia for maior que 5%
          final bool showTitle = percentage > 5;

          return PieChartSectionData(
            value: data.value.toDouble(),
            // Se for pequeno demais, retorna string vazia ""
            title: showTitle ? "${percentage.toStringAsFixed(0)}%" : "",
            radius: 60,
            // Reduzi levemente para ficar mais elegante
            color: pieColors[index % pieColors.length],
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList();

    // GERAÇÃO DA LEGENDA (MANTIDA IGUAL)
    final legendWidgets =
        sortedAssuntos.take(5).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final percentage = (data.value / total) * 100;

          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: pieColors[index % pieColors.length],
                    shape: BoxShape.circle, // Mudei para bolinha (opcional)
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    // Adicionei a porcentagem na legenda também para ajudar
                    "${data.key} (${percentage.toStringAsFixed(0)}%)",
                    style: const TextStyle(
                      fontSize: 13,
                    ), // Fonte levemente menor
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // O Gráfico
            SizedBox(
              width: 140, // Aumentei um pouco a área do gráfico
              height: 140,
              child: PieChart(
                PieChartData(
                  sections: pieSections,
                  centerSpaceRadius: 30,
                  // [DICA] Cria um buraco no meio (Donut), fica mais bonito
                  sectionsSpace: 2,
                  // Espaço branco entre as fatias
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(width: 24),
            // A Legenda
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: legendWidgets,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedList(BuildContext context, DateFormat dateFormat) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: report.listaCompleta.length,
      itemBuilder: (context, index) {
        final doc = report.listaCompleta[index];
        final log = doc.data() as Map<String, dynamic>;
        final data = (log['slotInicio'] as Timestamp).toDate();
        final uid = log['usuarioId'];
        final nome = userNames[uid] ?? uid;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text("Usuário: $nome"),
            subtitle: Text(
              "Data: ${dateFormat.format(data)}\nAssunto: ${log['assunto']}",
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
