// KANAWA - Histórico de viagens
// v1.3 — Só viagens reais do backend (sem mock)
//         + debugPrint para diagnóstico

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';

class _C {
  static const red = Color(0xFFE01818);
  static const redDark = Color(0xFFB91C1C);
  static const blue = Color(0xFF1E5FE0);
  static const blueDark = Color(0xFF0A4AD8);
  static const cyan = Color(0xFF00E5FF);
  static const green = Color(0xFF16A34A);
  static const amber = Color(0xFFD97706);
  static const purple = Color(0xFF7C3AED);
  static const textStrong = Color(0xFF18181B);
  static const textMuted = Color(0xFF71717A);
  static const textSubtle = Color(0xFFA1A1AA);
  static const bgApp = Color(0xFF0F0F12);
  static const bgCard = Color(0xFF1A1A1F);
  static const border = Color(0xFF27272A);
}

enum HistoryFilter { all, today, week, month }

class TripHistory {
  final String id;
  final String destination;
  final String origin;
  final String category;
  final DateTime date;
  final double distanceKm;
  final int durationMin;
  final int priceKz;
  final int rating;
  final String status;
  final bool isMoto;

  TripHistory({
    required this.id,
    required this.destination,
    required this.origin,
    required this.category,
    required this.date,
    required this.distanceKm,
    required this.durationMin,
    required this.priceKz,
    required this.rating,
    required this.status,
    required this.isMoto,
  });

