import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/widgets/app/app_scaffold.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/models/aviso_model.dart';

class AvisoDetailPage extends StatelessWidget {
  final Aviso aviso;
  final bool isAdmin;

  const AvisoDetailPage({
    required this.aviso,
    this.isAdmin = false,
    super.key,
  });

  String _formatDateTime(DateTime d) {
    final dt = d.toLocal();
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} às ${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final expired =
        aviso.endsAt != null && aviso.endsAt!.isBefore(DateTime.now());
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return AppScaffold(
      title: 'Detalhes do Aviso',
      showBackButton: true,
      actions: [
        if (isAdmin)
          IconButton(
            tooltip: 'Editar Aviso',
            icon: const Icon(Icons.edit),
            // MUDANÇA: Navegação corrigida para usar GoRouter
            onPressed: () => context.push('/avisos/editar', extra: aviso),
          ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              aviso.title,
              style: textTheme.displaySmall, // MUDANÇA: Fonte maior para o título
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
            const SizedBox(height: 16),
            // MUDANÇA: Agrupando metadados em um Card para melhor organização
            Card(
              color: colorScheme.surface.withAlpha(240),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Publicado em: ${_formatDateTime(aviso.publishedAt)}',
                            style: textTheme.bodyMedium,
                          ),
                          if (aviso.endsAt != null) ...[
                            const SizedBox(height: 8),
                            Text(
                                'Válido até: ${_formatDateTime(aviso.endsAt!)}',
                                style: textTheme.bodyMedium),
                          ],
                          if (expired) ...[
                            const SizedBox(height: 12),
                            Chip(
                              label: const Text('Expirado'),
                              backgroundColor:
                              colorScheme.error.withOpacity(0.1),
                              labelStyle:
                              TextStyle(color: colorScheme.error),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),
            const Divider(height: 48),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  aviso.description,
                  style: textTheme.bodyLarge?.copyWith(height: 1.5), // Maior espaçamento entre linhas
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}