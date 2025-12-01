// lib/widgets/grupo-musical/editar_grupo_dialog.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'grupo_form.dart'; // Import your existing form widget

class EditarGrupoMusicalDialog extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> grupo;

  const EditarGrupoMusicalDialog({
    super.key,
    required this.docId,
    required this.grupo,
  });

  @override
  State<EditarGrupoMusicalDialog> createState() => _EditarGrupoMusicalDialogState();
}

class _EditarGrupoMusicalDialogState extends State<EditarGrupoMusicalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _liderController;
  late TextEditingController _contatoController;
  late TextEditingController _emailController;
  late TextEditingController _observacoesController;
  late String _statusSelecionado;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _nomeController = TextEditingController(text: widget.grupo['nome'] ?? '');
    _liderController = TextEditingController(text: widget.grupo['lider'] ?? '');
    _contatoController = TextEditingController(text: widget.grupo['contato'] ?? '');
    _emailController = TextEditingController(text: widget.grupo['email'] ?? '');
    _observacoesController = TextEditingController(text: widget.grupo['observacoes'] ?? '');
    _statusSelecionado = widget.grupo['status'] ?? 'Ativo';
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _liderController.dispose();
    _contatoController.dispose();
    _emailController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _atualizarGrupo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final grupoData = {
        'nome': _nomeController.text.trim(),
        'lider': _liderController.text.trim(),
        'contato': _contatoController.text.trim(),
        'email': _emailController.text.trim(),
        'status': _statusSelecionado,
        'observacoes': _observacoesController.text.trim(),
        'dataAtualizacao': DateTime.now(), // Update timestamp
      };

      // Update the existing group document
      await FirebaseFirestore.instance
          .collection('grupos_musicais')
          .doc(widget.docId)
          .update(grupoData);

      if (mounted) {
        // Close the dialog and return 'true' to indicate success
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        // Show error inside the dialog or let the calling page handle it
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // Ensure loading state is reset even if an error occurs
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Editar Grupo Musical"),
      // Wrap content in SingleChildScrollView for smaller screens/keyboard
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          // Reuse your existing form widget!
          child: GrupoForm(
            nomeController: _nomeController,
            liderController: _liderController,
            contatoController: _contatoController,
            emailController: _emailController,
            observacoesController: _observacoesController,
            statusSelecionado: _statusSelecionado,
            onStatusChanged: (value) {
              // Need setState here because this state lives in the dialog
              if (value != null) {
                setState(() => _statusSelecionado = value);
              }
            },
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Close without saving
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _atualizarGrupo,
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}