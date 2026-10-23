// KANAWA - Home
// Design: MBSoft · Benvindo Mersh
// v1.4 — Sino com badge + navegação para NotificationsScreen

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/models/user.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import 'history_screen.dart';
import 'notifications_screen.dart';
import 'ride_request_screen.dart';

// ═══════════════════════════════════════════════════════════
// CORES
// ═══════════════════════════════════════════════════════════
class _C {
  static const red = Color(0xFFE01818);
  static const blue = Color(0xFF1E5FE0);
  static const blueDark = Color(0xFF0A4AD8);
  static const blueSoft = Color(0xFFE8F0FE);
  static const textStrong = Color(0xFF18181B);
  static const textMuted = Color(0xFF71717A);
  static const textSubtle = Color(0xFFA1A1AA);
  static const bgApp = Color(0xFFFAFAFA);
  static const bgSoft = Color(0xFFF4F4F5);
  static const border = Color(0xFFE4E4E7);
  static const success = Color(0xFF16A34A);
}

// ═══════════════════════════════════════════════════════════
// PROMOÇÕES
// ═══════════════════════════════════════════════════════════
class _Promo {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;

  const _Promo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });
}

const _promos = [
  _Promo(
    title: 'Primeira viagem',
    subtitle: '50% de desconto na tua primeira corrida',
    icon: Icons.local_offer_rounded,
    colors: [Color(0xFFE01818), Color(0xFFB91C1C)],
  ),
  _Promo(
    title: 'Mota é mais rápido',
    subtitle: 'Chega ao destino em metade do tempo',
    icon: Icons.two_wheeler_rounded,
    colors: [Color(0xFF1E5FE0), Color(0xFF0A4AD8)],
  ),
  _Promo(
    title: 'Convide amigos',
    subtitle: 'Ganha 500 Kz por cada amigo que se registar',
    icon: Icons.people_alt_rounded,
    colors: [Color(0xFF16A34A), Color(0xFF15803D)],
  ),
];

// ═══════════════════════════════════════════════════════════
// AÇÕES RÁPIDAS
// ═══════════════════════════════════════════════════════════
class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
  });
}

const _quickActions = [
  _QuickAction(
    label: 'Casa',
    icon: Icons.home_rounded,
    color: Color(0xFF1E5FE0),
  ),
  _QuickAction(
    label: 'Trabalho',
    icon: Icons.work_rounded,
    color: Color(0xFF16A34A),
  ),
  _QuickAction(
    label: 'Favoritos',
    icon: Icons.star_rounded,
    color: Color(0xFFD97706),
  ),
  _QuickAction(
    label: 'Recentes',
    icon: Icons.history_rounded,
    color: Color(0xFF71717A),
  ),
];

