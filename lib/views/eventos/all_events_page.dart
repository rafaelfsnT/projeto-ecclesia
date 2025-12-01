import '/widgets/app/app_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class TodosEventosPage extends StatefulWidget {
  const TodosEventosPage({super.key});

  @override
  State<TodosEventosPage> createState() => _TodosEventosPageState();
}

class _TodosEventosPageState extends State<TodosEventosPage> {
  @override
  void initState() {
    super.initState();
    // Garante que o 'pt_BR' esteja carregado para as datas
    initializeDateFormatting('pt_BR', null);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Eventos da Paróquia",
      showBackButton: true,
      showBottomNavBar: true,
      currentIndex: 0, // Mantém o ícone da Home ativo
      body: StreamBuilder<QuerySnapshot>(
        // Usamos a mesma query da HomePage
        stream: FirebaseFirestore.instance
            .collection("eventos")
            .where("dataHora", isGreaterThanOrEqualTo: Timestamp.now())
            .orderBy("dataHora", descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint("Erro ao carregar eventos: ${snapshot.error}");
            return const Center(child: Text("Erro ao carregar eventos."));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final eventos = snapshot.data?.docs ?? [];

          if (eventos.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  "Nenhum evento futuro encontrado.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          // Constrói a lista de cards de evento
          return ListView.builder(
            // Adiciona padding na lista
            padding: const EdgeInsets.all(12),
            itemCount: eventos.length,
            itemBuilder: (context, index) {
              final evento = eventos[index];
              // Reutilizamos o widget _buildEventoCard
              return _buildEventoCard(context, evento);
            },
          );
        },
      ),
    );
  }

  /// Constrói o Card para um único evento.
  /// Este widget é uma cópia do 'home_page.dart',
  /// mas com a margem restaurada.
  Widget _buildEventoCard(BuildContext context, DocumentSnapshot evento) {
    final dados = evento.data() as Map<String, dynamic>;

    final String titulo = dados['titulo'] ?? 'Evento';
    final String descricao = dados['descricao'] ?? '';
    final String local = dados['local'] ?? '';
    final DateTime? dataHora = (dados['dataHora'] as Timestamp?)?.toDate();
    final List<dynamic> imageUrlsList =
        dados['imageUrls'] as List<dynamic>? ?? [];
    final String imageUrl =
    imageUrlsList.isNotEmpty ? imageUrlsList.first.toString() : '';

    return Card(
      // Margem para espaçamento na lista
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Imagem do Evento ---
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 180,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                );
              },
              errorBuilder: (context, error, stack) {
                return Container(
                  height: 180,
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.broken_image,
                    size: 50,
                    color: Colors.grey.shade400,
                  ),
                );
              },
            ),

          // --- Informações do Evento ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                if (dataHora != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 16, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR')
                            .format(dataHora),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
                if (local.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 16, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Text(
                        local,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
                if (descricao.isNotEmpty) ...[
                  const Divider(height: 24),
                  // Mostra a descrição completa (sem limite de linhas)
                  Text(
                    descricao,
                    style: const TextStyle(fontSize: 14),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}