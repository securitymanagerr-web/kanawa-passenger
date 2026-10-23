// KANAWA - Acompanhar viagem
// v1.3 — Ao concluir, chama /simulate/ no backend

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import 'chat_screen.dart';
import 'rating_screen.dart';

class _C {
  static const red = Color(0xFFE01818);
  static const redDark = Color(0xFFB91C1C);
  static const blue = Color(0xFF1E5FE0);
  static const blueDark = Color(0xFF0A4AD8);
  static const cyan = Color(0xFF00E5FF);
  static const green = Color(0xFF16A34A);
  static const greenSoft = Color(0xFFF0FDF4);
  static const amber = Color(0xFFD97706);
  static const textStrong = Color(0xFF18181B);
  static const textMuted = Color(0xFF71717A);
  static const textSubtle = Color(0xFFA1A1AA);
  static const bgApp = Color(0xFF0F0F12);
  static const bgCard = Color(0xFF1A1A1F);
  static const border = Color(0xFF27272A);
}

enum TripStatus { onTheWay, arrived, inTrip, completed }

class TripTrackingScreen extends StatefulWidget {
  final String? tripId;
  final LatLng pickupLocation;
  final LatLng destinationLocation;
  final String destinationName;
  final String categoryLabel;
  final int priceKz;
  final double distanceKm;
  final int etaMin;

  const TripTrackingScreen({
    super.key,
    this.tripId,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.destinationName,
    required this.categoryLabel,
    required this.priceKz,
    required this.distanceKm,
    required this.etaMin,
  });

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Timer? _tripTimer;
  TripStatus _status = TripStatus.onTheWay;
  bool _isCompletingOnBackend = false;
  bool _backendCompleted = false;

  final Map<String, dynamic> _driver = {
    'name': 'Carlos Silva',
    'rating': 4.8,
    'plate': 'LD-42-AA',
    'vehicle': 'Toyota Corolla (Prata)',
    'phone': '+244923111222',
  };

  late LatLng _driverPos;
  double _progress = 0.0;
  int _secondsElapsed = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _driverPos = LatLng(
      widget.pickupLocation.latitude + 0.005,
      widget.pickupLocation.longitude + 0.005,
    );

