// KANAWA - Splash Screen
// Design: MBSoft · Benvindo Mersh
// Ano: 2026
// v1.1 — Valida token com /auth/me/ antes de navegar

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../shared/widgets/kanawa_logo_pin.dart';
import '../../shared/widgets/kanawa_signature.dart';
import '../auth/login_screen.dart';
import '../auth/verify_code_screen.dart';
import '../passenger/home_screen.dart';

// ═══════════════════════════════════════════════════════════
// CORES
// ═══════════════════════════════════════════════════════════
class _C {
  static const red = Color(0xFFE01818);
  static const blue = Color(0xFF1E5FE0);
  static const blueDark = Color(0xFF0A4AD8);
  static const blueLight = Color(0xFF4A90E2);
  static const blueSoft = Color(0xFFE8F0FE);
  static const textStrong = Color(0xFF18181B);
  static const textMuted = Color(0xFF71717A);
  static const textSubtle = Color(0xFFA1A1AA);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _wordController;
  late AnimationController _progressController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _wordController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    _entryController.forward();

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    _wordController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _pulseController.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _progressController.forward();

    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    await _navigate();
  }

  Future<void> _navigate() async {
    // ═══════════════════════════════════════════════════════
    // 1. Verificação pendente (registo/verificação em curso)
    // ═══════════════════════════════════════════════════════
    final pending = await ApiClient.getPendingVerification();
    if (!mounted) return;

    if (pending != null) {
      _goTo(
        VerifyCodeScreen(
          phone: pending['phone']!,
          email: pending['email']!,
        ),
      );
      return;
    }

    // ═══════════════════════════════════════════════════════
    // 2. Verifica se há tokens guardados
    // ═══════════════════════════════════════════════════════
    final hasSession = await ApiClient.hasSession();
    if (!mounted) return;

    if (!hasSession) {
      // Sem tokens → Login
      _goTo(const LoginScreen());
      return;
    }

    // ═══════════════════════════════════════════════════════
    // 3. Tem tokens → valida com /auth/me/
    // (o ApiClient renova automaticamente se o access expirou
    //  mas o refresh ainda é válido)
    // ═══════════════════════════════════════════════════════
    final response = await ApiClient.get('/auth/me/');
    if (!mounted) return;

    if (response.success) {
      // ✅ Tokens válidos → Home
      _goTo(const HomeScreen());
    } else {
      // ❌ Tokens inválidos → limpa e Login
      await ApiClient.clearTokens();
      if (!mounted) return;
      _goTo(const LoginScreen());
    }
  }

  void _goTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _wordController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 4),

              // Pin com carro
              AnimatedBuilder(
                animation: Listenable.merge([
                  _entryController,
                  _pulseController,
                ]),
                builder: (context, _) {
                  final entry = Curves.easeOutCubic
                      .transform(_entryController.value);
                  final pulse = _pulseController.value;

                  return Opacity(
                    opacity: entry,
                    child: Transform.translate(
                      offset: Offset(0, (1 - entry) * 20),
                      child: Transform.scale(
                        scale: 0.82 + (entry * 0.18),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _C.red.withOpacity(
                                  0.12 + (pulse * 0.08),
                                ),
                                blurRadius: 32 + (pulse * 8),
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const KanawaLogoPin(
                            size: 150,
                            showShadow: true,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // Wordmark
              AnimatedBuilder(
                animation: _wordController,
                builder: (_, __) => _AnimatedWordmark(
                  progress: _wordController.value,
                ),
              ),

              const SizedBox(height: 12),

              // Tagline
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _entryController,
                  curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _taglineWord('TAXI'),
                    _taglineDot(),
                    _taglineWord('RÁPIDO'),
                    _taglineDot(),
                    _taglineWord('SEGURO'),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // Frase
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _entryController,
                  curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
                ),
                child: Text(
                  'O seu destino,\na nossa prioridade.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _C.textMuted,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Barra de progresso
              AnimatedBuilder(
                animation: _progressController,
                builder: (_, __) => _ProgressBar(
                  progress: _progressController.value,
                ),
              ),

              const Spacer(flex: 3),

              // Assinatura
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _entryController,
                  curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
                ),
                child: const Center(child: KanawaSignature()),
              ),

              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _taglineWord(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: _C.textMuted,
      ),
    );
  }

  Widget _taglineDot() {
    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: _C.textSubtle,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// WORDMARK
// ═══════════════════════════════════════════════════════════
class _AnimatedWordmark extends StatelessWidget {
  final double progress;

  const _AnimatedWordmark({required this.progress});

  @override
  Widget build(BuildContext context) {
    const word = 'KANAWA';
    const total = 6;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final start = index / total * 0.55;
        final end = start + 0.45;
        final p = ((progress - start) / (end - start)).clamp(0.0, 1.0);
        final curved = Curves.easeOutCubic.transform(p);

        return Opacity(
          opacity: curved,
          child: Transform.translate(
            offset: Offset(0, (1 - curved) * 12),
            child: Transform.scale(
              scale: 0.94 + (curved * 0.06),
              child: Text(
                word[index],
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                  color: _C.textStrong,
                  height: 1,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// BARRA DE PROGRESSO
// ═══════════════════════════════════════════════════════════
class _ProgressBar extends StatelessWidget {
  final double progress;

  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    const maxWidth = 160.0;
    const barHeight = 4.0;

    return SizedBox(
      width: maxWidth,
      height: barHeight,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: _C.blueSoft,
              borderRadius: BorderRadius.circular(barHeight / 2),
            ),
          ),
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_C.blueDark, _C.blueLight],
                ),
                borderRadius: BorderRadius.circular(barHeight / 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}