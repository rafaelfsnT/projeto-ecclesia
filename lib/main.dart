import 'package:app_ecclesia/widgets/app/global_notification_wrapper.dart';
import 'package:app_ecclesia/widgets/app/offline_block_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'app/my_app_ecclesia.dart';
import 'firebase_options.dart';
import 'notifier/auth_notifier.dart';
import 'services/auth_service.dart';
import 'services/connection_service.dart';
import 'services/upload_service.dart';
import 'viewmodels/aviso_viewmodel.dart';
import 'viewmodels/evento_viewmodel.dart';
import 'viewmodels/liturgia_viewmodel.dart';
import 'viewmodels/perfil_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  final authNotifier = AuthNotifier();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (kDebugMode) {
    await FirebaseAuth.instance.signOut();
    print('MODO DEBUG: Sessão de usuário limpa no reinício.');
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<UploadService>(create: (_) => UploadService()),
        ChangeNotifierProvider(create: (_) => ConnectionService()),

        ChangeNotifierProvider.value(value: authNotifier),
        ChangeNotifierProvider(create: (_) => LiturgiaViewModel()),
        ChangeNotifierProvider(create: (_) => EventoViewModel()),
        ChangeNotifierProvider(create: (_) => AvisoViewModel()),
        ChangeNotifierProvider(
          create:
              (context) => PerfilViewModel(
                authNotifier: authNotifier,
                authService: Provider.of<AuthService>(context, listen: false),
                uploadService: Provider.of<UploadService>(
                  context,
                  listen: false,
                ),
              ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        builder: (context, child) {
          Widget widget = child ?? const SizedBox.shrink();
          widget = OfflineBlockWidget(child: widget);
          widget = GlobalNotificationWrapper(child: widget);
          return widget;
        },

        home: MyAppEcclesia(authNotifier: authNotifier),
      ),
    ),
  );
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}