  factory TripHistory.fromBackend(Map<String, dynamic> json) {
    try {
      final category = (json['category'] ?? '').toString();
      final status = (json['status'] ?? '').toString();
      final ratingRaw = json['rating'];
      final int rating = ratingRaw is int ? ratingRaw : 0;

      DateTime date;
      try {
        final rawDate = json['requested_at'] ?? json['completed_at'];
        date = DateTime.parse(rawDate.toString()).toLocal();
      } catch (_) {
        date = DateTime.now();
      }

      final distance = double.tryParse(
            (json['distance_km'] ?? '0').toString(),
          ) ??
          0.0;

      final duration = (json['duration_minutes'] as num?)?.toInt() ?? 0;

      final price = double.tryParse(
            (json['price'] ?? '0').toString(),
          )?.round() ??
          0;

      String catLabel;
      if (category == 'MOTA') {
        catLabel = 'Mota';
      } else if (category == 'ECONOMIC') {
        catLabel = 'Económico';
      } else if (category == 'COMFORT') {
        catLabel = 'Conforto';
      } else if (category == 'PREMIUM') {
        catLabel = 'Premium';
      } else {
        catLabel = category;
      }

      return TripHistory(
        id: json['id']?.toString() ?? '',
        destination:
            (json['dropoff_address'] ?? 'Destino').toString().trim().isEmpty
                ? 'Destino'
                : (json['dropoff_address'] ?? 'Destino').toString(),
        origin:
            (json['pickup_address'] ?? 'Recolha').toString().trim().isEmpty
                ? 'Recolha'
                : (json['pickup_address'] ?? 'Recolha').toString(),
        category: catLabel,
        date: date,
        distanceKm: distance,
        durationMin: duration,
        priceKz: price,
        rating: rating,
        status: status == 'CANCELLED' ? 'cancelled' : 'completed',
        isMoto: category == 'MOTA',
      );
    } catch (e) {
      debugPrint('❌ Erro ao processar viagem: $e');
      debugPrint('   JSON: $json');
      return TripHistory(
        id: 'error',
        destination: 'Erro',
        origin: '—',
        category: '—',
        date: DateTime.now(),
        distanceKm: 0,
        durationMin: 0,
        priceKz: 0,
        rating: 0,
        status: 'completed',
        isMoto: false,
      );
    }
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryFilter _filter = HistoryFilter.all;
  List<TripHistory> _trips = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('═══════════════════════════════════════════');
      debugPrint('📥 GET /trips/my/');
      debugPrint('═══════════════════════════════════════════');

      final response = await ApiClient.get(
        '/trips/my/',
        authenticated: true,
      );

      debugPrint('📥 RESPOSTA /trips/my/');
      debugPrint('   success: ${response.success}');
      debugPrint('   statusCode: ${response.statusCode}');
      debugPrint('   data type: ${response.data.runtimeType}');
      debugPrint('   data: ${response.data}');
      debugPrint('═══════════════════════════════════════════');

      if (!mounted) return;

      if (!response.success) {
        setState(() {
          _trips = [];
          _isLoading = false;
          _errorMessage = response.errorMessage;
        });
        return;
      }

      final data = response.data;

      // Caso 1: Lista direta
      if (data is List) {
        final trips = data
            .whereType<Map>()
            .map((j) => TripHistory.fromBackend(
                  Map<String, dynamic>.from(j),
                ))
            .where((t) => t.id != 'error')
            .toList();

        setState(() {
          _trips = trips;
          _isLoading = false;
        });
        return;
      }

      // Caso 2: Map com paginação (results)
      if (data is Map && data['results'] is List) {
        final trips = (data['results'] as List)
            .whereType<Map>()
            .map((j) => TripHistory.fromBackend(
                  Map<String, dynamic>.from(j),
                ))
            .where((t) => t.id != 'error')
            .toList();

        setState(() {
          _trips = trips;
          _isLoading = false;
        });
        return;
      }

      // Formato inesperado
      debugPrint('⚠️ Formato de resposta inesperado');
      setState(() {
        _trips = [];
        _isLoading = false;
        _errorMessage = 'Formato de resposta inesperado';
      });
    } catch (e, stack) {
      debugPrint('❌ Erro ao carregar viagens: $e');
      debugPrint('📍 Stack: $stack');
      if (mounted) {
        setState(() {
          _trips = [];
          _isLoading = false;
          _errorMessage = 'Erro: $e';
        });
      }
    }
  }

  List<TripHistory> get _filteredTrips {
    final now = DateTime.now();
    switch (_filter) {
      case HistoryFilter.all:
        return _trips;
      case HistoryFilter.today:
        return _trips
            .where((t) =>
                t.date.year == now.year &&
                t.date.month == now.month &&
                t.date.day == now.day)
            .toList();
      case HistoryFilter.week:
        return _trips
            .where((t) => now.difference(t.date).inDays <= 7)
            .toList();
      case HistoryFilter.month:
        return _trips
            .where((t) => now.difference(t.date).inDays <= 30)
            .toList();
    }
  }

  int get _totalTrips => _trips.where((t) => t.status == 'completed').length;
  int get _totalSpent => _trips
      .where((t) => t.status == 'completed')
      .fold(0, (s, t) => s + t.priceKz);
  double get _totalKm => _trips
      .where((t) => t.status == 'completed')
      .fold(0.0, (s, t) => s + t.distanceKm);
  double get _avgRating {
    final rated =
        _trips.where((t) => t.rating > 0 && t.status == 'completed').toList();
    if (rated.isEmpty) return 0;
    final sum = rated.fold(0, (s, t) => s + t.rating);
    return sum / rated.length;
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Há ${diff.inHours}h';
    if (diff.inDays == 1) {
      return 'Ontem · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) return 'Há ${diff.inDays} dias';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatKz(int value) {
    if (value >= 1000) {
      final k = value ~/ 1000;
      final rest = value % 1000;
      return '$k.${rest.toString().padLeft(3, '0')} Kz';
    }
    return '$value Kz';
  }

  void _showTripDetails(TripHistory trip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TripDetailsSheet(trip: trip),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bgApp,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _C.red),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStats(),
                          const SizedBox(height: 24),
                          _buildFilters(),
                          const SizedBox(height: 16),
                          _buildTripList(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                color: Colors.white,
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
                  'Histórico',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _isLoading
                      ? 'A carregar...'
                      : '${_trips.length} viagem(ns)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _C.textMuted,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _loadTrips,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _C.bgCard,
                shape: BoxShape.circle,
                border: Border.all(color: _C.border),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_C.blue, _C.blueDark]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _statItem(
                icon: Icons.local_taxi_rounded,
                value: '$_totalTrips',
                label: 'Viagens',
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.2),
              ),
              _statItem(
                icon: Icons.payments_rounded,
                value: _formatKz(_totalSpent),
                label: 'Gasto total',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.15), height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              _statItem(
                icon: Icons.route_rounded,
                value: '${_totalKm.toStringAsFixed(1)} km',
                label: 'Distância',
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.2),
              ),
              _statItem(
                icon: Icons.star_rounded,
                value: _avgRating > 0 ? _avgRating.toStringAsFixed(1) : '—',
                label: 'Avaliação média',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.85), size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final labels = {
      HistoryFilter.all: 'Todas',
      HistoryFilter.today: 'Hoje',
      HistoryFilter.week: 'Semana',
      HistoryFilter.month: 'Mês',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: HistoryFilter.values.map((f) {
          final selected = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected ? _C.red : _C.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? _C.red : _C.border,
                  ),
                ),
                child: Text(
                  labels[f]!,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : _C.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTripList() {
    final trips = _filteredTrips;

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (trips.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: trips
          .map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TripCard(
                  trip: t,
                  formattedDate: _formatDate(t.date),
                  formattedPrice: _formatKz(t.priceKz),
                  onTap: () => _showTripDetails(t),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _C.bgCard,
              shape: BoxShape.circle,
              border: Border.all(color: _C.red.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: _C.red,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Erro ao carregar',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage ?? 'Tenta novamente',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _C.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadTrips,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              'Tentar novamente',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _C.bgCard,
              shape: BoxShape.circle,
              border: Border.all(color: _C.border),
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 48,
              color: _C.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Sem viagens',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'As tuas viagens vão aparecer aqui',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _C.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CARD DE VIAGEM
// ═══════════════════════════════════════════════════════════
class _TripCard extends StatelessWidget {
  final TripHistory trip;
  final String formattedDate;
  final String formattedPrice;
  final VoidCallback onTap;

  const _TripCard({
    required this.trip,
    required this.formattedDate,
    required this.formattedPrice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCancelled = trip.status == 'cancelled';
    final color = isCancelled ? _C.red : _C.green;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    trip.isMoto
                        ? Icons.two_wheeler_rounded
                        : Icons.directions_car_rounded,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.destination,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            formattedDate,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _C.textMuted,
                            ),
                          ),
                          if (isCancelled) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: _C.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Cancelada',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: _C.red,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formattedPrice,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isCancelled ? _C.textMuted : Colors.white,
                        decoration:
                            isCancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (trip.rating > 0) ...[
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < trip.rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 11,
                            color: i < trip.rating ? _C.amber : _C.textSubtle,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: _C.border, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.route_rounded,
                  size: 13,
                  color: _C.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${trip.distanceKm.toStringAsFixed(1)} km',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _C.textMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.access_time_rounded,
                  size: 13,
                  color: _C.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${trip.durationMin} min',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _C.textMuted,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _C.bgApp,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _C.border),
                  ),
                  child: Text(
                    trip.category,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: _C.textMuted,
                    ),
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
// BOTTOM SHEET DE DETALHES
// ═══════════════════════════════════════════════════════════
class _TripDetailsSheet extends StatelessWidget {
  final TripHistory trip;

  const _TripDetailsSheet({required this.trip});

  @override
  Widget build(BuildContext context) {
    final isCancelled = trip.status == 'cancelled';

    return Container(
      decoration: const BoxDecoration(
        color: _C.bgApp,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _C.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color:
                          (isCancelled ? _C.red : _C.green).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      trip.isMoto
                          ? Icons.two_wheeler_rounded
                          : Icons.directions_car_rounded,
                      color: isCancelled ? _C.red : _C.green,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.destination,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isCancelled ? 'Viagem cancelada' : 'Viagem concluída',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isCancelled ? _C.red : _C.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _C.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _C.border),
                ),
                child: Column(
                  children: [
                    _routeLine(_C.green, 'Recolha', trip.origin),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 2,
                            height: 16,
                            color: _C.border,
                            margin: const EdgeInsets.only(left: 6),
                          ),
                        ],
                      ),
                    ),
                    _routeLine(_C.red, 'Destino', trip.destination),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _C.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _C.border),
                ),
                child: Column(
                  children: [
                    _detailRow(
                        Icons.category_rounded, 'Categoria', trip.category),
                    const SizedBox(height: 10),
                    _detailRow(Icons.route_rounded, 'Distância',
                        '${trip.distanceKm.toStringAsFixed(1)} km'),
                    const SizedBox(height: 10),
                    _detailRow(Icons.access_time_rounded, 'Duração',
                        '${trip.durationMin} min'),
                    const SizedBox(height: 10),
                    _detailRow(
                      Icons.calendar_today_rounded,
                      'Data',
                      '${trip.date.day.toString().padLeft(2, '0')}/${trip.date.month.toString().padLeft(2, '0')}/${trip.date.year}',
                    ),
                    const SizedBox(height: 10),
                    _detailRow(
                      Icons.payments_rounded,
                      'Preço',
                      '${trip.priceKz} Kz',
                      valueColor: _C.red,
                      valueWeight: FontWeight.w800,
                    ),
                  ],
                ),
              ),
              if (trip.rating > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _C.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _C.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: _C.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'A tua avaliação',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _C.textMuted,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < trip.rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 18,
                            color: i < trip.rating ? _C.amber : _C.textSubtle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _C.border),
                    foregroundColor: _C.textMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Fechar',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _routeLine(Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: _C.textSubtle,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    FontWeight? valueWeight,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _C.textMuted),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: _C.textMuted,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: valueWeight ?? FontWeight.w700,
            color: valueColor ?? Colors.white,
          ),
        ),
      ],
    );
  }
}