// ═══════════════════════════════════════════════════════════
// HOME SCREEN
// ═══════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _user;
  bool _isLoadingUser = true;
  int _unreadCount = 0;
  Timer? _badgeTimer;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadUnreadCount();
    _startBadgeRefresh();
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    super.dispose();
  }

  void _startBadgeRefresh() {
    _badgeTimer?.cancel();
    _badgeTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadUnreadCount();
    });
  }

  Future<void> _loadUser() async {
    try {
      final response = await ApiClient.get('/auth/me/');
      if (!mounted) return;

      if (response.success && response.data is Map) {
        setState(() {
          _user = User.fromJson(response.data as Map<String, dynamic>);
          _isLoadingUser = false;
        });
      } else {
        if (response.statusCode == 401) {
          await ApiClient.clearTokens();
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
          return;
        }
        setState(() => _isLoadingUser = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingUser = false);
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final response = await ApiClient.get(
        '/notifications/unread-count/',
        authenticated: true,
      );
      if (!mounted) return;

      if (response.success && response.data is Map) {
        final count = response.data['unread_count'];
        final parsed = (count is int)
            ? count
            : int.tryParse(count?.toString() ?? '0') ?? 0;
        if (mounted) setState(() => _unreadCount = parsed);
      }
    } catch (_) {
      // silencioso — não interrompe a home
    }
  }

  void _goToRideRequest() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RideRequestScreen(),
      ),
    );
  }

  void _goToHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const HistoryScreen(),
      ),
    );
  }

  void _goToProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  Future<void> _goToNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
    // Ao voltar, atualiza o badge
    _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bgApp,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══════════════════════════════════════════
              // HEADER
              // ═══════════════════════════════════════════
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _goToProfile,
                      child: _HeaderAvatar(
                        name: _user?.firstName ?? 'K',
                        loading: _isLoadingUser,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HeaderGreeting(
                        name: _user?.firstName ?? 'Bem-vindo',
                        loading: _isLoadingUser,
                      ),
                    ),
                    _IconCircleButton(
                      icon: Icons.history_rounded,
                      onTap: _goToHistory,
                    ),
                    const SizedBox(width: 8),
                    _NotificationButton(
                      unreadCount: _unreadCount,
                      onTap: _goToNotifications,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ═══════════════════════════════════════════
              // CARD PRINCIPAL — PEDIR VIAGEM
              // ═══════════════════════════════════════════
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _MainRequestCard(onTap: _goToRideRequest),
              ),

              const SizedBox(height: 28),

              // ═══════════════════════════════════════════
              // PROMO CAROUSEL
              // ═══════════════════════════════════════════
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Para ti',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _C.textStrong,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'Ver tudo',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _C.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _promos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return _PromoCard(promo: _promos[index]);
                  },
                ),
              ),

              const SizedBox(height: 28),

              // ═══════════════════════════════════════════
              // AÇÕES RÁPIDAS
              // ═══════════════════════════════════════════
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Acesso rápido',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _C.textStrong,
                    letterSpacing: -0.3,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: _quickActions.map((action) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: action == _quickActions.last ? 0 : 10,
                        ),
                        child: _QuickActionButton(
                          action: action,
                          onTap: action.label == 'Recentes'
                              ? _goToHistory
                              : _goToRideRequest,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 28),

              // ═══════════════════════════════════════════
              // VIAGENS RECENTES
              // ═══════════════════════════════════════════
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Viagens recentes',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _C.textStrong,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _goToHistory,
                      child: Text(
                        'Histórico',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _C.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _EmptyRecent(),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// BOTÃO DE NOTIFICAÇÕES COM BADGE
// ═══════════════════════════════════════════════════════════
class _NotificationButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _NotificationButton({
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              unreadCount > 0
                  ? Icons.notifications_rounded
                  : Icons.notifications_none_rounded,
              color: _C.textStrong,
              size: 20,
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                constraints: const BoxConstraints(minWidth: 20),
                decoration: BoxDecoration(
                  color: _C.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CARD PRINCIPAL — PEDIR VIAGEM
// ═══════════════════════════════════════════════════════════
class _MainRequestCard extends StatelessWidget {
  final VoidCallback onTap;

  const _MainRequestCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_C.red, Color(0xFFB91C1C)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _C.red.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.directions_car_rounded,
                size: 120,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PRONTO PARA IR?',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pedir uma viagem',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Rápido, seguro e ao melhor preço',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: _C.red,
                    size: 26,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// HEADER — AVATAR
// ═══════════════════════════════════════════════════════════
class _HeaderAvatar extends StatelessWidget {
  final String name;
  final bool loading;

  const _HeaderAvatar({required this.name, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: loading
            ? Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: _C.bgSoft,
                  shape: BoxShape.circle,
                ),
              )
            : Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: _C.red,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'K',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// HEADER — GREETING
// ═══════════════════════════════════════════════════════════
class _HeaderGreeting extends StatelessWidget {
  final String name;
  final bool loading;

  const _HeaderGreeting({required this.name, required this.loading});

  @override
  Widget build(BuildContext context) {
    return loading
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100,
                height: 12,
                decoration: BoxDecoration(
                  color: _C.bgSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 140,
                height: 10,
                decoration: BoxDecoration(
                  color: _C.bgSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Olá, $name',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _C.textStrong,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Para onde vamos hoje?',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _C.textMuted,
                ),
              ),
            ],
          );
  }
}

// ═══════════════════════════════════════════════════════════
// BOTÃO CIRCULAR
// ═══════════════════════════════════════════════════════════
class _IconCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: _C.textStrong, size: 20),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CARD DE PROMOÇÃO
// ═══════════════════════════════════════════════════════════
class _PromoCard extends StatelessWidget {
  final _Promo promo;

  const _PromoCard({required this.promo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: promo.colors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: promo.colors.first.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              promo.icon,
              size: 100,
              color: Colors.white.withOpacity(0.15),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      promo.icon,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                promo.title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                promo.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.85),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// AÇÃO RÁPIDA
// ═══════════════════════════════════════════════════════════
class _QuickActionButton extends StatelessWidget {
  final _QuickAction action;
  final VoidCallback onTap;

  const _QuickActionButton({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                action.icon,
                color: action.color,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _C.textStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// VIAGENS RECENTES VAZIO
// ═══════════════════════════════════════════════════════════
class _EmptyRecent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: _C.bgSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car_outlined,
              color: _C.textMuted,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ainda sem viagens',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _C.textStrong,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pede a tua primeira viagem e aparece aqui',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _C.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}