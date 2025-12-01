import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../notifier/auth_notifier.dart';
import '../theme_app.dart';
import '../widgets/app/global_notification_wrapper.dart';
import 'utils/app_router.dart';

class MyAppEcclesia extends StatelessWidget {
  final AuthNotifier authNotifier;

  const MyAppEcclesia({super.key, required this.authNotifier});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'App Flutter',
      debugShowCheckedModeBanner: false,
      theme: themeApp(),

      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      routerConfig: createAppRouter(authNotifier),
      builder: (context, child) {
        return GlobalNotificationWrapper(child: child!);
      },
    );
  }
}
