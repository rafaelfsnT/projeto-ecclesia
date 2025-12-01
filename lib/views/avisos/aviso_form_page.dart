import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/models/aviso_model.dart';
import '/viewmodels/aviso_viewmodel.dart';
import '/widgets/app/app_scaffold.dart';

class AvisoFormPage extends StatefulWidget {
  const AvisoFormPage({super.key});

  @override
  State<AvisoFormPage> createState() => _AvisoFormPageState();
}

class _AvisoFormPageState extends State<AvisoFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  DateTime _publishedAt = DateTime.now();
  DateTime? _endsAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _titleCtrl = TextEditingController(text: '');
    _descCtrl = TextEditingController(text: '');
    _publishedAt = DateTime.now();
    _endsAt = null;
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
    final initial = isPublished ? _publishedAt : (_endsAt ?? _publishedAt.add(const Duration(days: 1)));
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
        id: '',
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        publishedAt: _publishedAt,
        endsAt: _endsAt,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await vm.create(aviso);

      if (mounted) {

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aviso criado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao criar aviso: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      // Título fixo de "Novo Aviso"
      title: 'Novo Aviso',
      showBackButton: true,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe um título' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descrição', alignLabelWithHint: true),
              maxLines: 5,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe uma descrição' : null,
            ),
            const SizedBox(height: 24),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
              title: Text('Publicar em: ${_formatDate(_publishedAt)}'),
              trailing: const Icon(Icons.calendar_month),
              onTap: _saving ? null : () => _pickDate(isPublished: true),
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
              title: Text('Termina em: ${_endsAt != null ? _formatDate(_endsAt!) : 'Sem data de término'}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_endsAt != null)
                    IconButton(
                      tooltip: 'Remover data de término',
                      icon: const Icon(Icons.clear),
                      color: Theme.of(context).colorScheme.error,
                      onPressed: _saving ? null : () => setState(() => _endsAt = null),
                    ),
                  const Icon(Icons.calendar_month),
                ],
              ),
              onTap: _saving ? null : () => _pickDate(isPublished: false),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                  : const Text('Criar Aviso'), // Texto fixo
            ),
          ]
              .animate(interval: 60.ms)
              .fadeIn(duration: 300.ms, delay: 100.ms)
              .slideY(begin: 0.2, curve: Curves.easeOut),
        ),
      ),
    );
  }
}