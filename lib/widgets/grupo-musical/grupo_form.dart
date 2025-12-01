import 'package:flutter/material.dart';

class GrupoForm extends StatelessWidget {
  final TextEditingController nomeController;
  final TextEditingController liderController;
  final TextEditingController contatoController;
  final TextEditingController emailController;
  final TextEditingController observacoesController;
  final String statusSelecionado;
  final ValueChanged<String?> onStatusChanged;

  const GrupoForm({
    super.key,
    required this.nomeController,
    required this.liderController,
    required this.contatoController,
    required this.emailController,
    required this.observacoesController,
    required this.statusSelecionado,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Define as opções de status com cores (incluindo Pausa)
    const Map<String, Color> statusOptions = {
      'Ativo': Colors.green,
      'Inativo': Colors.red,
      'Pausa': Colors.orange, // <-- Adicionado Pausa
    };
    const Map<String, IconData> statusIcons = {
      'Ativo': Icons.check_circle_outline,
      'Inativo': Icons.highlight_off,
      'Pausa': Icons.pause_circle_outline, // <-- Ícone para Pausa
    };
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Informações Básicas",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do Grupo *',
                prefixIcon: Icon(Icons.group),
                border: OutlineInputBorder(),
              ),
              validator:
                  (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),
            const Text(
              "Responsável",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: liderController,
              decoration: const InputDecoration(
                labelText: 'Líder *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator:
                  (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: contatoController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Status *",
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: statusSelecionado,
              onChanged: onStatusChanged,
              child: Column(
                children:
                    statusOptions.entries.map((entry) {
                      final statusValue = entry.key;
                      final statusColor = entry.value;
                      final statusIcon =
                          statusIcons[statusValue] ?? Icons.help_outline;

                      return RadioListTile<String>(
                        value: statusValue,
                        title: Text(
                          statusValue,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        activeColor: statusColor,
                        secondary: Icon(
                          statusIcon,
                          color:
                              statusSelecionado == statusValue
                                  ? statusColor
                                  : statusColor.withOpacity(0.4),
                        ),
                        tileColor:
                            statusSelecionado == statusValue
                                ? statusColor.withValues(alpha: 0.1)
                                : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: observacoesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observações',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
