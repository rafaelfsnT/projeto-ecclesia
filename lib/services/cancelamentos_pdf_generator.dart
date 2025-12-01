import 'dart:io';

import '/models/relatorio_cancelamento_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

class CancelamentosPdfGenerator {
  final CancelamentoReport report;
  final Map<String, String> userNames;
  final DateTime startDate;
  final DateTime endDate;
  final String filtroTipoLabel;

  CancelamentosPdfGenerator({
    required this.report,
    required this.userNames,
    required this.startDate,
    required this.endDate,
    required this.filtroTipoLabel,
  });

  Future<void> generateAndOpenFile() async {
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

      // [CORREÇÃO 1] Carrega uma fonte que suporta acentos (UTF-8)
      final font = await PdfGoogleFonts.openSansRegular();
      final fontBold = await PdfGoogleFonts.openSansBold();

      // Define um tema padrão para usar essa fonte em tudo
      final theme = pw.ThemeData.withFont(base: font, bold: fontBold);

      // Ordenação
      final sortedMotivos =
          report.topMotivos.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
      final sortedUsuarios =
          report.topUsuarios.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            theme: theme, // Aplica a fonte
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
          ),
          header: (context) => _buildHeader(),
          footer: (context) => _buildFooter(context),

          // [CORREÇÃO 2] Lista plana de widgets
          build:
              (context) => [
                // 1. KPIs
                _buildKpiRow(context),
                pw.Divider(height: 30, thickness: 1.5),

                // 2. Tabelas de Topo
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.SizedBox(
                      width: 230,
                      child: _buildTopMotivosTable(sortedMotivos),
                    ),
                    pw.SizedBox(
                      width: 230,
                      child: _buildTopUsuariosTable(sortedUsuarios),
                    ),
                  ],
                ),
                pw.Divider(height: 30, thickness: 1.5),

                // 3. Título da Lista (Separado da tabela)
                pw.Text(
                  "Todos os Registros",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),

                // 4. A Tabela (Direto na lista, sem Column em volta)
                // Isso permite que ela quebre páginas automaticamente
                _buildDetailedTable(dateFormat),
              ],
        ),
      );

      final path = (await getApplicationDocumentsDirectory()).path;
      final file = File('$path/relatorio_cancelamentos.pdf');
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
            "Relatório Estratégico de Cancelamentos",
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            "Período: ${dateFormat.format(startDate)} até ${dateFormat.format(endDate)}",
          ),
          pw.Text("Filtro: $filtroTipoLabel"),
        ],
      ),
    );
  }

  pw.Widget _buildKpiRow(pw.Context context) {
    final taxaUltimaHora =
        (report.totalCancelamentos == 0)
            ? 0
            : (report.totalUltimaHora / report.totalCancelamentos) * 100;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _kpiCard("Total Geral", report.totalCancelamentos.toString()),
        _kpiCard(
          "Última Hora",
          report.totalUltimaHora.toString(),
          color: PdfColors.orange,
        ),
        _kpiCard(
          "Taxa Crítica",
          "${taxaUltimaHora.toStringAsFixed(0)}%",
          color: PdfColors.red,
        ),
      ],
    );
  }

  pw.Widget _kpiCard(
    String title,
    String value, {
    PdfColor color = PdfColors.blue,
  }) {
    return pw.Container(
      width: 150, // Largura fixa para alinhar
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border(left: pw.BorderSide(color: color, width: 4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTopMotivosTable(List<MapEntry<String, int>> sortedMotivos) {
    final headers = ['Motivo', 'Qtd.'];
    final data =
        sortedMotivos.take(5).map((e) => [e.key, e.value.toString()]).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "Principais Motivos",
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: data,
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            fontSize: 10,
          ),
          headerDecoration: const pw.BoxDecoration(
            color: PdfColors.blueGrey600,
          ),
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellPadding: const pw.EdgeInsets.all(4),
          columnWidths: {
            0: const pw.FlexColumnWidth(),
            1: const pw.FixedColumnWidth(30),
          },
        ),
      ],
    );
  }

  pw.Widget _buildTopUsuariosTable(List<MapEntry<String, int>> sortedUsuarios) {
    final headers = ['Usuário', 'Qtd.'];
    final data =
        sortedUsuarios
            .take(5)
            .map(
              (e) => [userNames[e.key] ?? 'Desconhecido', e.value.toString()],
            )
            .toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "Top Usuários",
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: data,
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            fontSize: 10,
          ),
          headerDecoration: const pw.BoxDecoration(
            color: PdfColors.blueGrey600,
          ),
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellPadding: const pw.EdgeInsets.all(4),
          columnWidths: {
            0: const pw.FlexColumnWidth(),
            1: const pw.FixedColumnWidth(30),
          },
        ),
      ],
    );
  }

  // [CORREÇÃO 3] Retorna apenas a Tabela (não mais envolvida em Column)
  pw.Widget _buildDetailedTable(DateFormat dateFormat) {
    final headers = ['Data', 'Usuário', 'Tipo', 'Justificativa'];

    final data =
        report.listaCompleta.map((doc) {
          final log = doc.data() as Map<String, dynamic>;
          final dataLog = (log['dataCancelamento'] as Timestamp).toDate();
          final uid = log['usuarioId'];
          final nome = userNames[uid] ?? 'ID: $uid';

          // Formata tipo
          String tipo = log['tipo'] ?? 'Outro';
          if (tipo == 'missa') tipo = 'Missa';
          if (tipo == 'agendamento') tipo = 'Agenda';

          return [
            dateFormat.format(dataLog),
            nome,
            tipo,
            log['justificativa'] ?? '',
          ];
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
      // Garante que o header se repita em novas páginas
      headerCount: 1,
      columnWidths: {
        0: const pw.FixedColumnWidth(80), // Data
        1: const pw.FlexColumnWidth(1.5), // Usuário
        2: const pw.FixedColumnWidth(50), // Tipo
        3: const pw.FlexColumnWidth(2.5), // Justificativa
      },
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        "Página ${context.pageNumber} de ${context.pagesCount} | Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}",
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    );
  }
}
