import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FiltrosRelatorioAgendamentoWidget extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final bool isLoading;
  final VoidCallback onTapStartDate;
  final VoidCallback onTapEndDate;
  final VoidCallback onGerarRelatorio;
  final VoidCallback onExportPDF;
  final bool canExport;

  const FiltrosRelatorioAgendamentoWidget({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.isLoading,
    required this.onTapStartDate,
    required this.onTapEndDate,
    required this.onGerarRelatorio,
    required this.onExportPDF,
    required this.canExport,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título da Seção
            Row(
              children: [
                Icon(Icons.filter_alt_outlined, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  "Filtros do Período",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Seletores de Data (Lado a Lado)
            Row(
              children: [
                Expanded(
                  child: _buildDateSelector(
                    context,
                    label: "Data Inicial",
                    date: startDate,
                    onTap: onTapStartDate,
                    icon: Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateSelector(
                    context,
                    label: "Data Final",
                    date: endDate,
                    onTap: onTapEndDate,
                    icon: Icons.event,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Botões de Ação
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : onGerarRelatorio,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.search),
                    label: Text(isLoading ? "Gerando..." : "Gerar Relatório"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    onPressed: (isLoading || !canExport) ? null : onExportPDF,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                          color: canExport ? Colors.red.shade700 : Colors.grey.shade300
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Icon(Icons.picture_as_pdf, color: canExport ? Colors.red.shade700 : Colors.grey),
                    label: Text(
                      "PDF",
                      style: TextStyle(color: canExport ? Colors.red.shade700 : Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(
      BuildContext context, {
        required String label,
        required DateTime date,
        required VoidCallback onTap,
        required IconData icon,
      }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, size: 18, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy').format(date),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}