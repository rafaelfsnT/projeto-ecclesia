import '/models/relatorio_cancelamento_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ListaResultadosCancelamentoWidget extends StatelessWidget {
  final CancelamentoReport report;
  final Map<String, String> userNames;

  const ListaResultadosCancelamentoWidget({
    super.key,
    required this.report,
    required this.userNames,
  });

  @override
  Widget build(BuildContext context) {
    if (report.listaCompleta.isEmpty) {
      return const Center(child: Text("Nenhum cancelamento encontrado."));
    }

    final sortedMotivos =
        report.topMotivos.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final sortedUsuarios =
        report.topUsuarios.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return ListView(
      children: [
        // --- 1. KPIs ---
        _buildKpiCards(context),

        // --- 2. Gráfico de Motivos ---
        _buildSectionTitle(context, "Principais Motivos de Cancelamento"),
        _buildTopMotivosChart(context, sortedMotivos),

        // --- 3. Lista de Top Usuários ---
        _buildSectionTitle(context, "Usuários com Mais Cancelamentos"),
        ..._buildTopUsuariosList(context, sortedUsuarios),

        // --- 4. Lista Detalhada ---
        const SizedBox(height: 16),
        ExpansionTile(
          title: Text(
            "Ver todos os ${report.totalCancelamentos} registros",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          children: [_buildDetailedList(context, dateFormat)],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildKpiCards(BuildContext context) {
    final taxaUltimaHora =
        (report.totalCancelamentos == 0)
            ? 0.0
            : (report.totalUltimaHora / report.totalCancelamentos) * 100;

    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            title: "Total",
            value: report.totalCancelamentos.toString(),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            title: "Última Hora",
            value: report.totalUltimaHora.toString(),
            color: Colors.orange.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            title: "Taxa (Últ. Hora)",
            value: "${taxaUltimaHora.toStringAsFixed(0)}%",
            color: Colors.red.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildTopMotivosChart(
    BuildContext context,
    List<MapEntry<String, int>> sortedMotivos,
  ) {
    final total = report.topMotivos.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final List<Color> pieColors = [
      Colors.red.shade400,
      Colors.orange.shade400,
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.purple.shade400,
    ];

    final pieSections =
        sortedMotivos.take(5).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final percentage = (data.value / total) * 100;
          return PieChartSectionData(
            value: data.value.toDouble(),
            title: "${percentage.toStringAsFixed(0)}%",
            radius: 70,
            color: pieColors[index % pieColors.length],
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList();

    final legendWidgets =
        sortedMotivos.take(5).toList().asMap().entries.map((entry) {
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
                // --- [INÍCIO DA CORREÇÃO] ---
                // Adicionamos 'Expanded' para que o texto quebre a linha
                // ou use 'ellipsis' se for muito longo.
                Expanded(
                  child: Text(
                    "${data.key} (${data.value})",
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                // --- [FIM DA CORREÇÃO] ---
              ],
            ),
          );
        }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: PieChart(PieChartData(sections: pieSections)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: legendWidgets,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTopUsuariosList(
    BuildContext context,
    List<MapEntry<String, int>> sortedUsuarios,
  ) {
    if (sortedUsuarios.isEmpty) return [const Text("Nenhum usuário cancelou.")];

    return sortedUsuarios.take(5).map((entry) {
      final uid = entry.key;
      final count = entry.value;
      final nome = userNames[uid] ?? "Usuário Desconhecido ($uid)";

      return Card(
        elevation: 0,
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHigh.withValues(alpha: 0.3),
        child: ListTile(
          leading: CircleAvatar(child: Text(count.toString())),
          title: Text(nome),
          subtitle: const Text("Total de Cancelamentos"),
        ),
      );
    }).toList();
  }

  Widget _buildDetailedList(BuildContext context, DateFormat dateFormat) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: report.listaCompleta.length,
      itemBuilder: (context, index) {
        final doc = report.listaCompleta[index];
        final log = doc.data() as Map<String, dynamic>;
        final data = (log['dataCancelamento'] as Timestamp).toDate();
        final uid = log['usuarioId'];
        final nome = userNames[uid] ?? uid;

        final IconData icon =
            log['tipo'] == 'missa'
                ? Icons.church_rounded
                : Icons.business_center_rounded;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(icon),
            title: Text("Usuário: $nome"),
            subtitle: Text(
              "Data: ${dateFormat.format(data)}\nMotivo: ${log['justificativa']}",
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

// Widget auxiliar para os KPIs
class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withValues(alpha: 0.5), width: 1),
      ),
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