    _startTripSimulation();
  }

  @override
  void dispose() {
    _tripTimer?.cancel();
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _startTripSimulation() {
    _tripTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) return;

      setState(() {
        _secondsElapsed++;

        if (_status == TripStatus.onTheWay) {
          _progress = (_progress + 0.06).clamp(0.0, 1.0);
          _driverPos = _lerpLatLng(_driverPos, widget.pickupLocation, 0.15);
          if (_progress >= 1.0) {
            _status = TripStatus.arrived;
            _progress = 0.0;
          }
        } else if (_status == TripStatus.arrived) {
          if (_secondsElapsed > 0 && _secondsElapsed % 6 == 0) {
            _status = TripStatus.inTrip;
            _progress = 0.0;
          }
        } else if (_status == TripStatus.inTrip) {
          _progress = (_progress + 0.04).clamp(0.0, 1.0);
          _driverPos =
              _lerpLatLng(_driverPos, widget.destinationLocation, 0.12);
          if (_progress >= 1.0) {
            _status = TripStatus.completed;
            timer.cancel();
            _simulateTripOnBackend();
          }
        }
      });
    });
  }

  // ═══════════════════════════════════════════════════════
  // SIMULAR CICLO COMPLETO NO BACKEND
  // PENDING → ACCEPTED → ARRIVED → IN_PROGRESS → COMPLETED
  // ═══════════════════════════════════════════════════════
  Future<void> _simulateTripOnBackend() async {
    if (_isCompletingOnBackend || _backendCompleted) return;

    if (widget.tripId == null || widget.tripId!.startsWith('mock-')) {
      debugPrint('⚠️ Sem tripId real — não marca no backend');
      setState(() => _backendCompleted = true);
      return;
    }

    setState(() => _isCompletingOnBackend = true);

    try {
      debugPrint('═══════════════════════════════════════════');
      debugPrint('🔄 SIMULATE: ${widget.tripId}');
      debugPrint('═══════════════════════════════════════════');

      final response = await ApiClient.post(
        '/trips/${widget.tripId}/simulate/',
        body: {},
        authenticated: true,
      );

      debugPrint('═══════════════════════════════════════════');
      debugPrint('📥 SIMULATE RESULT');
      debugPrint('   success: ${response.success}');
      debugPrint('   statusCode: ${response.statusCode}');
      debugPrint('   data: ${response.data}');
      debugPrint('═══════════════════════════════════════════');

      if (response.success) {
        debugPrint('✅ Viagem simulada com sucesso');
        setState(() {
          _backendCompleted = true;
          _isCompletingOnBackend = false;
        });
      } else {
        debugPrint('⚠️ Falha: ${response.errorMessage}');
        setState(() {
          _backendCompleted = true;
          _isCompletingOnBackend = false;
        });
      }
    } catch (e, stack) {
      debugPrint('❌ EXCEÇÃO: $e');
      debugPrint('📍 Stack: $stack');
      if (mounted) {
        setState(() {
          _backendCompleted = true;
          _isCompletingOnBackend = false;
        });
      }
    }
  }

  LatLng _lerpLatLng(LatLng from, LatLng to, double t) {
    return LatLng(
      from.latitude + (to.latitude - from.latitude) * t,
      from.longitude + (to.longitude - from.longitude) * t,
    );
  }

  Future<void> _makePhoneCall() async {
    final phone =
        (_driver['phone'] as String).replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) _showSnack('Não foi possível abrir o discador');
    } catch (e) {
      debugPrint('Erro ao ligar: $e');
      if (mounted) _showSnack('Erro ao ligar');
    }
  }

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          driverName: _driver['name'] as String,
          driverPhone: _driver['phone'] as String,
          driverPlate: _driver['plate'] as String,
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: _C.blueDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _openRating() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RatingScreen(
          tripId: widget.tripId,
          driverName: _driver['name'] as String,
          driverPlate: _driver['plate'] as String,
          destinationName: widget.destinationName,
          priceKz: widget.priceKz,
        ),
      ),
    );
  }

  String _getStatusTitle() {
    switch (_status) {
      case TripStatus.onTheWay:
        return 'Motorista a caminho';
      case TripStatus.arrived:
        return 'Motorista chegou';
      case TripStatus.inTrip:
        return 'Em viagem';
      case TripStatus.completed:
        return 'Viagem concluída';
    }
  }

  String _getStatusSubtitle() {
    switch (_status) {
      case TripStatus.onTheWay:
        return 'A caminho do ponto de recolha';
      case TripStatus.arrived:
        return 'Aguarda no ponto de recolha';
      case TripStatus.inTrip:
        return 'A caminho do destino';
      case TripStatus.completed:
        return 'Chegaste ao destino';
    }
  }

  Color _getStatusColor() {
    switch (_status) {
      case TripStatus.onTheWay:
        return _C.amber;
      case TripStatus.arrived:
        return _C.green;
      case TripStatus.inTrip:
        return _C.blue;
      case TripStatus.completed:
        return _C.green;
    }
  }

  IconData _getStatusIcon() {
    switch (_status) {
      case TripStatus.onTheWay:
        return Icons.directions_car_rounded;
      case TripStatus.arrived:
        return Icons.location_on_rounded;
      case TripStatus.inTrip:
        return Icons.navigation_rounded;
      case TripStatus.completed:
        return Icons.check_circle_rounded;
    }
  }

  Set<Marker> _buildMarkers() {
    return {
      Marker(
        markerId: const MarkerId('pickup'),
        position: widget.pickupLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Recolha'),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destinationLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: widget.destinationName),
      ),
      if (_status != TripStatus.completed)
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverPos,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(title: _driver['name']),
          zIndex: 100,
        ),
    };
  }

  Set<Polyline> _buildPolylines() {
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [widget.pickupLocation, widget.destinationLocation],
        color: _C.blue,
        width: 4,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bgApp,
      body: SafeArea(
        child: Column(
          children: [
            _buildMap(),
            _buildBottomSheet(),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return SizedBox(
      height: 340,
      child: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.pickupLocation,
                zoom: 14,
              ),
              onMapCreated: (c) {
                _mapController = c;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final bounds = LatLngBounds(
                    southwest: LatLng(
                      math.min(widget.pickupLocation.latitude,
                          widget.destinationLocation.latitude),
                      math.min(widget.pickupLocation.longitude,
                          widget.destinationLocation.longitude),
                    ),
                    northeast: LatLng(
                      math.max(widget.pickupLocation.latitude,
                          widget.destinationLocation.latitude),
                      math.max(widget.pickupLocation.longitude,
                          widget.destinationLocation.longitude),
                    ),
                  );
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngBounds(bounds, 80),
                  );
                });
              },
              markers: _buildMarkers(),
              polylines: _buildPolylines(),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: _C.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _getStatusColor().withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getStatusIcon(),
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStatusTitle(),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _getStatusSubtitle(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _C.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_status != TripStatus.completed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _status == TripStatus.inTrip
                            ? '${((1 - _progress) * widget.etaMin).ceil()} min'
                            : '${((1 - _progress) * 5).ceil()} min',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _getStatusColor(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          color: _C.bgApp,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: _status == TripStatus.completed
              ? _buildCompleted()
              : _buildInProgress(),
        ),
      ),
    );
  }

  Widget _buildCompleted() {
    return Column(
      children: [
        const SizedBox(height: 20),
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
          'Viagem concluída!',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isCompletingOnBackend
              ? 'A sincronizar com o servidor...'
              : 'Chegaste ao destino em segurança',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: _C.textMuted,
          ),
        ),
        if (_isCompletingOnBackend) ...[
          const SizedBox(height: 16),
          const CircularProgressIndicator(color: _C.green, strokeWidth: 2.5),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.border),
          ),
          child: Column(
            children: [
              _infoRow(Icons.location_on_rounded, _C.green, 'Recolha',
                  'Localização inicial'),
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
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${widget.priceKz} Kz',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _C.red,
                          ),
                        ),
                        Text(
                          'Total pago',
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
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isCompletingOnBackend ? null : _openRating,
            icon: const Icon(Icons.star_rounded, size: 22),
            label: Text(
              'AVALIAR VIAGEM',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.amber,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _C.border,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInProgress() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.border),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: _C.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _driver['name'],
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.star_rounded,
                            size: 13, color: _C.amber),
                        Text(
                          ' ${_driver['rating']}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _driver['vehicle'],
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: _C.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _C.bgApp,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: _C.border),
                      ),
                      child: Text(
                        _driver['plate'],
                        style: GoogleFonts.inter(
                          fontSize: 10,
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
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _actionButton(
                icon: Icons.phone_rounded,
                label: 'Ligar',
                color: _C.green,
                onTap: _makePhoneCall,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionButton(
                icon: Icons.chat_bubble_rounded,
                label: 'Chat',
                color: _C.blue,
                onTap: _openChat,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionButton(
                icon: Icons.share_rounded,
                label: 'Partilhar',
                color: _C.amber,
                onTap: () {
                  _showSnack('Link da viagem copiado!');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.border),
          ),
          child: Column(
            children: [
              _infoRow(Icons.location_on_rounded, _C.green, 'Recolha',
                  'Localização inicial'),
              const SizedBox(height: 10),
              _infoRow(Icons.flag_rounded, _C.red, 'Destino',
                  widget.destinationName),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}