import '/widgets/relatorios/cancelamentos-report/filtro_relatorio_cancelamento_widget.dart';
import '/widgets/relatorios/cancelamentos-report/lista_resultados_cancelamentos_widget.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/widgets/app/app_scaffold.dart';
import '/services/cancelamentos_pdf_generator.dart';
import '/models/relatorio_cancelamento_model.dart';

class RelatorioCancelamentosPage extends StatefulWidget {
  const RelatorioCancelamentosPage({super.key});

  @override
  State<RelatorioCancelamentosPage> createState() =>
      _RelatorioCancelamentosPageState();
}

class _RelatorioCancelamentosPageState
    extends State<RelatorioCancelamentosPage> {
  // --- ESTADO DA PÁGINA ---
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _filtroTipo = 'todos';
  bool _isLoading = false;
  CancelamentoReport? _report;
  Map<String, String> _userNames = {};

  final Map<String, String> _filtroTipoOpcoes = {
    'todos': 'Todos os Cancelamentos',
    'missa': 'Apenas Missas',
    'agendamento': 'Apenas Agendamentos',
  };

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

  // --- LÓGICA DE NEGÓCIO ---

  Future<void> _gerarRelatorio() async {
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
      _userNames = {};
    });

    final startTimestamp = Timestamp.fromDate(
      DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0),
    );
    final endTimestamp = Timestamp.fromDate(
      DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59),
    );

    int totalCancelamentos = 0;
    int totalUltimaHora = 0;
    final Map<String, int> topMotivos = {};
    final Map<String, int> topUsuarios = {};
    final Set<String> uidsParaBuscar = {};

    try {
      Query query = FirebaseFirestore.instance
          .collection('logs_cancelamentos')
          .where('dataCancelamento', isGreaterThanOrEqualTo: startTimestamp)
          .where('dataCancelamento', isLessThanOrEqualTo: endTimestamp);

      if (_filtroTipo != 'todos') {
        query = query.where('tipo', isEqualTo: _filtroTipo);
      }

      final querySnapshot = await query.get();
      final listaCompleta = querySnapshot.docs;
      totalCancelamentos = listaCompleta.length;

      for (final doc in listaCompleta) {
        final data = doc.data() as Map<String, dynamic>;
        final justificativa = data['justificativa'] as String? ?? 'Sem Motivo';
        final uid = data['usuarioId'] as String;

        if (justificativa != "Cancelamento com antecedência.") {
          totalUltimaHora++;
        }
        topMotivos[justificativa] = (topMotivos[justificativa] ?? 0) + 1;
        topUsuarios[uid] = (topUsuarios[uid] ?? 0) + 1;
        uidsParaBuscar.add(uid);
      }

      if (uidsParaBuscar.isNotEmpty) {
        _userNames = await _fetchUserNames(uidsParaBuscar.toList());
      }

      setState(() {
        _report = CancelamentoReport(
          totalCancelamentos: totalCancelamentos,
          totalUltimaHora: totalUltimaHora,
          topMotivos: topMotivos,
          topUsuarios: topUsuarios,
          listaCompleta: listaCompleta,
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

  Future<Map<String, String>> _fetchUserNames(List<String> uids) async {
    final Map<String, String> names = {};
    // Firestore 'whereIn' limit of 10 (or 30 dependent on setup, safely sticking to logic)
    for (int i = 0; i < uids.length; i += 10) {
      final sublist = uids.sublist(
        i,
        i + 10 > uids.length ? uids.length : i + 10,
      );
      final userQuery =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .where(FieldPath.documentId, whereIn: sublist)
              .get();
      for (final userDoc in userQuery.docs) {
        names[userDoc.id] =
            (userDoc.data()['nome'] as String?) ?? 'Nome Desconhecido';
      }
    }
    return names;
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
      final generator = CancelamentosPdfGenerator(
        report: _report!,
        userNames: _userNames,
        startDate: _startDate,
        endDate: _endDate,
        filtroTipoLabel: _filtroTipoOpcoes[_filtroTipo]!,
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
      title: "Relatório de Cancelamentos",
      showBackButton: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Widget de Filtros Novo
            FiltrosRelatorioCancelamentoWidget(
              startDate: _startDate,
              endDate: _endDate,
              filtroTipo: _filtroTipo,
              filtroTipoOpcoes: _filtroTipoOpcoes,
              isLoading: _isLoading,
              // Passamos as funções com validação
              onTapStartDate: _selectStartDate,
              onTapEndDate: _selectEndDate,
              onFiltroChanged: (novoFiltro) {
                if (novoFiltro != null) {
                  setState(() => _filtroTipo = novoFiltro);
                }
              },
              onGerarRelatorio: _gerarRelatorio,
              onExportPDF: _exportarPDF,
              canExport: _report != null,
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

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
                              Icons.cancel_presentation,
                              size: 60,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Filtre e gere o relatório de cancelamentos.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                      : ListaResultadosCancelamentoWidget(
                        report: _report!,
                        userNames: _userNames,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
