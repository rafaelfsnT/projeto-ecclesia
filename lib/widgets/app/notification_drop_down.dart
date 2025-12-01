import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/evento_model.dart';

class NotificationDropDown extends StatefulWidget {
  final String? uid;

  const NotificationDropDown({super.key, required this.uid});

  @override
  State<NotificationDropDown> createState() => NotificationDropDownState();
}

class NotificationDropDownState extends State<NotificationDropDown> {
  late Stream<QuerySnapshot> _stream;

  @override
  void initState() {
    super.initState();
    if (widget.uid != null) {
      _stream =
          FirebaseFirestore.instance
              .collection('usuarios')
              .doc(widget.uid)
              .collection('notificacoes')
              .orderBy('data', descending: true)
              .limit(10)
              .snapshots();
    } else {
      _stream = const Stream.empty();
    }
  }

  /// Ação: O usuário clicou em uma notificação
  Future<void> _handleNotificationTap(
    BuildContext context,
    DocumentSnapshot doc,
  ) async {
    final data = doc.data() as Map<String, dynamic>;
    final tipo = data['tipo'];
    final documentId = data['documentId'];

    // 1. Fecha o MENU (Dropdown) imediatamente
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    // 2. Marca como lida (sem esperar/await para ser rápido)
    _markAsRead(doc.id);

    // 3. Lógica de Navegação
    if (tipo == 'evento' && documentId != null) {
      // [CORREÇÃO] Abre o Loading no Root Navigator (garante que fica por cima de tudo)
      showDialog(
        context: this.context, // Usa o contexto do Widget (State), não do menu
        barrierDismissible: false,
        useRootNavigator: true, // <--- IMPORTANTE
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Busca dados
        final eventoSnapshot =
            await FirebaseFirestore.instance
                .collection('eventos')
                .doc(documentId)
                .get();

        // [CORREÇÃO] Fecha o Loading no Root Navigator
        if (mounted) {
          Navigator.of(this.context, rootNavigator: true).pop();
        }

        if (eventoSnapshot.exists) {
          final eventData = eventoSnapshot.data() as Map<String, dynamic>;
          final eventoModel = Evento.fromMap(eventData, eventoSnapshot.id);

          if (mounted) {
            // Navega para a tela
            this.context.push('/eventos/detalhe', extra: eventoModel);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(this.context).showSnackBar(
              const SnackBar(content: Text("Este evento não existe mais.")),
            );
          }
        }
      } catch (e) {
        // Se der erro, garante que fecha o loading
        if (mounted) {
          Navigator.of(this.context, rootNavigator: true).pop();
        }
        debugPrint("Erro ao buscar evento: $e");
      }
    } else if (tipo == 'missa' && documentId != null) {
      // Para missa, navegação direta (GoRouter lida com o carregamento na página destino)
      if (mounted) this.context.go('/missa/$documentId');
    }
  }

