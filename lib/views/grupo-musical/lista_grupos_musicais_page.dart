import '/widgets/app/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '/widgets/grupo-musical/editar_dialog.dart';
import '/widgets/grupo-musical/status_chip.dart';
import '../../widgets/admin/admin_list_action_buttons.dart';

class ListaGruposMusicaisPage extends StatelessWidget {
  const ListaGruposMusicaisPage({super.key});

  Future<void> _confirmarExclusao(
      BuildContext context, String docId, String grupoNome) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Confirmar exclusão"),
        content: Text("Tem certeza que deseja excluir o grupo \"$grupoNome\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('grupos_musicais')
            .doc(docId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Grupo excluído com sucesso")),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao excluir o grupo: ${e.toString()}")),
          );
        }
      }
    }
  }

  // FUNÇÃO: EXCLUIR TODOS OS GRUPOS
  Future<void> _excluirTodosGrupos(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("EXCLUIR TODOS OS GRUPOS"),
        content: const Text(
          "ATENÇÃO! Deseja realmente excluir TODOS os grupos musicais cadastrados? Esta ação é irreversível.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("EXCLUIR TUDO"),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        final collection = FirebaseFirestore.instance.collection('grupos_musicais');
        final snapshots = await collection.get();

        // Batch delete para maior performance e atomicidade
        WriteBatch batch = FirebaseFirestore.instance.batch();
        for (var doc in snapshots.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Todos os grupos foram excluídos com sucesso!"),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erro ao excluir todos os grupos: ${e.toString()}"),
            ),
          );
        }
      }
    }
  }

  Future<void> _abrirDialogEdicao(
      BuildContext context,
      String docId,
      Map<String, dynamic> grupo,
      ) async {
    final bool? foiSalvo = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => EditarGrupoMusicalDialog(
        docId: docId,
        grupo: grupo,
      ),
    );

    if (foiSalvo == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grupo musical atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Grupos Musicais",

      // 1. CONFIGURAÇÃO DA APPBAR
      showBackButton: false,
      showDrawer: false,

      // 2. LEADING PADRÃO
      leading: const HomeAdminButton(),

      // 3. AÇÕES PADRONIZADAS (Adicionar + Deletar Todos)
      actions: [
        AddActionButton(
          tooltip: 'Cadastrar Novo Grupo',
          onPressed: () => context.push('/cadastroGM'),
        ),
        IconButton(
          icon: const Icon(Icons.delete_forever, color: Colors.red),
          tooltip: "Deletar todos os grupos",
          onPressed: () => _excluirTodosGrupos(context),
        ),
      ],

      floatingActionButton: null,

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('grupos_musicais')
            .orderBy('nome')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Erro ao carregar os grupos."));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("Nenhum grupo cadastrado."));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final grupo = doc.data() as Map<String, dynamic>;
              final docId = doc.id;
              final status = grupo['status'] ?? '';
              final grupoNome = grupo['nome'] ?? "Grupo Sem Nome";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          grupoNome,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusChip(status: status),
                    ],
                  ),
                  subtitle: Text("Líder: ${grupo['lider'] ?? 'N/A'}"),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _abrirDialogEdicao(context, docId, grupo);
                      } else if (value == 'delete') {
                        _confirmarExclusao(context, docId, grupoNome);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text("Excluir"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}