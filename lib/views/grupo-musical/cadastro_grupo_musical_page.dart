import '/widgets/app/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/widgets/grupo-musical/grupo_buttons.dart';
import '/widgets/grupo-musical/grupo_form.dart';

class CadastroGrupoMusicalPage extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? grupo;

  const CadastroGrupoMusicalPage({super.key, this.docId, this.grupo});

  @override
  State<CadastroGrupoMusicalPage> createState() =>
      _CadastroGrupoMusicalPageState();
}

class _CadastroGrupoMusicalPageState extends State<CadastroGrupoMusicalPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _liderController = TextEditingController();
  final _contatoController = TextEditingController();
  final _emailController = TextEditingController();
  final _observacoesController = TextEditingController();

  String _statusSelecionado = 'Ativo';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.grupo != null) {
      _nomeController.text = widget.grupo!['nome'] ?? '';
      _liderController.text = widget.grupo!['lider'] ?? '';
      _contatoController.text = widget.grupo!['contato'] ?? '';
      _emailController.text = widget.grupo!['email'] ?? '';
      _observacoesController.text = widget.grupo!['observacoes'] ?? '';
      _statusSelecionado = widget.grupo!['status'] ?? 'Ativo';
    }
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

  Future<void> _salvarGrupo() async {
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
        'dataAtualizacao': Timestamp.fromDate(DateTime.now()),
      };

      final coll = FirebaseFirestore.instance.collection('grupos_musicais');

      if (widget.docId == null) {
        // Novo grupo
        final docRef = coll.doc();
        await docRef.set({
          ...grupoData,
          'dataCriacao': Timestamp.fromDate(DateTime.now()),
        });
      } else {
        // Editar grupo existente
        await coll.doc(widget.docId).update(grupoData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.docId == null
                  ? 'Grupo musical cadastrado com sucesso!'
                  : 'Grupo musical atualizado com sucesso!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Retorna para a lista padronizada
        context.go('/grupos-musicais');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.docId == null ? "Cadastrar Grupo Musical" : "Editar Grupo Musical";

    return AppScaffold(
      title: title,
      showBackButton: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GrupoForm(
                nomeController: _nomeController,
                liderController: _liderController,
                contatoController: _contatoController,
                emailController: _emailController,
                observacoesController: _observacoesController,
                statusSelecionado: _statusSelecionado,
                onStatusChanged: (value) {
                  if (value != null) setState(() => _statusSelecionado = value);
                },
              ),
              const SizedBox(height: 24),
              GrupoButtons(
                isLoading: _isLoading,
                onSalvar: _salvarGrupo,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
