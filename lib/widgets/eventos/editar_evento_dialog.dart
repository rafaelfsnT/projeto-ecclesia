// NOVO ARQUIVO: lib/widgets/eventos/editar_evento_dialog.dart
// Baseado em seu 'editar_evento_page.dart', mas adaptado para um AlertDialog
// e com o limite de 2 imagens.

// *** CORRIGIDO COM O SIZEDBOX PARA EVITAR O RENDERVIEWPORT ERROR ***

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/evento_model.dart';
import '../../viewmodels/evento_viewmodel.dart';

class EditarEventoDialog extends StatefulWidget {
  final Evento evento;
  const EditarEventoDialog({super.key, required this.evento});

  @override
  State<EditarEventoDialog> createState() => _EditarEventoDialogState();
}

class _EditarEventoDialogState extends State<EditarEventoDialog> {
  // Constante para o limite de imagens
  static const int _limiteMaximoImagens = 2;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _descricaoController;
  late TextEditingController _localController;
  late DateTime _dataHora;

  List<String> _imageUrlsExistentes = [];
  List<File> _novasImagensSelecionadas = [];

  // Lista para rastrear URLs que precisam ser deletadas do Storage
  List<String> _urlsParaDeletar = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.evento.titulo);
    _descricaoController = TextEditingController(text: widget.evento.descricao);
    _localController = TextEditingController(text: widget.evento.local);
    _dataHora = widget.evento.dataHora;
    _imageUrlsExistentes = widget.evento.imageUrls != null
        ? List.from(widget.evento.imageUrls!)
        : [];
  }

  // --- LÓGICA DO LIMITE DE IMAGEM ---
  int get _totalImagens =>
      _imageUrlsExistentes.length + _novasImagensSelecionadas.length;
  bool get _podeAdicionarMaisImagens => _totalImagens < _limiteMaximoImagens;
  int get _espacoDisponivel => _limiteMaximoImagens - _totalImagens;
  // --- FIM DA LÓGICA DO LIMITE ---

  Future<void> _selecionarNovasImagens() async {
    // 1. Verifica se pode adicionar mais
    if (!_podeAdicionarMaisImagens) {
      if (!mounted) return;
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
      // 2. Pega apenas a quantidade que cabe no limite
      final List<File> imagensParaAdicionar = pickedFiles
          .take(_espacoDisponivel) // Pega somente o que cabe
          .map((p) => File(p.path))
          .toList();

      setState(() {
        _novasImagensSelecionadas.addAll(imagensParaAdicionar);
      });

      // 3. Avisa se algumas imagens foram ignoradas
      if (pickedFiles.length > imagensParaAdicionar.length) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Limite de 2 imagens atingido. Algumas imagens não foram adicionadas.')),
        );
      }
    }
  }

  Future<void> _salvarEdicao() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final viewModel = Provider.of<EventoViewModel>(context, listen: false);

    try {
      // 1. Deletar imagens marcadas para exclusão
      for (final url in _urlsParaDeletar) {
        await viewModel.deletarImagemPorUrl(url);
      }

      // 2. Criar objeto Evento com os campos de texto
      final eventoAtualizado = Evento(
        id: widget.evento.id,
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        dataHora: _dataHora,
        local: _localController.text.trim(),
        imageUrls: _imageUrlsExistentes, // A lista de URLs que sobraram
      );

      // 3. Chamar o método que faz upload das novas e atualiza o doc
      await viewModel.atualizarEventoComNovasImagens(
        eventoAtualizado,
        _novasImagensSelecionadas,
        imagensExistentes: _imageUrlsExistentes,
      );

      if (!mounted) return;
      // Fecha o dialog com sucesso
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar evento: ${e.toString()}')),
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
    final textTheme = theme.textTheme;

    // Texto de ajuda para o limite de imagens
    final String helperText = _podeAdicionarMaisImagens
        ? 'Você pode adicionar mais $_espacoDisponivel imagem(ns).'
        : 'Limite de 2 imagens atingido.';

    return AlertDialog(
      title: const Text('Editar Evento'),
      // --- INÍCIO DA CORREÇÃO ---
      // Adicionamos um SizedBox com largura definida para
      // evitar o erro de cálculo de dimensão intrínseca (RenderViewport).
      content: SizedBox(
        width: double.maxFinite, // Preenche a largura do Dialog
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            // --- FIM DA CORREÇÃO ---
            child: Column(
              mainAxisSize: MainAxisSize.min, // Importante para o Column
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- UI DE IMAGEM ATUALIZADA COM LIMITE ---
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: (_imageUrlsExistentes.isEmpty &&
                      _novasImagensSelecionadas.isEmpty)
                      ? Center(
                    child: Text(
                      'Nenhuma imagem selecionada.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    scrollDirection: Axis.horizontal,
                    itemCount: _imageUrlsExistentes.length +
                        _novasImagensSelecionadas.length,
                    itemBuilder: (context, idx) {
                      // Imagens existentes (URLs)
                      if (idx < _imageUrlsExistentes.length) {
                        final url = _imageUrlsExistentes[idx];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _buildImagePreview(
                            theme,
                            imageWidget: Image.network(url,
                                fit: BoxFit.cover,
                                // Tratamento de erro de carregamento
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                const Center(
                                    child: Icon(
                                        Icons.broken_image,
                                        color: Colors.grey))),
                            onRemove: () {
                              setState(() {
                                final urlRemovida =
                                _imageUrlsExistentes.removeAt(idx);
                                _urlsParaDeletar.add(urlRemovida);
                              });
                            },
                          ),
                        );
                      }
                      // Novas imagens (Files)
                      else {
                        final newIndex =
                            idx - _imageUrlsExistentes.length;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _buildImagePreview(
                            theme,
                            imageWidget: Image.file(
                                _novasImagensSelecionadas[newIndex],
                                fit: BoxFit.cover),
                            onRemove: () {
                              setState(() => _novasImagensSelecionadas
                                  .removeAt(newIndex));
                            },
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Adicionar Mais Imagens'),
                  // Desabilita se o limite foi atingido
                  onPressed: _podeAdicionarMaisImagens && !_isSaving
                      ? _selecionarNovasImagens
                      : null,
                ),
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
                const SizedBox(height: 16),
                // --- Fim da UI de Imagem ---

                TextFormField(
                  controller: _tituloController,
                  decoration: const InputDecoration(
                      labelText: 'Título do Evento',
                      border: OutlineInputBorder()),
                  readOnly: _isSaving,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe um título.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descricaoController,
                  decoration: const InputDecoration(
                      labelText: 'Descrição',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder()),
                  maxLines: 4,
                  readOnly: _isSaving,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe uma descrição.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _localController,
                  decoration: const InputDecoration(
                      labelText: 'Local', border: OutlineInputBorder()),
                  readOnly: _isSaving,
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
                  onTap: _isSaving ? null : _selecionarDataHora,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _salvarEdicao,
          child: _isSaving
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 3, color: Colors.white),
          )
              : const Text('Salvar Alterações'),
        ),
      ],
    );
  }

  Future<void> _selecionarDataHora() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dataHora,
      firstDate: DateTime(2000), // Permitir datas passadas para edição
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && mounted) {
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
  }

  // Widget auxiliar de preview (igual ao que você já tinha)
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
              onTap: _isSaving ? null : onRemove, // Desabilita remoção ao salvar
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
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

