import '/models/relatorio_leitores_model.dart';
import 'package:flutter/material.dart';
import '../gargalo_card_widget.dart';
import '../heat_map_widget.dart';
import 'top_leitor_title.dart';

class ListaResultadosLeitoresWidget extends StatelessWidget {
  final EngagementReport report;
  final String filtroCargoLabel;
  final Function(String) formatarCargoCallback;
  final Function(UserEngagementDetails) onUserTap;

  const ListaResultadosLeitoresWidget({
    super.key,
    required this.report,
    required this.filtroCargoLabel,
    required this.formatarCargoCallback,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    final sortedUsers =
        report.userEngagement.entries.toList()..sort(
          (a, b) => b.value.totalServices.compareTo(a.value.totalServices),
        );

    if (sortedUsers.isEmpty && report.cargoGargalos.isEmpty) {
      return Center(
        child: Text("Nenhum dado encontrado para '$filtroCargoLabel'."),
      );
    }

    return ListView(
      children: [
        // --- Relatório 1: Top Voluntários (Clicável) ---
        Text("Top Leitores", style: Theme.of(context).textTheme.titleLarge),
        Text("Voluntários mais engajados no período selecionado."),
        const SizedBox(height: 8),
        if (sortedUsers.isEmpty)
          const Text("Nenhum leitor serviu neste período.")
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedUsers.length,
            itemBuilder: (context, index) {
              final entry = sortedUsers[index];
              return TopLeitorTile(
                details: entry.value,
                rank: index + 1,
                onTap: () => onUserTap(entry.value),
              );
            },
          ),

        // --- Relatório 2: Gargalos ---
        const Divider(height: 40),
        Text(
          "Vagas Ociosas (Gargalos)",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text("Cargos que não foram preenchidos no período."),
        const SizedBox(height: 8),
        _buildGargaloList(report.cargoGargalos, report.cargoTotaisCriados),

        // --- [RELATÓRIO ATUALIZADO] ---
        const Divider(height: 40),
        Text(
          "Perfil de Engajamento (Dia x Horário)",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        // [MUDANÇA] Chama o HeatmapWidget
        HeatmapWidget(
          data: report.totalHorarioDiaMap,
          baseColor: Theme.of(context).colorScheme.primary,
        ),

        // [REMOVIDO] Gráficos de Período e Dia da Semana
      ],
    );
  }

  // O _buildGargaloList pode ficar aqui, pois ele
  // constrói uma lista (ListView.builder)
  Widget _buildGargaloList(
    Map<String, int> gargaloData,
    Map<String, int> totalData,
  ) {
    if (gargaloData.isEmpty) {
      return const Text("Nenhuma vaga ociosa encontrada. Parabéns!");
    }

    final sortedGargalos =
        gargaloData.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedGargalos.length,
      itemBuilder: (context, index) {
        final entry = sortedGargalos[index];
        final cargoKey = entry.key;
        final gargaloCount = entry.value;
        final totalCount = totalData[cargoKey] ?? gargaloCount;

        return GargaloCardWidget(
          cargoKey: cargoKey,
          gargaloCount: gargaloCount,
          totalCount: totalCount,
          formatarCargoCallback: formatarCargoCallback,
        );
      },
    );
  }
}
