import 'dart:io';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/relatorio_ministro_model.dart';

class MinistrosPdfGenerator {
  final EngagementReportMinistros report;
  final DateTime startDate;
  final DateTime endDate;

  MinistrosPdfGenerator({
    required this.report,
    required this.startDate,
    required this.endDate,
  });

  Future<void> generateAndOpenFile() async {
    try {
      final pdf = pw.Document();

      // Ordenação dos dados (quem tem mais serviços aparece primeiro)
      final sortedUsers = report.userEngagement.entries.toList()
        ..sort((a, b) => b.value.totalServices.compareTo(a.value.totalServices));

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => _buildHeader(),

          // [CORREÇÃO PARA EVITAR O ERRO TooManyPagesException]
          // Usamos o operador "spread" (...) para injetar os widgets soltos na lista.
          // Isso permite que o PDF calcule onde cortar a página no meio da tabela.
          build: (context) => [

            // Lista de Ministros (Agora pode quebrar página se for grande)
            ..._buildTopMinistrosList(sortedUsers),

            pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 15),
                child: pw.Divider(thickness: 1.5)
            ),

            // Lista de Gargalos (Agora pode quebrar página se for grande)
            ..._buildGargaloList(
              report.cargoGargalos,
              report.cargoTotaisCriados,
            ),

            pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 15),
                child: pw.Divider(thickness: 1.5)
            ),

            // Seção do Heatmap (Tabela fixa, não precisa desembrulhar pois é pequena)
            pw.Text(
              "Perfil de Engajamento (Global)",
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            _buildHeatmapTable(report.totalHorarioDiaMap),
          ],
          footer: (context) => _buildFooter(context),
        ),
      );

      final path = (await getApplicationDocumentsDirectory()).path;
      final file = File('$path/relatorio_ministros.pdf');
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      print("Erro ao gerar PDF: $e");
      throw Exception("Erro ao gerar PDF: $e");
    }
  }

  // --- Widgets do PDF ---

  pw.Widget _buildHeader() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      margin: const pw.EdgeInsets.only(bottom: 15),
      padding: const pw.EdgeInsets.only(bottom: 5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey, width: 2),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "Relatório Estratégico de Ministros",
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            "Período: ${dateFormat.format(startDate)} até ${dateFormat.format(endDate)}",
          ),
        ],
      ),
    );
  }

  // [ALTERADO] Retorna List<pw.Widget> em vez de Column para permitir paginação
  List<pw.Widget> _buildTopMinistrosList(
      List<MapEntry<String, UserEngagementDetailsMinistros>> sortedUsers,
      ) {
    final headers = ['Rank', 'Nome do Ministro', 'Total de Serviços'];

    final data = sortedUsers.map((entry) {
      final details = entry.value;
      return [
        sortedUsers.indexOf(entry) + 1,
        details.userName,
        details.totalServices.toString(),
      ];
    }).toList();

    // Retorna uma lista contendo o Título, o Espaço e a Tabela soltos
    return [
      pw.Text(
        "Top Ministros",
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 10),
      if (data.isEmpty)
        pw.Text("Nenhum ministro serviu neste período.")
      else
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
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: const pw.EdgeInsets.all(6),
          // Repete o cabeçalho se a tabela quebrar para a próxima página
          headerCount: 1,
          columnWidths: {
            0: const pw.FixedColumnWidth(50),
            1: const pw.FlexColumnWidth(),
            2: const pw.FixedColumnWidth(80),
          },
        ),
    ];
  }

  // [ALTERADO] Retorna List<pw.Widget> em vez de Column
  List<pw.Widget> _buildGargaloList(
      Map<String, int> gargaloData,
      Map<String, int> totalData,
      ) {
    final headers = ['Cargo', 'Vagas Ociosas', 'Total Criado', 'Taxa Ociosidade'];

    final data = gargaloData.entries.map((entry) {
      final cargoKey = entry.key;
      final gargaloCount = entry.value;
      final totalCount = totalData[cargoKey] ?? gargaloCount;
      final taxa = (totalCount == 0) ? 0 : (gargaloCount / totalCount) * 100;
      return [
        "Vagas de Ministro",
        gargaloCount.toString(),
        totalCount.toString(),
        "${taxa.toStringAsFixed(0)}%",
      ];
    }).toList();

    return [
      pw.Text(
        "Vagas Ociosas (Gargalos)",
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 10),
      if (data.isEmpty)
        pw.Text("Nenhuma vaga ociosa encontrada. Parabéns!")
      else
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: data,
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.red700),
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: const pw.EdgeInsets.all(6),
          headerCount: 1,
          columnWidths: {
            0: const pw.FlexColumnWidth(),
            1: const pw.FixedColumnWidth(80),
            2: const pw.FixedColumnWidth(80),
            3: const pw.FixedColumnWidth(80),
          },
        ),
    ];
  }

  pw.Widget _buildHeatmapTable(Map<String, int> data) {
    const dias = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB', 'DOM'];
    const periodos = ['MANHÃ', 'TARDE', 'NOITE'];

    final headerRow = pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text("Período", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        ...dias.map((dia) => pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(dia, style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
        )),
      ],
    );

    final dataRows = periodos.map((periodo) {
      return pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(periodo, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          ),
          ...dias.map((dia) {
            final value = data['$dia-$periodo'] ?? 0;
            return pw.Container(
              color: value > 0 ? PdfColors.blue50 : PdfColors.white,
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Text(value.toString(), textAlign: pw.TextAlign.center),
            );
          }),
        ],
      );
    }).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
      children: [headerRow, ...dataRows],
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