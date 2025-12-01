import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/evento_viewmodel.dart';


class EventosUsuarioPage extends StatelessWidget {
  const EventosUsuarioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Próximos Eventos'),
      ),
      body: Consumer<EventoViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (viewModel.eventos.isEmpty) {
            return const Center(
              child: Text('Nenhum evento agendado.'),
            );
          }

          return ListView.builder(
            itemCount: viewModel.eventos.length,
            itemBuilder: (context, index) {
              final evento = viewModel.eventos[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(evento.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(evento.descricao),
                  trailing: Text(
                    '${evento.dataHora.day}/${evento.dataHora.month}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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