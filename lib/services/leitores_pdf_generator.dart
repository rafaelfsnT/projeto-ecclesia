import 'dart:io';
import '/models/relatorio_leitores_model.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class LeitoresPdfGenerator {
  final EngagementReport report;
  final DateTime startDate;
  final DateTime endDate;
  final String filtroCargoLabel;
  final Function(String) formatarCargoCallback;

  LeitoresPdfGenerator({
    required this.report,
    required this.startDate,
    required this.endDate,
    required this.filtroCargoLabel,
    required this.formatarCargoCallback,
  });

  Future<void> generateAndOpenFile() async {
    try {
      final pdf = pw.Document();

      final sortedUsers = report.userEngagement.entries.toList()
        ..sort((a, b) => b.value.totalServices.compareTo(a.value.totalServices));

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => _buildHeader(),
          // O TRUQUE ESTÁ AQUI: Usamos o spread operator (...) para "espalhar"
          // os widgets dentro da lista principal do MultiPage.
          build: (context) => [
            ..._buildTopLeitoresList(sortedUsers), // Mudado de Table para List

            pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 15),
                child: pw.Divider(thickness: 1.5)
            ),

            ..._buildGargaloList( // Mudado de Table para List
              report.cargoGargalos,
              report.cargoTotaisCriados,
            ),

            pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 15),
                child: pw.Divider(thickness: 1.5)
            ),

            _buildDataTables(context),
          ],
          footer: (context) => _buildFooter(context),
        ),
      );

      final path = (await getApplicationDocumentsDirectory()).path;
      final file = File('$path/relatorio_leitores.pdf');
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
            "Relatório Estratégico de Leitores",
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            "Período: ${dateFormat.format(startDate)} até ${dateFormat.format(endDate)}",
          ),
          pw.Text("Filtro: $filtroCargoLabel"),
        ],
      ),
    );
  }

  // [CORREÇÃO] Retorna List<pw.Widget> em vez de pw.Widget (Column)
  List<pw.Widget> _buildTopLeitoresList(
      List<MapEntry<String, UserEngagementDetails>> sortedUsers,
      ) {
    final headers = ['Rank', 'Nome do Voluntário', 'Total de Serviços'];

    final data = sortedUsers.map((entry) {
      final details = entry.value;
      return [
        sortedUsers.indexOf(entry) + 1,
        details.userName,
        details.totalServices.toString(),
      ];
    }).toList();

    return [
      pw.Text(
        "Top Leitores",
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 10),
      if (data.isEmpty)
        pw.Text("Nenhum leitor serviu neste período.")
      else
      // O TableHelper agora está solto na lista do MultiPage, permitindo quebra de página
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
          columnWidths: {
            0: const pw.FixedColumnWidth(50),
            1: const pw.FlexColumnWidth(),
            2: const pw.FixedColumnWidth(80),
          },
        ),
    ];
  }

  // [CORREÇÃO] Retorna List<pw.Widget> em vez de pw.Widget (Column)
  List<pw.Widget> _buildGargaloList(
      Map<String, int> gargaloData,
      Map<String, int> totalData,
      ) {
    final headers = ['Cargo', 'Vagas Ociosas', 'Total Criado', 'Taxa Ociosidade'];

    final sortedGargalos = gargaloData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final data = sortedGargalos.map((entry) {
      final cargoKey = entry.key;
      final gargaloCount = entry.value;
      final totalCount = totalData[cargoKey] ?? gargaloCount;
      final taxa = (totalCount == 0) ? 0 : (gargaloCount / totalCount) * 100;

      return [
        formatarCargoCallback(cargoKey),
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
          columnWidths: {
            0: const pw.FlexColumnWidth(),
            1: const pw.FixedColumnWidth(80),
            2: const pw.FixedColumnWidth(80),
            3: const pw.FixedColumnWidth(80),
          },
        ),
    ];
  }

  // [NOTA] Tabelas lado a lado (Row) NÃO quebram página.
  // Se essas tabelas ficarem muito compridas, você terá o erro de novo.
  // Como são resumos (dias da semana e horários), geralmente são curtos, então deixei assim.
  pw.Widget _buildDataTables(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Engajamento por Período", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _buildHorarioTable(report.horarioEngagement),
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Engajamento por Dia", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _buildWeekdayTable(report.totalWeekdayEngagement),
            ],
          ),
        ),
      ],
    );
  }

  // ... _buildHorarioTable, _buildWeekdayTable e _buildFooter continuam iguais ...
  pw.Table _buildHorarioTable(Map<String, int> horarioData) {
    final data =
    horarioData.entries
        .where((e) => e.value > 0)
        .map((e) => [e.key, e.value.toString()])
        .toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Período', 'Serviços'],
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
        .where((e) => e.value > 0) // Mostra só dias com serviço
        .map((e) => [dias[e.key], e.value.toString()])
        .toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Dia da Semana', 'Serviços'],
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