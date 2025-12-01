import '/models/evento_model.dart';
import '/widgets/app/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class EventoDetailPage extends StatefulWidget {
  final Evento evento;
  const EventoDetailPage({super.key, required this.evento});

  @override
  State<EventoDetailPage> createState() => _EventoDetailPageState();
}

class _EventoDetailPageState extends State<EventoDetailPage> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final hasImages = widget.evento.imageUrls != null && widget.evento.imageUrls!.isNotEmpty;
    final hasMultipleImages = hasImages && widget.evento.imageUrls!.length > 1;

    return AppScaffold(
      title: 'Detalhes do Evento',
      showBackButton: true,
      showBottomNavBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Seção de Imagem / Carrossel ---
            if (hasImages)
              SizedBox(
                height: 250,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: widget.evento.imageUrls!.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          widget.evento.imageUrls![index],
                          fit: BoxFit.cover,
                          // Placeholder de carregamento
                          loadingBuilder: (context, child, progress) {
                            return progress == null
                                ? child
                                : const Center(child: CircularProgressIndicator());
                          },
                          // Placeholder de erro
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image,
                                  color: Colors.grey, size: 48),
                            );
                          },
                        );
                      },
                    ).animate().fadeIn(duration: 300.ms),

                    // Indicador de "bolinhas" (só aparece se tiver > 1 imagem)
                    if (hasMultipleImages)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SmoothPageIndicator(
                          controller: _pageController,
                          count: widget.evento.imageUrls!.length,
                          effect: WormEffect(
                            dotHeight: 10,
                            dotWidth: 10,
                            activeDotColor: theme.colorScheme.onPrimary,
                            dotColor: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                  ],
                ),
              ),

            // --- Seção de Conteúdo ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    widget.evento.titulo,
                    style: textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                  const SizedBox(height: 16),

                  // Card de Metadados (Data e Local)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            theme,
                            icon: Icons.calendar_month,
                            text: DateFormat('dd/MM/yyyy \'às\' HH:mm')
                                .format(widget.evento.dataHora.toLocal()),
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            theme,
                            icon: Icons.location_on,
                            text: widget.evento.local,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                  const Divider(height: 48),

                  // Descrição
                  Text(
                    'Sobre o evento:',
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 12),
                  Text(
                    widget.evento.descricao,
                    style: textTheme.bodyLarge?.copyWith(height: 1.5),
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para os ícones
  Widget _buildInfoRow(ThemeData theme, {required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: theme.textTheme.bodyLarge),
        ),
      ],
    );
  }
}