import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/models/aviso_model.dart';
import '/viewmodels/aviso_viewmodel.dart';

class EditarAvisoDialog extends StatefulWidget {
  final Aviso aviso;
  const EditarAvisoDialog({super.key, required this.aviso});

  @override
  State<EditarAvisoDialog> createState() => _EditarAvisoDialogState();
}

class _EditarAvisoDialogState extends State<EditarAvisoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late DateTime _publishedAt;
  late DateTime? _endsAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.aviso.title);
    _descCtrl = TextEditingController(text: widget.aviso.description);
    _publishedAt = widget.aviso.publishedAt;
    _endsAt = widget.aviso.endsAt;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate({required bool isPublished}) async {
    final now = DateTime.now();
    final initial = isPublished
        ? _publishedAt
        : (_endsAt ?? _publishedAt.add(const Duration(days: 1)));
    final first = isPublished ? now : _publishedAt;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (picked == null) return;

    setState(() {
      if (isPublished) _publishedAt = picked;
      else _endsAt = picked;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<AvisoViewModel>();
    setState(() => _saving = true);

    try {
      final aviso = Aviso(
        id: widget.aviso.id, // ID original
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        publishedAt: _publishedAt,
        endsAt: _endsAt,
        createdAt: widget.aviso.createdAt, // Data de criação original
        updatedAt: DateTime.now(), // Nova data de atualização
      );

      await vm.update(aviso);

      if (mounted) Navigator.pop(context, true); // Retorna 'true' para sucesso
    } catch (e) {
      if (mounted) {
        // Exibição de erro simplificada
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Editar Aviso"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Título'),
                readOnly: _saving,
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Informe um título' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                    labelText: 'Descrição', alignLabelWithHint: true),
                maxLines: 5,
                readOnly: _saving,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe uma descrição'
                    : null,
              ),
              const SizedBox(height: 24),
              // Data de Publicação
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300)),
                title: Text('Publicar em: ${_formatDate(_publishedAt)}'),
                trailing: const Icon(Icons.calendar_month),
                onTap: _saving ? null : () => _pickDate(isPublished: true),
              ),
              const SizedBox(height: 16),
              // Data de Término (Opcional)
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300)),
                title: Text(
                    'Termina em: ${_endsAt != null ? _formatDate(_endsAt!) : 'Sem data de término'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_endsAt != null)
                      IconButton(
                        tooltip: 'Remover data de término',
                        icon: const Icon(Icons.clear),
                        color: Theme.of(context).colorScheme.error,
                        onPressed: _saving
                            ? null
                            : () => setState(() => _endsAt = null),
                      ),
                    const Icon(Icons.calendar_month),
                  ],
                ),
                onTap: _saving ? null : () => _pickDate(isPublished: false),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text("Atualizar"),
        ),
      ],
    );
  }
}