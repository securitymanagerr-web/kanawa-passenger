// KANAWA - App Passageiro
// Plataforma de transporte por aplicativo
// Angola · Saurimo, Lunda Sul

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/services/local_notifications_service.dart';
import 'core/theme/kanawa_theme.dart';
import 'features/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Força modo retrato
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 🔔 Inicializar notificações locais (som + vibração)
  await LocalNotificationsService.initialize();

  runApp(const KanawaApp());
}

class KanawaApp extends StatelessWidget {
  const KanawaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KANAWA',
      debugShowCheckedModeBanner: false,
      theme: KanawaTheme.light(),
      home: const SplashScreen(),
    );
  }
}