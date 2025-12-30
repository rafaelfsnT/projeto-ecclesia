import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MissasPdfGeneratorService {
  Future<void> gerarRelatorioMensal(
    List<QueryDocumentSnapshot> missas,
    String mesAno,
    Map<String, String> mapaNomes,
  ) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    // Organiza as missas por data
    missas.sort((a, b) {
      final dA = (a['dataHora'] as Timestamp).toDate();
      final dB = (b['dataHora'] as Timestamp).toDate();
      return dA.compareTo(dB);
    });

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape, // Paisagem cabe melhor a tabela
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            _buildHeader(mesAno, fontBold),
            pw.SizedBox(height: 20),
            _buildTable(missas, font, fontBold, mapaNomes),
          ];
        },
      ),
    );

    // Abre o preview do PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Escala_$mesAno.pdf',
    );
  }

  pw.Widget _buildHeader(String titulo, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ESCALA | MATRIZ',
          style: pw.TextStyle(font: fontBold, fontSize: 14),
        ),
        pw.Text(
          'PARÓQUIA NOSSA SENHORA DO CARMO',
          style: pw.TextStyle(font: fontBold, fontSize: 12),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          titulo.toUpperCase(),
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 24,
            color: PdfColors.red900,
          ),
        ),
        pw.Divider(color: PdfColors.grey),
      ],
    );
  }

  pw.Widget _buildTable(
    List<QueryDocumentSnapshot> missas,
    pw.Font font,
    pw.Font fontBold,
    Map<String, String> mapaNomes,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(40), // Dia
        1: const pw.FixedColumnWidth(40), // Sem
        2: const pw.FixedColumnWidth(40), // Hora
        3: const pw.FlexColumnWidth(2), // Celebração/Descrição
        4: const pw.FlexColumnWidth(1), // Equipe
        5: const pw.FlexColumnWidth(2), // Funções (Anim, Leitor...)
      },
      children:
          missas.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final dataHora = (data['dataHora'] as Timestamp).toDate();
            final escala = data['escala'] as Map<String, dynamic>? ?? {};

            // Formatações
            final dia = DateFormat('dd').format(dataHora);
            final sem = DateFormat(
              'EEE',
              'pt_BR',
            ).format(dataHora).toUpperCase().substring(0, 3);
            final hora = DateFormat('HH:mm').format(dataHora);
            final titulo = data['titulo'] ?? 'Missa Comum';
            final equipe =
                data['celebrante'] ?? ''; // Ou outro campo de equipe se tiver

            // Busca nomes das pessoas (Aqui assumimos que no Map escala tem o NOME ou o ID)
            // OBS: Se no banco você salva só o ID do usuário, precisaria buscar os nomes antes de gerar o PDF.
            // Para simplificar, vou assumir que você vai ajustar para passar os nomes ou que vamos imprimir o ID por enquanto.
            // O ideal é no "ListaMissasPage" fazer um "join" ou salvar o nome junto na escala.

            return pw.TableRow(
              verticalAlignment: pw.TableCellVerticalAlignment.middle,
              children: [
                _cell(dia, fontBold, align: pw.TextAlign.center),
                _cell(sem, font, align: pw.TextAlign.center),
                _cell(hora, font, align: pw.TextAlign.center),
                _cell(titulo, fontBold),
                _cell(equipe, font, align: pw.TextAlign.center),
                _buildEscalaCell(escala, font, fontBold, mapaNomes),
              ],
            );
          }).toList(),
    );
  }

  pw.Widget _cell(
    String text,
    pw.Font font, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 10),
        textAlign: align,
      ),
    );
  }

  pw.Widget _buildEscalaCell(
    Map<String, dynamic> escala,
    pw.Font font,
    pw.Font fontBold,
    Map<String, String> mapaNomes,
  ) {
    // Helper para formatar linha: "ANIM: Fulano"
    pw.Widget item(String label, String key) {
      final uid = escala[key]?.toString();
      if (uid == null || uid.isEmpty) return pw.SizedBox.shrink();

      // [AQUI A MÁGICA] Troca UID pelo Nome ou usa "---"
      final nome = mapaNomes[uid] ?? '---';

      return pw.Row(
        children: [
          pw.SizedBox(
            width: 35,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(font: fontBold, fontSize: 8),
            ),
          ),
          pw.Expanded(
            child: pw.Text(nome, style: pw.TextStyle(font: font, fontSize: 8)),
          ),
        ],
      );
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          item('ANIM', 'comentarista'), // Usando a chave que você usa no banco
          item('1ª LEIT', 'primeiraLeitura'),
          item('2ª LEIT', 'segundaLeitura'),
          item('SALMO', 'salmo'),
          item('PRECES', 'preces'),
        ],
      ),
    );
  }
}
