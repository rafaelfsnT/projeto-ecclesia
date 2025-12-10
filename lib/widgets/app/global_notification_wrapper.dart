import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/evento_model.dart';
import '../../notifier/auth_notifier.dart';

class GlobalNotificationWrapper extends StatefulWidget {
  final Widget child;

  const GlobalNotificationWrapper({super.key, required this.child});

  @override
  State<GlobalNotificationWrapper> createState() =>
      _GlobalNotificationWrapperState();
}

class _GlobalNotificationWrapperState extends State<GlobalNotificationWrapper> {
  bool _showBanner = false;
  String _bannerTitle = '';
  String _bannerBody = '';
  RemoteMessage? _currentMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotifications();
      _setupInteractedMessage(); // Configura cliques quando app está fechado/fundo
      _listenToForegroundNotifications(); // Configura banner quando app está aberto
    });
  }

  Future<void> _setupNotifications() async {
    final fcm = FirebaseMessaging.instance;
    // Permissões críticas para iOS e Android 13+
    await fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Inscreve no tópico de eventos
    await fcm.subscribeToTopic('eventos');

    // Salva/Atualiza o token
    final token = await fcm.getToken();
    if (token != null && mounted) {
      final uid = context.read<AuthNotifier>().user?.uid;
      if (uid != null) {
        FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
          'fcmToken': token,
        });
      }
    }
  }

  // 1. Lida com cliques quando o app estava FECHADO ou em SEGUNDO PLANO
  Future<void> _setupInteractedMessage() async {
    // Caso A: App estava terminado e foi aberto pelo toque na notificação
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNavigation(initialMessage);
    }

    // Caso B: App estava em segundo plano e foi aberto pelo toque
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNavigation);
  }

  // 2. Lida com notificações com o app ABERTO (Mostra o Banner na Stack)
  void _listenToForegroundNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Recebi notificação no foreground: ${message.notification?.title}");

      if (message.notification != null) {
        // [OPCIONAL] Se quiser que Admin não veja o banner, descomente abaixo:
        // final isAdmin = context.read<AuthNotifier>().isAdmin;
        // if (isAdmin) return;

        if (mounted) {
          setState(() {
            _bannerTitle = message.notification!.title ?? 'Nova Notificação';
            _bannerBody = message.notification!.body ?? '';
            _currentMessage = message;
            _showBanner = true;
          });

          // Esconde automaticamente após 5 segundos
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted && _showBanner) {
              setState(() => _showBanner = false);
            }
          });
        }
      }
    });
  }

  // 3. Lógica Central de Navegação
  Future<void> _handleNavigation(RemoteMessage message) async {
    // Esconde o banner se estiver aberto
    if (mounted) setState(() => _showBanner = false);

    final data = message.data;
    final screen = data['screen'] as String?;
    final id = data['id'] as String?;

    if (screen == null) return;

    print("Navegando para: $screen com ID: $id");

    // Navegação Direta (Listas ou Missa)
    if (screen.startsWith('/missa/') ||
        screen == '/todas-missas' ||
        screen == '/all-events') {
      context.go(screen);
    }
    // Navegação para Detalhes de Evento (Precisa buscar o objeto antes)
    else if (id != null &&
        (screen.contains('evento') ||
            data['click_action'] == 'FLUTTER_NOTIFICATION_CLICK')) {
      // Mostra loading rápido
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true, // Garante que aparece por cima
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('eventos')
                .doc(id)
                .get();

        // Fecha o loading
        if (mounted) Navigator.of(context, rootNavigator: true).pop();

        if (doc.exists) {
          final evento = Evento.fromMap(doc.data()!, doc.id);
          if (mounted) context.push('/eventos/detalhe', extra: evento);
        } else {
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Evento não encontrado.")),
            );
        }
      } catch (e) {
        // Fecha o loading em caso de erro
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        debugPrint("Erro ao navegar para evento: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // AQUI ESTÁ A CORREÇÃO: Usamos Stack em vez de Overlay
    return Stack(
      children: [
        // 1. O App fica embaixo
        widget.child,

        // 2. O Banner fica em cima (renderizado condicionalmente)
        if (_showBanner)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: _TopBannerWidget(
                  title: _bannerTitle,
                  body: _bannerBody,
                  onTap: () {
                    if (_currentMessage != null)
                      _handleNavigation(_currentMessage!);
                  },
                  onDismiss: () {
                    setState(() => _showBanner = false);
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Widget Visual do Banner (Bonito e com Animação Implícita)
class _TopBannerWidget extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _TopBannerWidget({
    required this.title,
    required this.body,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    // Animação de entrada suave
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -100, end: 0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(offset: Offset(0, value), child: child);
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: onTap,
          // Permite arrastar para cima para fechar
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity! < 0) {
              onDismiss();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onDismiss,
                  child: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
