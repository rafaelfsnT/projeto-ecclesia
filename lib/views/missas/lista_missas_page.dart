import '/widgets/app/app_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '/services/missa_service.dart';
import '/widgets/missas/editar_missaC_dialog.dart';
import '/widgets/missas/editar_missasE_dialog.dart';

// NOVO IMPORT
import '../../widgets/admin/admin_list_action_buttons.dart';

class ListaMissasPage extends StatelessWidget {
  ListaMissasPage({super.key});

  final MissaService missaService = MissaService();

  Future<void> excluirMissa(BuildContext context,
      String id,
      String missaNome,) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) =>
          AlertDialog(
            title: const Text("Confirmar exclusão"),
            content: Text('Deseja realmente excluir a missa "$missaNome"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text("Cancelar"),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme
                      .of(context)
                      .colorScheme
                      .error,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text("Excluir"),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      try {
        await FirebaseFirestore.instance.collection("missas").doc(id).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Missa excluída com sucesso!")),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao excluir missa: ${e.toString()}")),
          );
        }
      }
    }
  }

  Future<void> excluirTodasMissas(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) =>
          AlertDialog(
            title: const Text("EXCLUIR TODAS AS MISSAS"),
            content: const Text(
              "ATENÇÃO! Deseja realmente excluir TODAS as missas cadastradas? Esta ação é irreversível.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text("Cancelar"),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme
                      .of(context)
                      .colorScheme
                      .error,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text("EXCLUIR TUDO"),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      try {
        await missaService.deleteAllMissas();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Todas as missas foram excluídas com sucesso!"),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erro ao excluir todas as missas: ${e.toString()}"),
            ),
          );
        }
      }
    }
  }

  void _showFullObservation(BuildContext context, String observacao) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Observação Completa"),
          content: SingleChildScrollView(child: Text(observacao)),
          actions: <Widget>[
            TextButton(
              child: const Text("Fechar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddMissaOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Nova Missa Comum'),
                onTap: () {
                  Navigator.pop(bc);
                  // Usando push/go router se o contexto for o do scaffold
                  // Note: Aqui a navegação original usava push do Flutter, mas se quiser migrar:
                  context.push('/createMissa');
                },
              ),
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Nova Missa Especial'),
                onTap: () {
                  Navigator.pop(bc);
                  // Usando push/go router se o contexto for o do scaffold
                  context.push('/createMissaE');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> editarMissa(BuildContext context, DocumentSnapshot missa) async {
    final bool? salvo = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditarMissaComumDialog(missa: missa),
    );
    if (salvo == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Missa atualizada com sucesso!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> editarMissaEspecial(BuildContext context,
      DocumentSnapshot missa,) async {
    final bool? salvo = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditarMissaEspecialDialog(missa: missa),
    );
    if (salvo == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Missa especial atualizada com sucesso!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildTagsList(List<String> tags, bool isEspecial) {
    return Wrap(
      spacing: 6,
      runSpacing: 2,
      children:
      tags
          .map(
            (t) =>
            Chip(
              label: Text(t, style: const TextStyle(fontSize: 12)),
              backgroundColor:
              isEspecial
                  ? Colors.orange.shade700.withValues(alpha: 0.15)
                  : Colors.grey.shade200,
              labelPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 0,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
      )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Lista de Missas",
      // 1. CONFIGURAÇÃO DA APPBAR: Remove o Back Button e o Drawer
      showBackButton: false,
      showDrawer: false,

      // 2. NOVO LEADING: Botão 'Home'
      leading: const HomeAdminButton(),

      // 3. NOVAS AÇÕES: Botão 'Adicionar' e 'Deletar Tudo'
      actions: [
        AddActionButton(
          tooltip: 'Adicionar Missa',
          onPressed: () => _showAddMissaOptions(context),
        ),
        IconButton(
          icon: const Icon(Icons.delete_forever, color: Colors.red),
          tooltip: "Deletar todas as missas",
          onPressed: () => excluirTodasMissas(context),
        ),
      ],

      // 4. FLOATING ACTION BUTTON REMOVIDO
      floatingActionButton: null,

      // 5. BODY
      body: StreamBuilder<QuerySnapshot>(
        stream:
        FirebaseFirestore.instance
            .collection("missas")
            .orderBy("dataHora")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final missas = snapshot.data!.docs;
          if (missas.isEmpty) {
            return const Center(child: Text("Nenhuma missa cadastrada."));
          }

          return ListView.builder(
            itemCount: missas.length,
            itemBuilder: (context, index) {
              final missa = missas[index];
              final dataHora = (missa['dataHora'] as Timestamp).toDate();
              final dataFormatada = DateFormat('dd/MM/yyyy').format(dataHora);
              final horaFormatada = DateFormat('HH:mm').format(dataHora);

              final DateTime dataExpiracao = dataHora.add(
                const Duration(hours: 1),
              );
              final bool isExpirada = dataExpiracao.isBefore(DateTime.now());

              final dados = missa.data() as Map<String, dynamic>;
              final tipo = dados["tipo"] ?? "comum";
              final titulo = dados["titulo"] ?? "";
              final celebrante = dados["celebrante"] ?? "";
              final String observacao = dados["observacao"] ?? "";
              final List tags =
              (dados["tags"] is List ? dados["tags"] : []) as List;
              final bool isEspecial = tipo == "especial";

              final String nomeMissa =
              titulo.isNotEmpty ? titulo : "Missa Comum";

              final Color cardBackgroundColor =
              isExpirada
                  ? Colors
                  .grey
                  .shade200 // Cor de missa expirada
                  : (isEspecial
                  ? Colors
                  .yellow
                  .shade50 // Cor de missa especial
                  : Theme
                  .of(context)
                  .cardColor); // Cor normal

              // Define o ícone com base no status
              final Icon iconLeading = Icon(
                isExpirada
                    ? Icons
                    .check_circle_outline // Ícone de expirada
                    : (isEspecial ? Icons.star : Icons.church),
                // Ícones normais
                color:
                isExpirada
                    ? Colors
                    .grey
                    .shade600 // Cor do ícone expirado
                    : (isEspecial
                    ? Colors.orange.shade700
                    : Theme
                    .of(context)
                    .primaryColor),
                size: 32,
              );

              final subtitleStyle = TextStyle(
                fontStyle: FontStyle.italic,
                color: isEspecial ? Colors.black54 : Colors.black54,
              );

              return Card(
                color: cardBackgroundColor,
                elevation: isEspecial ? 6 : (isExpirada ? 0 : 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side:
                  isExpirada
                      ? BorderSide(
                    color: Colors.grey.shade400,
                    width: 1,
                  ) // Borda cinza
                      : (isEspecial
                      ? BorderSide(
                    color: Colors.orange.shade700.withValues(
                      alpha: 0.4,
                    ),
                    width: 1,
                  )
                      : BorderSide.none),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  leading: iconLeading,
                  title: Text(
                    nomeMissa,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isExpirada ? Colors.grey.shade700 : Colors.black87,
                      decoration:
                      isExpirada ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$dataFormatada às $horaFormatada",
                        style: subtitleStyle.copyWith(
                          fontStyle: FontStyle.normal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (celebrante.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            "Celebrante: $celebrante",
                            style: subtitleStyle,
                          ),
                        ),
                      if (observacao.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  "Obs: ${observacao.length > 40 ? '${observacao
                                      .substring(0, 40)}...' : observacao}",
                                  style: subtitleStyle.copyWith(
                                    color: Colors.red.shade700,
                                    fontStyle: FontStyle.normal,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (observacao.length > 40)
                                GestureDetector(
                                  onTap:
                                      () =>
                                      _showFullObservation(
                                        context,
                                        observacao,
                                      ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: _buildTagsList(
                            tags.cast<String>(),
                            isEspecial,
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                  IconButton(
                  icon: Icon(
                  Icons.edit,
                      color:
                      isExpirada
                          ? ColorScheme
                          .of(context)
                          .secondary
                          : const Color(0xFF5D4037),
                ),
                onPressed: () {
                  if (isEspecial) {
                    editarMissaEspecial(context, missa);
                  } else {
                    editarMissa(context, missa);
                  }
                },
              ),
              IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed:
              () => excluirMissa(context, missa.id, nomeMissa),
              ),
              ],
              ),
              onTap: () {
              context.go('/missa/${missa.id}');
              },
              )
              ,
              );
            },
          );
        },
      ),
    );
  }
}
