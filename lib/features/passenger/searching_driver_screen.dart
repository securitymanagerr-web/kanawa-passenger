// KANAWA - A procurar motorista (Passageiro)
// v2.5 — Bairro + município + fallback local prioritário

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import 'chat_screen.dart';
import 'trip_tracking_screen.dart';

class _C {
  static const red = Color(0xFFE01818);
  static const redDark = Color(0xFFB91C1C);
  static const blue = Color(0xFF1E5FE0);
  static const blueDark = Color(0xFF0A4AD8);
  static const cyan = Color(0xFF00E5FF);
  static const green = Color(0xFF16A34A);
  static const amber = Color(0xFFD97706);
  static const textStrong = Color(0xFF18181B);
  static const textMuted = Color(0xFF71717A);
  static const textSubtle = Color(0xFFA1A1AA);
  static const bgApp = Color(0xFF0F0F12);
  static const bgCard = Color(0xFF1A1A1F);
  static const border = Color(0xFF27272A);
}

// ═══════════════════════════════════════════════════════════
// BAIRROS LOCAIS DE SAURIMO (fonte primária)
// ═══════════════════════════════════════════════════════════
class _LocalArea {
  final String name;
  final double lat;
  final double lng;

  const _LocalArea({
    required this.name,
    required this.lat,
    required this.lng,
  });
}

const _localAreas = <_LocalArea>[
  _LocalArea(name: 'Bairro Txizainga 1', lat: -9.6568, lng: 20.4088),
  _LocalArea(name: 'Bairro Txizainga 2', lat: -9.6683, lng: 20.4155),
  _LocalArea(name: 'Bairro Sassamba', lat: -9.6599, lng: 20.3923),
  _LocalArea(name: 'Bairro 11 de Novembro', lat: -9.6573, lng: 20.3948),
  _LocalArea(name: 'Bairro Agostinho Neto', lat: -9.6548, lng: 20.3846),
  _LocalArea(name: 'Bairro Luavur', lat: -9.6496, lng: 20.3807),
  _LocalArea(name: 'Bairro Verde', lat: -9.6617, lng: 20.3988),
  _LocalArea(name: 'Bairro Candembe', lat: -9.6614, lng: 20.3628),
  _LocalArea(name: 'Bairro Juventude', lat: -9.6623, lng: 20.4422),
  _LocalArea(name: 'Bairro Sambukila-A', lat: -9.6731, lng: 20.3905),
  _LocalArea(name: 'Bairro Cacanda', lat: -9.6480, lng: 20.3850),
  _LocalArea(name: 'Bairro Cidade Alta', lat: -9.6720, lng: 20.4010),
  _LocalArea(name: 'Bairro Mukonda', lat: -9.6600, lng: 20.4100),
  _LocalArea(name: 'Bairro Sagrada Esperança', lat: -9.6650, lng: 20.3800),
  _LocalArea(name: 'Bairro Chifunga', lat: -9.6520, lng: 20.3950),
  _LocalArea(name: 'Bairro Mussende', lat: -9.6700, lng: 20.3780),
  _LocalArea(name: 'Bairro Camalundo', lat: -9.6550, lng: 20.4150),
  _LocalArea(name: 'Centro, Saurimo', lat: -9.6608, lng: 20.3917),
  _LocalArea(name: 'Mona Quimbundo', lat: -9.6650, lng: 20.3850),
  _LocalArea(name: 'Cassengo', lat: -9.6770, lng: 20.4098),
  _LocalArea(name: 'Muangueji', lat: -9.6062, lng: 20.4179),
];

class SearchingDriverScreen extends StatefulWidget {
  final LatLng pickupLocation;
  final LatLng destinationLocation;
  final String destinationName;
  final String categoryId;
  final String categoryLabel;
  final int priceKz;
  final int etaMin;
  final double distanceKm;

  const SearchingDriverScreen({
    super.key,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.destinationName,
    required this.categoryId,
    required this.categoryLabel,
    required this.priceKz,
    required this.etaMin,
    required this.distanceKm,
  });

