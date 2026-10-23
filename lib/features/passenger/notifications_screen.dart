// KANAWA - Notificações (Passageiro)
// v1.2 — Navegação + som/vibração quando chega notificação nova
// Design: MBSoft · Benvindo Mersh

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/api/api_client.dart';
import '../../core/services/local_notifications_service.dart';
import 'trip_tracking_screen.dart';

// ═══════════════════════════════════════════════════════════
// CORES (locais — igual ao home_screen.dart)
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
  static const bgCard = Color(0xFFFFFFFF);
  static const border = Color(0xFFE4E4E7);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);
  static const driver = Color(0xFF0F766E);
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;
  bool _isNavigating = false;

  // 🔔 Para detetar notificações novas
  final Set<String> _knownNotificationIds = {};
  bool _firstLoadDone = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _loadNotifications(silent: true);
    });
  }

  Future<void> _loadNotifications({bool silent = false}) async {
    if (!mounted) return;

    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await ApiClient.get(
        '/notifications/',
        authenticated: true,
      );

      if (!mounted) return;

      if (response.success) {
        final data = response.data;
        List<dynamic>? list;

        if (data is List) {
          list = data;
        } else if (data is Map && data['results'] is List) {
          list = data['results'] as List;
        }

        if (list != null) {
          final all = list
              .map((m) => Map<String, dynamic>.from(m as Map))
              .toList();

          // 🔔 Detetar notificações novas (só após primeira carga)
          if (_firstLoadDone) {
            for (final n in all) {
              final id = n['id']?.toString() ?? '';
              if (id.isEmpty) continue;
              if (_knownNotificationIds.contains(id)) continue;

              _playNotificationSound(n);
            }
          }

          // Atualizar ids conhecidos
          _knownNotificationIds.clear();
          for (final n in all) {
            final id = n['id']?.toString() ?? '';
            if (id.isNotEmpty) _knownNotificationIds.add(id);
          }

          setState(() {
            _notifications = all;
            _isLoading = false;
            _error = null;
          });

          if (!_firstLoadDone) _firstLoadDone = true;
        } else {
          setState(() {
            _notifications = [];
            _isLoading = false;
          });
        }
      } else {
        if (!silent) {
          setState(() {
            _isLoading = false;
            _error = 'Erro ao carregar notificações';
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Erro: $e');
      if (!silent && mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Erro de ligação';
        });
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🔔 SOM + VIBRAÇÃO
  // ═══════════════════════════════════════════════════════════
  Future<void> _playNotificationSound(Map<String, dynamic> notif) async {
    final title = notif['title']?.toString() ?? 'Notificação';
    final message = notif['message']?.toString() ?? '';

    await LocalNotificationsService.show(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: title,
      body: message,
      payload: notif['type']?.toString(),
    );
  }

  Future<void> _markAsRead(String id) async {
    try {
      await ApiClient.post(
        '/notifications/$id/read/',
        body: {},
        authenticated: true,
      );
      _loadNotifications(silent: true);
    } catch (e) {
      debugPrint('❌ Erro: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final res = await ApiClient.post(
        '/notifications/read-all/',
        body: {},
        authenticated: true,
      );

      if (res.success) {
        _loadNotifications(silent: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Todas as notificações foram marcadas como lidas',
                style: GoogleFonts.inter(fontSize: 13),
              ),
              backgroundColor: _C.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Erro: $e');
    }
  }

  Future<void> _onNotificationTap(Map<String, dynamic> notif) async {
    if (_isNavigating) return;

    final id = notif['id']?.toString() ?? '';
    final type = notif['type']?.toString() ?? '';
    final isRead = notif['is_read'] == true;

    if (!isRead && id.isNotEmpty) {
      await _markAsRead(id);
    }

    String? tripId;
    final data = notif['data'];
    if (data is Map) {
      tripId = data['trip_id']?.toString();
    }

    if (tripId == null || tripId.isEmpty) return;

    switch (type) {
      case 'TRIP_ACCEPTED':
      case 'TRIP_ARRIVED':
      case 'TRIP_STARTED':
      case 'TRIP_COMPLETED':
        await _openTripTracking(tripId);
        break;
      case 'TRIP_CANCELLED':
        _showCancelledDialog(notif);
        break;
      default:
        break;
    }
  }

  Future<void> _openTripTracking(String tripId) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: _C.red),
        ),
      );
    }

    try {
      final res = await ApiClient.get('/trips/my/', authenticated: true);

      if (!mounted) return;
      if (mounted) Navigator.of(context).pop();

      if (!res.success) {
        _showError('Não foi possível carregar a viagem');
        setState(() => _isNavigating = false);
        return;
      }

      Map<String, dynamic>? trip;
      final raw = res.data;
      List<dynamic>? list;

      if (raw is List) {
        list = raw;
      } else if (raw is Map && raw['results'] is List) {
        list = raw['results'] as List;
      }

      if (list != null) {
        for (final item in list) {
          if (item is Map) {
            final m = Map<String, dynamic>.from(item);
            if (m['id']?.toString() == tripId) {
              trip = m;
              break;
            }
          }
        }
      }

      if (trip == null) {
        _showError('Viagem não encontrada no histórico');
        setState(() => _isNavigating = false);
        return;
      }

      final pickupLat =
          double.tryParse(trip['pickup_latitude']?.toString() ?? '');
      final pickupLng =
          double.tryParse(trip['pickup_longitude']?.toString() ?? '');
      final dropLat =
          double.tryParse(trip['dropoff_latitude']?.toString() ?? '');
      final dropLng =
          double.tryParse(trip['dropoff_longitude']?.toString() ?? '');

      if (pickupLat == null ||
          pickupLng == null ||
          dropLat == null ||
          dropLng == null) {
        _showError('Viagem sem coordenadas válidas');
        setState(() => _isNavigating = false);
        return;
      }

      final priceRaw = trip['price'];
      final priceKz = priceRaw is num
          ? priceRaw.round()
          : (double.tryParse(priceRaw?.toString() ?? '0')?.round() ?? 0);

      final distanceRaw = trip['distance_km'];
      final distanceKm = distanceRaw is num
          ? distanceRaw.toDouble()
          : double.tryParse(distanceRaw?.toString() ?? '0') ?? 0.0;

      final category = trip['category']?.toString() ?? 'ECONÓMICO';
      final categoryLabel =
          category[0].toUpperCase() + category.substring(1).toLowerCase();

      final etaMin = ((distanceKm / 30) * 60).ceil().clamp(1, 999);

      final destinationName =
          trip['dropoff_address']?.toString() ?? 'Destino';

      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => TripTrackingScreen(
              tripId: tripId,
              pickupLocation: LatLng(pickupLat, pickupLng),
              destinationLocation: LatLng(dropLat, dropLng),
              destinationName: destinationName,
              categoryLabel: categoryLabel,
              priceKz: priceKz,
              distanceKm: distanceKm,
              etaMin: etaMin,
            ),
          ),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      debugPrint('❌ Erro: $e');
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showError('Erro ao abrir a viagem');
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: _C.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCancelledDialog(Map<String, dynamic> notif) {
    final message = notif['message']?.toString() ?? 'A viagem foi cancelada.';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _C.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cancel_rounded,
                color: _C.danger,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Viagem cancelada',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _C.textStrong,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: _C.textMuted,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _C.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'TRIP_ACCEPTED':
        return Icons.check_circle_rounded;
      case 'TRIP_ARRIVED':
        return Icons.location_on_rounded;
      case 'TRIP_STARTED':
        return Icons.navigation_rounded;
      case 'TRIP_COMPLETED':
        return Icons.flag_rounded;
      case 'TRIP_CANCELLED':
        return Icons.cancel_rounded;
      case 'NEW_TRIP_AVAILABLE':
        return Icons.local_taxi_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'TRIP_ACCEPTED':
        return _C.blue;
      case 'TRIP_ARRIVED':
        return _C.warning;
      case 'TRIP_STARTED':
        return _C.success;
      case 'TRIP_COMPLETED':
        return _C.driver;
      case 'TRIP_CANCELLED':
        return _C.danger;
      case 'NEW_TRIP_AVAILABLE':
        return _C.red;
      default:
        return _C.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => n['is_read'] != true).length;

    return Scaffold(
      backgroundColor: _C.bgApp,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _C.bgCard,
                        shape: BoxShape.circle,
                        border: Border.all(color: _C.border),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: _C.textStrong,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notificações',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: _C.textStrong,
                          ),
                        ),
                        if (unread > 0)
                          Text(
                            '$unread não lida${unread > 1 ? "s" : ""}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _C.red,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (unread > 0)
                    TextButton(
                      onPressed: _markAllAsRead,
                      child: Text(
                        'Marcar todas',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _C.blue,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(color: _C.border, height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: _C.red,
                      ),
                    )
                  : _error != null
                      ? _buildError()
                      : _notifications.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              onRefresh: () => _loadNotifications(),
                              color: _C.red,
                              child: ListView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                itemCount: _notifications.length,
                                itemBuilder: (context, index) {
                                  return _buildNotificationItem(
                                    _notifications[index],
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notif) {
    final type = notif['type']?.toString() ?? 'SYSTEM';
    final title = notif['title']?.toString() ?? '';
    final message = notif['message']?.toString() ?? '';
    final timeAgo = notif['time_ago']?.toString() ?? '';
    final isRead = notif['is_read'] == true;

    final color = _colorForType(type);
    final icon = _iconForType(type);
    final isTripNotif = type.startsWith('TRIP_');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onNotificationTap(notif),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead ? _C.bgCard : color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isRead ? _C.border : color.withOpacity(0.3),
              width: isRead ? 1 : 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight:
                                  isRead ? FontWeight.w700 : FontWeight.w900,
                              color: _C.textStrong,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: _C.textMuted,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          timeAgo,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: _C.textSubtle,
                          ),
                        ),
                        if (isTripNotif) ...[
                          const Spacer(),
                          Text(
                            'Ver viagem',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: color,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: _C.bgSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: _C.textMuted,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sem notificações',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _C.textStrong,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'As tuas notificações vão aparecer aqui',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: _C.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: _C.danger, size: 48),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Erro',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _C.textStrong,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _loadNotifications(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}