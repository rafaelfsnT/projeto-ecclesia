import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/aviso_model.dart';
import '../../viewmodels/aviso_viewmodel.dart';
import '../../widgets/app/app_scaffold.dart';
import '../../widgets/admin/admin_list_action_buttons.dart';
import '../../widgets/avisos/editar_aviso_dialog.dart';

class AvisoListPage extends StatefulWidget {
  final bool isAdmin;
  const AvisoListPage({this.isAdmin = false, super.key});

  @override
  State<AvisoListPage> createState() => _AvisoListPageState();
}

class _AvisoListPageState extends State<AvisoListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Inicia a escuta de avisos
      context.read<AvisoViewModel>().startListening();
    });
  }

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _confirmDelete(BuildContext context, Aviso a) async {
    final vm = context.read<AvisoViewModel>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Excluir aviso "${a.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await vm.delete(a.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aviso excluído')),
        );
      }
    }
  }

  // Lógica de Excluir Todos
  Future<void> _excluirTodosAvisos(BuildContext context) async {
    final vm = context.read<AvisoViewModel>();

    if (vm.avisos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não há avisos para excluir.")),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("EXCLUIR TODOS OS AVISOS"),
        content: const Text(
          "ATENÇÃO! Deseja realmente excluir TODOS os avisos? Esta ação é irreversível.",
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
        // Copia lista para evitar erros de iteração
        final listaParaExcluir = List<Aviso>.from(vm.avisos);

        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (c) => const Center(child: CircularProgressIndicator()),
          );
        }

        // Deleta um por um usando o método existente
        for (var aviso in listaParaExcluir) {
          await vm.delete(aviso.id);
        }

        if (context.mounted) {
          Navigator.pop(context); // Fecha loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Todos os avisos foram excluídos!")),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Fecha loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao excluir avisos: $e")),
          );
        }
      }
    }
  }

  Future<void> _showEditDialog(BuildContext context, Aviso aviso) async {
    final bool? salvo = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditarAvisoDialog(aviso: aviso),
    );
    if (salvo == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Aviso atualizado com sucesso!"),
            backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Consumer<AvisoViewModel>(
      builder: (context, vm, _) {
        return AppScaffold(
          title: 'Avisos',

          showBackButton: !widget.isAdmin,
          showDrawer: false,
          leading: widget.isAdmin ? const HomeAdminButton() : null,

          // AÇÕES: Se Admin -> Adicionar + Excluir Tudo
          actions: [
            AddActionButton(
              tooltip: 'Adicionar novo aviso',
              onPressed: () => context.push('/avisos/adicionar'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              tooltip: "Deletar todos os avisos",
              onPressed: () => _excluirTodosAvisos(context),
            ),
          ],

          floatingActionButton: null,

          body: vm.isLoading && vm.avisos.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : vm.avisos.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Nenhum aviso encontrado.', style: textTheme.titleMedium),
              ],
            ),
          )
              : RefreshIndicator(
            onRefresh: () async {
              context.read<AvisoViewModel>().startListening();
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: vm.avisos.length,
              itemBuilder: (context, i) {
                final a = vm.avisos[i];
                final isExpired = (a.endsAt != null && a.endsAt!.isBefore(DateTime.now()));

                return Animate(
                  effects: [
                    FadeEffect(duration: 300.ms),
                    SlideEffect(begin: const Offset(0.1, 0), duration: 300.ms)
                  ],
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      onTap: () => context.push('/avisos/detalhe', extra: a),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      isThreeLine: true,
                      leading: CircleAvatar(
                        backgroundColor: isExpired ? colorScheme.error : colorScheme.primary,
                        child: Icon(
                          isExpired ? Icons.watch_later_outlined : Icons.campaign,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(a.title, style: textTheme.titleMedium),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isExpired)
                            Chip(
                              label: const Text('EXPIRADO'),
                              backgroundColor: colorScheme.errorContainer,
                              labelStyle: TextStyle(color: colorScheme.onErrorContainer),
                              padding: EdgeInsets.zero,
                            )
                          else
                            Text(
                              'Publicado em: ${_formatDate(a.publishedAt)}',
                              style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                            ),
                          if (!isExpired && a.endsAt != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Válido até: ${_formatDate(a.endsAt!)}',
                                style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                              ),
                            ),
                        ],
                      ),
                      // Ações de Edição e Exclusão só aparecem se isAdmin for TRUE
                      trailing: widget.isAdmin
                          ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            color: theme.colorScheme.primary,
                            onPressed: () => _showEditDialog(context, a),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: theme.colorScheme.error,
                            onPressed: () => _confirmDelete(context, a),
                          ),
                        ],
                      )
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}