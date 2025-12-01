import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/relatorio_ministro_model.dart';
import '../../services/ministros_pdf_generator.dart';
import '../../widgets/app/app_scaffold.dart';
import '../../widgets/relatorios/ministro-report/detalhe_ministro_modal.dart';
import '../../widgets/relatorios/ministro-report/filtro_relatorio_ministro_widget.dart';
import '../../widgets/relatorios/ministro-report/lista_resultados_ministro_widget.dart';

class RelatorioMinistrosPage extends StatefulWidget {
  const RelatorioMinistrosPage({super.key});

  @override
  State<RelatorioMinistrosPage> createState() => _RelatorioMinistrosPageState();
}

class _RelatorioMinistrosPageState extends State<RelatorioMinistrosPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  EngagementReportMinistros? _report;

  // --- LÓGICA DE SELEÇÃO DE DATA (VALIDAÇÕES) ---

  Future<void> _selectStartDate() async {
    final now = DateTime.now();
    // Data inicial não pode ser futura, nem maior que a data final atual
    final lastDateLimit = _endDate.isAfter(now) ? now : _endDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: lastDateLimit,
      locale: const Locale('pt', 'BR'),
      helpText: 'DATA INICIAL',
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      // Não pode ser menor que o início
      lastDate: now,
      // Não pode ser futura
      locale: const Locale('pt', 'BR'),
      helpText: 'DATA FINAL',
    );

    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  // --- HELPER METHODS ---

  bool _isCargoDeMinistro(String key) {
    return key.toLowerCase().contains('ministro');
  }

  String _formatarCargo(String cargoKey) {
    if (cargoKey.contains('ministro')) return 'Vagas de Ministro';
    return cargoKey;
  }

  String _getPeriodo(int hora) {
    if (hora < 12) return 'Manhã';
    if (hora < 18) return 'Tarde';
    return 'Noite';
  }

  String _formatarDia(int weekday) {
    const dias = {
      1: 'SEG',
      2: 'TER',
      3: 'QUA',
      4: 'QUI',
      5: 'SEX',
      6: 'SAB',
      7: 'DOM',
    };
    return dias[weekday] ?? '';
  }

  // --- LÓGICA DE NEGÓCIO ---

  Future<void> _gerarRelatorio() async {
    // Validação extra
    if (_startDate.isAfter(_endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("A data inicial não pode ser maior que a final."),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _report = null;
    });

    final startTimestamp = Timestamp.fromDate(
      DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0),
    );
    final endTimestamp = Timestamp.fromDate(
      DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59),
    );

    final Map<String, UserEngagementDetailsMinistros> userMap = {};
    final Map<String, int> cargoGargaloMap = {};
    final Map<String, int> cargoTotaisCriadosMap = {};
    final Map<String, int> totalHorarioDiaMap = {};
    const String cargoKeyGenerico = 'ministro';
    final DateTime agora = DateTime.now();

    try {
      final query =
          await FirebaseFirestore.instance
              .collection('missas')
              .where('dataHora', isGreaterThanOrEqualTo: startTimestamp)
              .where('dataHora', isLessThanOrEqualTo: endTimestamp)
              .get();

      for (final missaDoc in query.docs) {
        final data = missaDoc.data();
        final dataHora = (data['dataHora'] as Timestamp).toDate();

        final DateTime dataExpiracao = dataHora.add(const Duration(hours: 1));
        if (dataExpiracao.isAfter(agora)) continue;

        final escala = data['escala'] as Map<String, dynamic>? ?? {};
        final weekday = dataHora.weekday;
        final diaStr = _formatarDia(weekday);
        final periodoStr = _getPeriodo(dataHora.hour).toUpperCase();
        final compositeKey = "$diaStr-$periodoStr";

        for (final entry in escala.entries) {
          final cargo = entry.key;
          final uid = entry.value;

          if (_isCargoDeMinistro(cargo)) {
            cargoTotaisCriadosMap[cargoKeyGenerico] =
                (cargoTotaisCriadosMap[cargoKeyGenerico] ?? 0) + 1;

            if (uid != null && uid is String) {
              final details = userMap.putIfAbsent(
                uid,
                () => UserEngagementDetailsMinistros(),
              );
              details.totalServices++;
              details.horarioDiaMap[compositeKey] =
                  (details.horarioDiaMap[compositeKey] ?? 0) + 1;
              totalHorarioDiaMap[compositeKey] =
                  (totalHorarioDiaMap[compositeKey] ?? 0) + 1;
            } else {
              cargoGargaloMap[cargoKeyGenerico] =
                  (cargoGargaloMap[cargoKeyGenerico] ?? 0) + 1;
            }
          }
        }
      }

      for (final uid in userMap.keys) {
        try {
          final userDoc =
              await FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(uid)
                  .get();
          userMap[uid]!.userName =
              userDoc.exists
                  ? (userDoc.data()!['nome'] ?? 'Nome não cadastrado')
                  : 'Usuário Excluído';
        } catch (e) {
          userMap[uid]!.userName = 'Erro ao buscar nome';
        }
      }

      setState(() {
        _report = EngagementReportMinistros(
          userEngagement: userMap,
          cargoGargalos: cargoGargaloMap,
          cargoTotaisCriados: cargoTotaisCriadosMap,
          totalHorarioDiaMap: totalHorarioDiaMap,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao gerar relatório: $e")));
    }
  }

  void _showUserDetailModal(
    BuildContext context,
    UserEngagementDetailsMinistros details,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return DetalheMinistroModal(details: details);
      },
    );
  }

  Future<void> _exportarPDF() async {
    if (_report == null) return;

    setState(() => _isLoading = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Gerando PDF..."),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final generator = MinistrosPdfGenerator(
        report: _report!,
        startDate: _startDate,
        endDate: _endDate,
      );
      await generator.generateAndOpenFile();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao exportar PDF: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Relatório de Ministros",
      showBackButton: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Widget de Filtros Padronizado
            FiltroRelatorioMinistroWidget(
              startDate: _startDate,
              endDate: _endDate,
              isLoading: _isLoading,
              // Passamos as novas funções
              onTapStartDate: _selectStartDate,
              onTapEndDate: _selectEndDate,
              onGerarRelatorio: _gerarRelatorio,
              onExportPDF: _exportarPDF,
              canExport: _report != null,
            ),
            const Divider(height: 32),

            // Widget de Resultados
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _report == null
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.group,
                              size: 60,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Selecione um período e gere o relatório.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                      : ListaResultadosMinistrosWidget(
                        report: _report!,
                        formatarCargoCallback: _formatarCargo,
                        onUserTap:
                            (details) => _showUserDetailModal(context, details),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
