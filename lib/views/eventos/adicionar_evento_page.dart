import 'dart:io';
import '/models/evento_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '/viewmodels/evento_viewmodel.dart';
import '/widgets/app/app_scaffold.dart';

class AdicionarEventoPage extends StatefulWidget {
  const AdicionarEventoPage({super.key});

  @override
  State<AdicionarEventoPage> createState() => _AdicionarEventoPageState();
}

class _AdicionarEventoPageState extends State<AdicionarEventoPage> {
  // --- INÍCIO DAS MUDANÇAS ---
  static const int _limiteMaximoImagens = 2;

  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _localController = TextEditingController();
  DateTime _dataHora = DateTime.now();

  List<File> _imagensSelecionadas = [];
  bool _isSaving = false;

  // --- LÓGICA DO LIMITE DE IMAGEM ---
  int get _totalImagens => _imagensSelecionadas.length;
  bool get _podeAdicionarMaisImagens => _totalImagens < _limiteMaximoImagens;
  int get _espacoDisponivel => _limiteMaximoImagens - _totalImagens;
  // --- FIM DA LÓGICA DO LIMITE ---

  Future<void> _selecionarImagens() async {
    // 1. Verifica se pode adicionar mais
    if (!_podeAdicionarMaisImagens) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Você já atingiu o limite de 2 imagens.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 70);

    if (pickedFiles.isNotEmpty && mounted) {
      final List<File> imagensParaAdicionar = pickedFiles
          .take(_espacoDisponivel)
          .map((p) => File(p.path))
          .toList();

      setState(() {
        _imagensSelecionadas.addAll(imagensParaAdicionar);
      });

      // 3. Avisa se algumas imagens foram ignoradas
      if (pickedFiles.length > imagensParaAdicionar.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Limite de 2 imagens atingido. Algumas imagens não foram adicionadas.')),
        );
      }
    }
  }


  Future<void> _salvarEvento() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final viewModel = Provider.of<EventoViewModel>(context, listen: false);

    try {
      final novoEvento = Evento(
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        dataHora: _dataHora,
        local: _localController.text.trim(),
        imageUrls: null,
      );

      await viewModel.criarEventoComImagens(novoEvento, _imagensSelecionadas);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento criado com sucesso')),
      );
      GoRouter.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar evento: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _localController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd/MM/yyyy HH:mm').format(_dataHora.toLocal());
    final theme = Theme.of(context);
    // --- MUDANÇA ---
    final textTheme = theme.textTheme;

    // Texto de ajuda para o limite de imagens
    final String helperText = _podeAdicionarMaisImagens
        ? 'Você pode adicionar até $_limiteMaximoImagens imagens (resta $_espacoDisponivel).'
        : 'Limite de 2 imagens atingido.';
    // --- FIM DA MUDANÇA ---

    return AppScaffold(
      title: 'Adicionar Novo Evento',
      showBackButton: true,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- UI DE IMAGEM ATUALIZADA ---
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _imagensSelecionadas.isEmpty
                  ? Center(
                child: Text(
                  'Nenhuma imagem selecionada.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                scrollDirection: Axis.horizontal,
                itemCount: _imagensSelecionadas.length,
                itemBuilder: (context, idx) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _buildImagePreview(
                      theme,
                      imageWidget: Image.file(_imagensSelecionadas[idx],
                          fit: BoxFit.cover),
                      onRemove: () {
                        setState(
                                () => _imagensSelecionadas.removeAt(idx));
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Adicionar Imagens'),
              // --- MUDANÇA ---
              // Desabilita se o limite foi atingido
              onPressed: _podeAdicionarMaisImagens && !_isSaving
                  ? _selecionarImagens
                  : null,
              // --- FIM DA MUDANÇA ---
            ),
            // --- NOVO WIDGET DE TEXTO DE AJUDA ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                helperText,
                style: textTheme.bodySmall?.copyWith(
                  color: _podeAdicionarMaisImagens
                      ? Colors.grey.shade600
                      : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // --- FIM DA MUDANÇA ---
            const SizedBox(height: 16),
            // --- Fim da UI de Imagem ---

            TextFormField(
              controller: _tituloController,
              decoration: const InputDecoration(labelText: 'Título do Evento'),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Informe um título.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descricaoController,
              decoration: const InputDecoration(
                  labelText: 'Descrição', alignLabelWithHint: true),
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Informe uma descrição.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _localController,
              decoration: const InputDecoration(labelText: 'Local'),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Informe o local.' : null,
            ),
            const SizedBox(height: 24),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              title: Text('Data e Hora: $dateLabel'),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _dataHora,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_dataHora),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _dataHora = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                    });
                  }
                }
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _salvarEvento,
              child: _isSaving
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 3, color: Colors.white),
              )
                  : const Text('Salvar Evento'),
            ),
          ].animate(interval: 60.ms)
              .fadeIn(duration: 300.ms, delay: 100.ms)
              .slideY(begin: 0.2, curve: Curves.easeOut),
        ),
      ),
    );
  }

  // Widget auxiliar de preview
  Widget _buildImagePreview(ThemeData theme,
      {required Widget imageWidget, required VoidCallback onRemove}) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageWidget,
          ),
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
