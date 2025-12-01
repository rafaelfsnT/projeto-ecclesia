import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../notifier/auth_notifier.dart';

class GlobalNotificationWrapper extends StatefulWidget {
  final Widget child;

  const GlobalNotificationWrapper({super.key, required this.child});

  @override
  State<GlobalNotificationWrapper> createState() => _GlobalNotificationWrapperState();
}

class _GlobalNotificationWrapperState extends State<GlobalNotificationWrapper> {
  @override
  void initState() {
    super.initState();
    _setupNotifications();
    _listenToForegroundNotifications();
  }

  Future<void> _setupNotifications() async {
    final fcm = FirebaseMessaging.instance;
    NotificationSettings settings = await fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await fcm.subscribeToTopic('eventos');
      // Pequeno delay para garantir que o AuthNotifier esteja pronto
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _saveFcmToken();
      });
    }
  }

  Future<void> _saveFcmToken() async {
    try {
      final fcm = FirebaseMessaging.instance;
      final token = await fcm.getToken();
      if (token == null) return;

      // Pega o UID do provider globalmente
      final uid = context.read<AuthNotifier>().user?.uid;

      if (uid != null) {
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).update(
          {'fcmToken': token},
        );
      }
    } catch (e) {
      debugPrint('Erro ao salvar FCM Token Global: $e');
    }
  }

  void _listenToForegroundNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // [NOVA LÓGICA] Verifica se é Admin
      final authNotifier = context.read<AuthNotifier>();

      // Se for Admin, encerra a função aqui e NÃO mostra o banner
      if (authNotifier.isAdmin) return;

      if (message.notification != null) {
        _showTopNotification(
          title: message.notification!.title ?? 'Nova Notificação',
          body: message.notification!.body ?? '',
        );
      }
    });
  }

  // --- EXIBIÇÃO DO BANNER (OVERLAY GLOBAL) ---
  void _showTopNotification({required String title, required String body}) {
    final overlay = Overlay.of(context);
    final theme = Theme.of(context);

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          child: Material(
            color: Colors.transparent,
            child: _TopBannerWidget(
              title: title,
              body: body,
              theme: theme,
              onDismiss: () {
                if (overlayEntry.mounted) {
                  overlayEntry.remove();
                }
              },
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Fecha sozinho depois de 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// --- WIDGET VISUAL DO BANNER (Com Gradiente) ---
class _TopBannerWidget extends StatefulWidget {
  final String title;
  final String body;
  final ThemeData theme;
  final VoidCallback onDismiss;

  const _TopBannerWidget({
    required this.title,
    required this.body,
    required this.theme,
    required this.onDismiss,
  });

  @override
  State<_TopBannerWidget> createState() => _TopBannerWidgetState();
}

class _TopBannerWidgetState extends State<_TopBannerWidget> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    // Animação de entrada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _isVisible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      // Efeito de descer do topo
      transform: Matrix4.translationValues(0, _isVisible ? 0 : -150, 0),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // O SEU GRADIENTE
        gradient: LinearGradient(
          colors: [
            widget.theme.colorScheme.primary,
            widget.theme.colorScheme.secondary,
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
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.body,
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
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: () {
              setState(() => _isVisible = false);
              Future.delayed(const Duration(milliseconds: 500), () {
                widget.onDismiss();
              });
            },
          ),
        ],
      ),
    );
  }
}