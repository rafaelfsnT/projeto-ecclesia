import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/evento_model.dart';
import '../../viewmodels/evento_viewmodel.dart';
import '../../widgets/app/app_scaffold.dart';
import '../../widgets/app/app_list_item.dart';
import '../../widgets/admin/admin_list_action_buttons.dart';
import '../../widgets/eventos/editar_evento_dialog.dart';

class EventosPage extends StatelessWidget {
  const EventosPage({super.key});

  Future<void> _confirmarExclusao(BuildContext context, Evento evento) async {
    final theme = Theme.of(context);
    final vm = Provider.of<EventoViewModel>(context, listen: false);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar Evento'),
        content: Text('Tem certeza que deseja deletar o evento "${evento.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await vm.deletarEvento(evento.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Evento deletado')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao deletar: $e')),
          );
        }
      }
    }
  }

  // Lógica inteligente: Usa o método de deletar um por um para simular o "Excluir Tudo"
  // sem precisar criar uma nova query no backend imediatamente.
  Future<void> _excluirTodosEventos(BuildContext context) async {
    final vm = Provider.of<EventoViewModel>(context, listen: false);

    if (vm.eventos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não há eventos para excluir.")),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("EXCLUIR TODOS OS EVENTOS"),
        content: const Text(
          "ATENÇÃO! Deseja realmente excluir TODOS os eventos cadastrados? Esta ação é irreversível.",
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
        // Copia a lista para evitar erros de modificação concorrente
        final listaParaExcluir = List<Evento>.from(vm.eventos);

        // Exibe loading
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (c) => const Center(child: CircularProgressIndicator()),
          );
        }

        for (var evento in listaParaExcluir) {
          if (evento.id != null) {
            await vm.deletarEvento(evento.id!);
          }
        }

        if (context.mounted) {
          Navigator.pop(context); // Fecha loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Todos os eventos foram excluídos!")),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Fecha loading se der erro
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao excluir eventos: $e")),
          );
        }
      }
    }
  }

  Future<void> _editarEvento(BuildContext context, Evento evento) async {
    final bool? salvo = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return EditarEventoDialog(evento: evento);
      },
    );

    if (salvo == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Evento atualizado com sucesso!"),
          backgroundColor: Colors.green,
        ),
      );
      Provider.of<EventoViewModel>(context, listen: false).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppScaffold(
      title: 'Gerenciar Eventos',
      // 1. PADRONIZAÇÃO DO HEADER (Igual ListaMissasPage)
      showBackButton: false,
      showDrawer: false,
      leading: const HomeAdminButton(),

      // 2. AÇÕES: Adicionar e Excluir Tudo
      actions: [
        AddActionButton(
          tooltip: 'Adicionar Evento',
          onPressed: () => context.push('/eventos/adicionar'),
        ),
        IconButton(
          icon: const Icon(Icons.delete_forever, color: Colors.red),
          tooltip: "Deletar todos os eventos",
          onPressed: () => _excluirTodosEventos(context),
        ),
      ],

      // 3. REMOÇÃO DE BOTÕES FLUTUANTES
      floatingActionButton: null,

      body: Consumer<EventoViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.eventos.isEmpty) {
            return Center(
              child: Text(
                'Nenhum evento encontrado.',
                style: textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => Provider.of<EventoViewModel>(context, listen: false).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: viewModel.eventos.length,
              itemBuilder: (context, index) {
                final evento = viewModel.eventos[index];
                final dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(evento.dataHora.toLocal());

                return AppListItem(
                  index: index,
                  leadingIcon: Icons.celebration,
                  title: evento.titulo,
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Local: ${evento.local}', style: textTheme.bodyMedium),
                      Text('Data: $dataFormatada', style: textTheme.bodyMedium),
                    ],
                  ),
                  onTap: () => context.push('/eventos/detalhe', extra: evento),
                  onEdit: () => _editarEvento(context, evento),
                  onDelete: () => _confirmarExclusao(context, evento),
                );
              },
            ),
          );
        },
      ),
    );
  }
}