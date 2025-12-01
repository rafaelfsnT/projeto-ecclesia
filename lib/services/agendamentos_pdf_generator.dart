import 'dart:io';

import '/models/relatorio_agendamento_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

class AgendamentosPdfGenerator {
  final AgendamentoReport report;
  final Map<String, String> userNames; // Mapa de UID -> Nome
  final DateTime startDate;
  final DateTime endDate;

  AgendamentosPdfGenerator({
    required this.report,
    required this.userNames,
    required this.startDate,
    required this.endDate,
  });

  Future<void> generateAndOpenFile() async {
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

      final font = await PdfGoogleFonts.openSansRegular();
      final fontBold = await PdfGoogleFonts.openSansBold();
      final theme = pw.ThemeData.withFont(base: font, bold: fontBold);

      // Constrói listas ordenadas para as tabelas
      final sortedAssuntos =
          report.topAssuntos.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      final sortedHorarios =
          report.topHorariosEspecificos.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            theme: theme,
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
          ),
          header: (context) => _buildHeader(),
          footer: (context) => _buildFooter(context),

          // [CORREÇÃO DE PAGINAÇÃO]
          // Os itens aqui são "filhos diretos" e podem quebrar página
          build:
              (context) => [
                // Seção 1: KPIs
                _buildKpiCard(context),
                pw.Divider(height: 30, thickness: 1.5),

                // Seção 2: Tabelas de Gráficos (Assuntos e Períodos)
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.SizedBox(
                      width: 230,
                      child: _buildTopAssuntosTable(sortedAssuntos),
                    ),
                    pw.SizedBox(
                      width: 230,
                      child: pw.Column(
                        children: [
                          _buildHorarioTable(report.horarioEngagement),
                          pw.SizedBox(height: 20),
                          _buildWeekdayTable(report.weekdayEngagement),
                        ],
                      ),
                    ),
                  ],
                ),

                // Seção 3: Top Horários (Nova tabela solicitada)
                pw.SizedBox(height: 20),
                pw.Text(
                  "Top Horários de Atendimento",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildTopHorariosTable(sortedHorarios),

                pw.Divider(height: 30, thickness: 1.5),

                // Seção 4: Lista Detalhada
                // [IMPORTANTE] O Título e a Tabela estão separados agora.
                // A Tabela não está mais dentro de uma Column, então ela pode
                // crescer infinitamente e criar novas páginas no PDF.
                pw.Text(
                  "Todos os Agendamentos",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildDetailedTable(dateFormat),
              ],
        ),
      );

      final path = (await getApplicationDocumentsDirectory()).path;
      final file = File('$path/relatorio_agendamentos.pdf');
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      print("Erro ao gerar PDF: $e");
      throw Exception("Erro ao gerar PDF: $e");
    }
  }

  pw.Widget _buildHeader() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey, width: 2),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "Relatório Estratégico de Agendamentos",
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            "Período: ${dateFormat.format(startDate)} até ${dateFormat.format(endDate)}",
          ),
        ],
      ),
    );
  }

  pw.Widget _buildKpiCard(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(
        color: PdfColors.blueGrey50,
        border: pw.Border(
          left: pw.BorderSide(color: PdfColors.blueGrey700, width: 4),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            "Total de Agendamentos no Período",
            style: pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            report.totalAgendamentos.toString(),
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTopAssuntosTable(List<MapEntry<String, int>> sortedAssuntos) {
    final headers = ['Assunto', 'Qtd.'];
    final data =
        sortedAssuntos
            .take(5) // Limita ao Top 5
            .map((e) => [e.key, e.value.toString()])
            .toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "Assuntos Mais Procurados",
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: data,
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(
            color: PdfColors.blueGrey700,
          ),
          cellPadding: const pw.EdgeInsets.all(6),
          columnWidths: {
            0: const pw.FlexColumnWidth(),
            1: const pw.FixedColumnWidth(40),
          },
        ),
      ],
    );
  }

  pw.Widget _buildTopHorariosTable(List<MapEntry<String, int>> sortedHorarios) {
    final headers = ['Horário', 'Qtd.'];
    final data =
        sortedHorarios.take(8).map((e) => [e.key, e.value.toString()]).toList();

    // Dica: Usa largura mínima para não ocupar a página toda horizontalmente
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      cellPadding: const pw.EdgeInsets.all(5),
      columnWidths: {
        0: const pw.FixedColumnWidth(80),
        1: const pw.FixedColumnWidth(50),
      },
      tableWidth: pw.TableWidth.min,
      cellAlignment: pw.Alignment.center,
    );
  }

  pw.Table _buildHorarioTable(Map<String, int> horarioData) {
    final data =
        horarioData.entries
            .where((e) => e.value > 0)
            .map((e) => [e.key, e.value.toString()])
            .toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Período', 'Qtd.'],
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey600),
      cellPadding: const pw.EdgeInsets.all(4),
      cellStyle: const pw.TextStyle(fontSize: 10),
    );
  }

  pw.Table _buildWeekdayTable(Map<int, int> weekdayData) {
    const dias = {
      1: 'Segunda',
      2: 'Terça',
      3: 'Quarta',
      4: 'Quinta',
      5: 'Sexta',
      6: 'Sábado',
      7: 'Domingo',
    };
    final data =
        weekdayData.entries
            .where((e) => e.value > 0)
            .map((e) => [dias[e.key], e.value.toString()])
            .toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Dia da Semana', 'Qtd.'],
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      cellPadding: const pw.EdgeInsets.all(6),
    );
  }

  pw.Widget _buildDetailedTable(DateFormat dateFormat) {
    final headers = ['Data', 'Usuário', 'Assunto'];

    final data =
        report.listaCompleta.map((doc) {
          final log = doc.data() as Map<String, dynamic>;
          final data = (log['slotInicio'] as Timestamp).toDate();
          final uid = log['usuarioId'];
          final nome = userNames[uid] ?? uid;

          return [dateFormat.format(data), nome, log['assunto'] ?? ''];
        }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerCount: 1,
      // Repete o cabeçalho em novas páginas
      columnWidths: {
        0: const pw.FixedColumnWidth(90),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(2),
      },
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        "Página ${context.pageNumber} de ${context.pagesCount} | Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}",
        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey),
      ),
    );
  }
}