  @override
  State<SearchingDriverScreen> createState() => _SearchingDriverScreenState();
}

class _SearchingDriverScreenState extends State<SearchingDriverScreen>
    with TickerProviderStateMixin {
  late AnimationController _radarController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  GoogleMapController? _mapController;
  Timer? _pollTimer;
  int _secondsElapsed = 0;
  bool _isCreatingTrip = false;
  String? _tripId;
  String? _resolvedAddress;

  Map<String, dynamic>? _acceptedDriver;
  String? _tripStatus;

  @override
  void initState() {
    super.initState();

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _createTripOnBackend();
  }

  @override
  void dispose() {
    _radarController.dispose();
    _pulseController.dispose();
    _pollTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════
  // RESOLVER ENDEREÇO (bairro + município)
  // ═══════════════════════════════════════════════════════
  Future<String> _resolveAddress(double lat, double lng) async {
    // ─────────────────────────────────────────────
    // NÍVEL 1: Lista local (SEMPRE prioritária em Saurimo)
    // ─────────────────────────────────────────────
    final nearest = _findNearestArea(lat, lng);
    if (nearest != null) {
      // Adiciona o município ao bairro
      final result = '${nearest.name}, Saurimo';
      debugPrint('✅ [1/2] Bairro via lista local: $result');
      return result;
    }

    // ─────────────────────────────────────────────
    // NÍVEL 2: Nominatim (fora de Saurimo)
    // ─────────────────────────────────────────────
    try {
      debugPrint('🔍 [2/2] A tentar Nominatim...');
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lng'
        '&format=json'
        '&zoom=16'
        '&addressdetails=1',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'KanawaApp/1.0'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final address = data['address'] as Map<String, dynamic>? ?? {};

        final suburb = address['suburb'] ??
            address['neighbourhood'] ??
            address['quarter'] ??
            address['hamlet'] ??
            '';
        final city = address['city'] ??
            address['town'] ??
            address['municipality'] ??
            address['village'] ??
            '';
        final state = address['state'] ?? '';

        // Monta "Bairro, Cidade, Província"
        final parts = <String>[];
        if (suburb.isNotEmpty) parts.add(suburb);
        if (city.isNotEmpty) parts.add(city);
        if (state.isNotEmpty) parts.add(state);

        if (parts.isNotEmpty) {
          final result = parts.join(', ');
          debugPrint('✅ [2/2] Nominatim: $result');
          return result;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [2/2] Nominatim falhou: $e');
    }

    debugPrint('⚠️ Todos os métodos falharam. Fallback.');
    return 'Saurimo, Lunda Sul';
  }

  _LocalArea? _findNearestArea(double lat, double lng) {
    if (_localAreas.isEmpty) return null;

    _LocalArea? nearest;
    double minDist = double.infinity;

    for (final area in _localAreas) {
      final d = _haversineKm(lat, lng, area.lat, area.lng);
      if (d < minDist) {
        minDist = d;
        nearest = area;
      }
    }

    if (minDist > 15.0) return null;
    return nearest;
  }

  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final p1 = lat1 * math.pi / 180;
    final p2 = lat2 * math.pi / 180;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(p1) * math.cos(p2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return R * 2 * math.asin(math.sqrt(h));
  }

  // ═══════════════════════════════════════════════════════
  // CRIAR VIAGEM
  // ═══════════════════════════════════════════════════════
  Future<void> _createTripOnBackend() async {
    if (_isCreatingTrip) return;
    setState(() => _isCreatingTrip = true);

    try {
      debugPrint('═══════════════════════════════════════════');
      debugPrint('🟢 A criar viagem...');

      final pickupAddress = await _resolveAddress(
        widget.pickupLocation.latitude,
        widget.pickupLocation.longitude,
      );

      _resolvedAddress = pickupAddress;
      debugPrint('📤 pickup_address FINAL: "$pickupAddress"');
      debugPrint('═══════════════════════════════════════════');

      final body = {
        'pickup_latitude': widget.pickupLocation.latitude.toStringAsFixed(7),
        'pickup_longitude': widget.pickupLocation.longitude.toStringAsFixed(7),
        'pickup_address': pickupAddress,
        'dropoff_latitude':
            widget.destinationLocation.latitude.toStringAsFixed(7),
        'dropoff_longitude':
            widget.destinationLocation.longitude.toStringAsFixed(7),
        'dropoff_address': widget.destinationName,
        'category': widget.categoryId,
        'payment_method': 'CASH',
      };

      final response = await ApiClient.post(
        '/trips/request/',
        body: body,
        authenticated: true,
      );

      if (!mounted) return;

      if (response.success && response.data is Map) {
        final data = response.data as Map;
        _tripId = data['id']?.toString();
        debugPrint('✅ Viagem criada: $_tripId');
        setState(() {
          _isCreatingTrip = false;
          _tripStatus = 'PENDING';
        });
        _startPolling();
      } else {
        debugPrint('❌ Falha: ${response.errorMessage}');
        setState(() => _isCreatingTrip = false);
        _showError('Não foi possível criar a viagem.');
      }
    } catch (e) {
      debugPrint('❌ Exceção: $e');
      if (mounted) {
        setState(() => _isCreatingTrip = false);
        _showError('Erro de ligação.');
      }
    }
  }

  // ═══════════════════════════════════════════════════════
  // POLLING
  // ═══════════════════════════════════════════════════════
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      setState(() => _secondsElapsed += 3);
      _checkTripStatus();
    });
  }

  Future<void> _checkTripStatus() async {
    if (_tripId == null) return;

    try {
      final response = await ApiClient.get(
        '/trips/$_tripId/poll/',
        authenticated: true,
      );

      if (!mounted) return;

      if (response.success && response.data is Map) {
        final data = response.data as Map;
        final status = data['status']?.toString() ?? '';

        debugPrint('📥 Poll: $status');

        if (status == 'ACCEPTED' ||
            status == 'ARRIVED' ||
            status == 'IN_PROGRESS') {
          final driver = data['driver'] as Map?;

          if (driver != null && _acceptedDriver == null) {
            _pollTimer?.cancel();
            setState(() {
              _tripStatus = status;
              _acceptedDriver = {
                'name': driver['full_name']?.toString() ?? 'Motorista',
                'phone': driver['phone']?.toString() ?? '—',
                'plate': driver['vehicle_plate']?.toString() ?? '—',
                'vehicle': driver['vehicle_model']?.toString() ?? '—',
                'rating': 4.8,
                'eta': 4,
              };
            });
          }
        } else if (status == 'CANCELLED') {
          _pollTimer?.cancel();
          _showError('A viagem foi cancelada.');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Erro polling: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: _C.redDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // AÇÕES
  // ═══════════════════════════════════════════════════════
  Future<void> _makePhoneCall() async {
    if (_acceptedDriver == null) return;
    final phone = (_acceptedDriver!['phone'] as String)
        .replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) _showError('Não foi possível abrir o discador');
    } catch (e) {
      debugPrint('Erro ao ligar: $e');
    }
  }

  void _openChat() {
    if (_acceptedDriver == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          driverName: _acceptedDriver!['name'] as String,
          driverPhone: _acceptedDriver!['phone'] as String,
          driverPlate: _acceptedDriver!['plate'] as String,
        ),
      ),
    );
  }

  void _continueTrip() {
    if (_tripId == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TripTrackingScreen(
          tripId: _tripId,
          pickupLocation: widget.pickupLocation,
          destinationLocation: widget.destinationLocation,
          destinationName: widget.destinationName,
          categoryLabel: widget.categoryLabel,
          priceKz: widget.priceKz,
          distanceKm: widget.distanceKm,
          etaMin: widget.etaMin,
        ),
      ),
    );
  }

  void _cancelTrip() async {
    if (_tripId != null) {
      try {
        await ApiClient.post(
          '/trips/$_tripId/cancel/',
          body: {'reason': 'Cancelada pelo passageiro'},
          authenticated: true,
        );
      } catch (e) {
        debugPrint('Erro ao cancelar: $e');
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  String _getElapsedText() {
    final min = _secondsElapsed ~/ 60;
    final sec = _secondsElapsed % 60;
    if (min > 0) return '${min}min ${sec}s';
    return '${sec}s';
  }

  // ═══════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bgApp,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: widget.pickupLocation,
                        zoom: 14,
                      ),
                      onMapCreated: (c) => _mapController = c,
                      markers: {
                        Marker(
                          markerId: const MarkerId('pickup'),
                          position: widget.pickupLocation,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure,
                          ),
                        ),
                        Marker(
                          markerId: const MarkerId('destination'),
                          position: widget.destinationLocation,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                        ),
                      },
                      polylines: {
                        Polyline(
                          polylineId: const PolylineId('route'),
                          points: [
                            widget.pickupLocation,
                            widget.destinationLocation,
                          ],
                          color: _C.blue,
                          width: 5,
                        ),
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      compassEnabled: false,
                      mapToolbarEnabled: false,
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 16,
                    child: GestureDetector(
                      onTap: _cancelTrip,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 14,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: _C.textStrong,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _acceptedDriver != null
                    ? _buildDriverFound()
                    : _buildSearching(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearching() {
    return Column(
      children: [
        const SizedBox(height: 20),
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _radarController,
                builder: (context, _) {
                  return CustomPaint(
                    size: const Size(200, 200),
                    painter: _RadarPainter(_radarController.value),
                  );
                },
              ),
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _C.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _C.red.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_taxi_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          _isCreatingTrip ? 'A preparar viagem...' : 'A procurar motorista...',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.categoryLabel,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _C.cyan,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Há ${_getElapsedText()}',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _C.textMuted,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.border),
          ),
          child: Column(
            children: [
              _infoRow(
                Icons.location_on_rounded,
                _C.green,
                'Recolha',
                _resolvedAddress ?? 'A obter localização...',
              ),
              const SizedBox(height: 10),
              _infoRow(Icons.flag_rounded, _C.red, 'Destino',
                  widget.destinationName),
              const SizedBox(height: 14),
              Divider(color: _C.border, height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.distanceKm.toStringAsFixed(1)} km',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Distância',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: _C.textSubtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.etaMin} min',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Tempo',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: _C.textSubtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${widget.priceKz} Kz',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _C.red,
                          ),
                        ),
                        Text(
                          'Preço',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: _C.textSubtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: _cancelTrip,
          child: Text(
            'Cancelar pedido',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _C.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDriverFound() {
    final driver = _acceptedDriver!;
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _C.green.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: _C.green,
            size: 50,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Motorista encontrado!',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'A caminho de ti',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _C.textMuted,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.green.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: _C.green,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (driver['name'] as String).isNotEmpty
                            ? (driver['name'] as String)[0].toUpperCase()
                            : 'M',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                driver['name'],
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.star_rounded,
                                size: 14, color: _C.amber),
                            Text(
                              ' ${driver['rating']}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          driver['vehicle'],
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _C.textMuted,
                          ),
                        ),
                        const SizedBox(height: 3),
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
                            driver['plate'],
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _C.bgApp,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.phone_rounded,
                      color: _C.textMuted,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      driver['phone'],
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _C.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: _C.green,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Chega em ${driver['eta']} min',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _C.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _makePhoneCall,
                  icon: const Icon(Icons.phone_rounded, size: 20),
                  label: Text(
                    'LIGAR',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _openChat,
                  icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                  label: Text(
                    'CHAT',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _continueTrip,
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.navigation_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'ACOMPANHAR VIAGEM',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _cancelTrip,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _C.border),
              foregroundColor: _C.textMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Cancelar viagem',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double progress;
  _RadarPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    for (int i = 0; i < 3; i++) {
      final offset = (progress + i / 3) % 1.0;
      final radius = offset * maxRadius;
      final opacity = (1.0 - offset).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = const Color(0xFFE01818).withOpacity(opacity * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.progress != progress;
}