  Future<void> _markAsRead(String notifId) async {
    if (widget.uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.uid)
          .collection('notificacoes')
          .doc(notifId)
          .update({'lida': true});
    } catch (e) {
      debugPrint("Erro ao marcar notificação como lida: $e");
    }
  }

  Future<void> _markAllAsRead(
    BuildContext menuContext,
    QuerySnapshot snapshot,
  ) async {
    // 1. [CORREÇÃO] Fecha o menu PRIMEIRO
    Navigator.of(menuContext).pop();

    if (widget.uid == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['lida'] == false) {
          batch.update(doc.reference, {'lida': true});
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Erro ao marcar todas como lidas: $e");
    }
  }

  Future<void> _deleteNotification(String notifId) async {
    if (widget.uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.uid)
          .collection('notificacoes')
          .doc(notifId)
          .delete();
    } catch (e) {
      debugPrint("Erro ao excluir notificação: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.uid == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (context, snapshot) {
        final bool isLoading =
            snapshot.connectionState == ConnectionState.waiting;
        final bool hasError = snapshot.hasError;
        final List<DocumentSnapshot> docs = snapshot.data?.docs ?? [];

        final int unreadCount =
            docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              return data != null && data['lida'] == false;
            }).length;

        return PopupMenuButton<String>(
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(unreadCount.toString()),
            child: const Icon(Icons.notifications_outlined),
          ),
          offset: const Offset(0, 50),
          elevation: 4,
          color: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          itemBuilder: (dialogContext) {
            return [
              PopupMenuItem(
                enabled: false,
                padding: EdgeInsets.zero,
                child: SizedBox(
                  width: 350,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Notificações",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "$unreadCount novas",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, thickness: 0.5),

                      if (isLoading)
                        const SizedBox(
                          height: 100,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (hasError)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: Text("Erro ao carregar.")),
                        )
                      else if (docs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.notifications_off_outlined,
                                  size: 40,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Sem notificações",
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 350,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: docs.length,
                            itemBuilder: (ctx, index) {
                              final doc = docs[index];
                              final notif = doc.data() as Map<String, dynamic>;
                              final bool isRead = notif['lida'] ?? false;

                              IconData iconData = Icons.info_outline;
                              if (notif['tipo'] == 'evento')
                                iconData = Icons.celebration_rounded;
                              else if (notif['tipo'] == 'missa')
                                iconData = Icons.calendar_month_rounded;

                              // [VISUAL] Lógica de Cores para Lida/Não Lida
                              final Color bgColor =
                                  isRead
                                      ? Colors.white
                                      : theme.colorScheme.primary.withValues(
                                        alpha: 0.08,
                                      );
                              // Se não lida -> Preto forte. Se lida -> Cinza escuro
                              final Color titleColor =
                                  isRead ? Colors.grey.shade800 : Colors.black;
                              // Se não lida -> Negrito (w800). Se lida -> Normal
                              final FontWeight titleWeight =
                                  isRead ? FontWeight.normal : FontWeight.w800;
                              final Color iconColor =
                                  isRead
                                      ? Colors.grey.shade400
                                      : theme.colorScheme.primary;

                              return Dismissible(
                                key: Key(doc.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Colors.red.shade50,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  return await showDialog<bool>(
                                    context: dialogContext,
                                    builder: (context) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                        ),
                                        backgroundColor: Colors.transparent,
                                        child: Container(
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            gradient: LinearGradient(
                                              colors: [
                                                theme.colorScheme.primary,
                                                theme.colorScheme.secondary
                                                    .withValues(alpha: 0.8),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.delete_forever,
                                                size: 32,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(height: 16),
                                              const Text(
                                                "Excluir",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              const Text(
                                                "Apagar esta notificação?",
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 24),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextButton(
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                            false,
                                                          ),
                                                      style:
                                                          TextButton.styleFrom(
                                                            foregroundColor:
                                                                Colors.white,
                                                          ),
                                                      child: const Text(
                                                        "Cancelar",
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: ElevatedButton(
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                            true,
                                                          ),
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.white,
                                                            foregroundColor:
                                                                Colors.red,
                                                          ),
                                                      child: const Text(
                                                        "Excluir",
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                onDismissed:
                                    (direction) => _deleteNotification(doc.id),
                                child: Container(
                                  color: bgColor,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: Stack(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color:
                                                isRead
                                                    ? Colors.grey[100]
                                                    : Colors.white,
                                            shape: BoxShape.circle,
                                            // Borda colorida se não lida
                                            border:
                                                isRead
                                                    ? null
                                                    : Border.all(
                                                      color: theme
                                                          .colorScheme
                                                          .primary
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                    ),
                                          ),
                                          child: Icon(
                                            iconData,
                                            color: iconColor,
                                            size: 20,
                                          ),
                                        ),
                                        // [VISUAL] Bolinha azul para não lida
                                        if (!isRead)
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color:
                                                    theme.colorScheme.primary,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    title: Text(
                                      notif['titulo'] ?? 'Notificação',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: titleWeight,
                                        // Aplica o negrito
                                        color: titleColor,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        notif['corpo'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    onTap:
                                        () => _handleNotificationTap(
                                          dialogContext,
                                          doc,
                                        ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      const Divider(height: 1, thickness: 0.5),

                      if (!isLoading && !hasError && docs.isNotEmpty)
                        InkWell(
                          // [CORREÇÃO] Passamos o contexto do diálogo para fechar
                          onTap:
                              () =>
                                  _markAllAsRead(dialogContext, snapshot.data!),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            alignment: Alignment.center,
                            child: Text(
                              "Marcar todas como lidas",
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ];
          },
        );
      },
    );
  }
}
