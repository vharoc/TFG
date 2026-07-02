import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/mensaje.dart';
import '../models/poi_sugerido.dart';
import '../models/ruta_result.dart';
import '../theme/theme.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/ruta/poi_response_overlay.dart';
import '../widgets/ruta/ruta_bottom_panel.dart';
import '../widgets/ruta/stop_marker.dart';

class RutaNavegacionScreen extends StatefulWidget {
  const RutaNavegacionScreen({super.key});

  @override
  State<RutaNavegacionScreen> createState() => _RutaNavegacionScreenState();
}

class _RutaNavegacionScreenState extends State<RutaNavegacionScreen> {
  final MapController _mapController = MapController();
  final ImagePicker _picker = ImagePicker();
  StreamSubscription<Position>? _locationSub;
  Position? _userPosition;
  bool _followUser = false;
  bool _cerrando = false;

  bool _showPoiOverlay = false;
  bool _poiQueryPending = false;
  String? _poiOverlayText;
  int _lastBotMessageCount = 0;
  int _lastParadaActual = -1;

  @override
  void initState() {
    super.initState();
    _startLocationStream();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<HomeViewModel>();
      final count = vm.messages
          .where((m) => m.role == MensajeRole.bot && m.tipo == MensajeTipo.texto)
          .length;
      setState(() {
        _lastBotMessageCount = count;
        _lastParadaActual = vm.rutaState?.paradaActual ?? 0;
      });
      _centerOnCurrentStop();
    });
  }

  void _startLocationStream() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
    _locationSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(
      (pos) {
        if (!mounted) return;
        setState(() => _userPosition = pos);
        if (_followUser) {
          _mapController.move(
            LatLng(pos.latitude, pos.longitude),
            _mapController.camera.zoom,
          );
        }
      },
      onError: (_) {
        // GPS no disponible: el punto azul no aparece
      },
    );
  }

  void _centerOnCurrentStop() {
    final parada = context.read<HomeViewModel>().rutaState?.paradaActualObj;
    if (parada == null || !mounted) return;
    _mapController.move(LatLng(parada.lat, parada.lon), 16.0);
  }

  // La ruta notifica varias veces al terminar; el guard evita hacer pop dos veces.
  void _cerrar() {
    if (_cerrando) return;
    _cerrando = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo != null && mounted) {
        context.read<HomeViewModel>().enviarImagen(photo);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo abrir la cámara. Revisa el permiso de cámara en los ajustes del móvil.',
          ),
        ),
      );
    }
  }

  // Chips de curiosidad construidos con el id de la parada en curso.
  List<PoiSugerido> _chipsParadaActual(RutaState rs) {
    final parada = rs.paradaActualObj;
    if (parada == null) return const [];
    return [
      PoiSugerido(id: parada.id, nombre: '¿Cuál es su historia?', esPregunta: true),
      PoiSugerido(id: parada.id, nombre: '¿Qué tiene de especial?', esPregunta: true),
      PoiSugerido(id: parada.id, nombre: 'Cuéntame una curiosidad', esPregunta: true),
    ];
  }

  List<Marker> _buildMarkers(RutaState rs) {
    final markers = <Marker>[];

    for (int i = 0; i < rs.resultado!.paradas.length; i++) {
      final p = rs.resultado!.paradas[i];
      final isCurrent = i == rs.paradaActual;
      final isVisited = i < rs.paradaActual;
      markers.add(Marker(
        point: LatLng(p.lat, p.lon),
        width: isCurrent ? 40 : 32,
        height: isCurrent ? 40 : 32,
        child: StopMarker(
          number: i + 1,
          isCurrent: isCurrent,
          isVisited: isVisited,
        ),
      ));
    }

    if (_userPosition != null) {
      markers.add(Marker(
        point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
        width: 22,
        height: 22,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue.shade600,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 5),
            ],
          ),
        ),
      ));
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, vm, _) {
        if (vm.rutaState == null || vm.rutaState!.estado != EstadoRuta.activo) {
          _cerrar();
          return const SizedBox.shrink();
        }

        final rs = vm.rutaState!;

        if (rs.paradaActual != _lastParadaActual) {
          _lastParadaActual = rs.paradaActual;
          _showPoiOverlay = false;
          _poiQueryPending = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _centerOnCurrentStop();
          });
        }

        final botMessages = vm.messages
            .where((m) =>
                m.role == MensajeRole.bot && m.tipo == MensajeTipo.texto)
            .toList();
        if (_poiQueryPending && botMessages.length > _lastBotMessageCount) {
          _lastBotMessageCount = botMessages.length;
          _poiQueryPending = false;
          final texto = botMessages.last.contenido;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _poiOverlayText = texto);
          });
        }

        final parada = rs.paradaActualObj!;
        final userLatLng = _userPosition != null
            ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
            : null;
        final paradaLatLng = LatLng(parada.lat, parada.lon);

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) Navigator.of(context).pop();
          },
          child: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: paradaLatLng,
                      initialZoom: 16.0,
                      onTap: (_, _) => setState(() => _followUser = false),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.chat.frontend',
                        maxNativeZoom: 19,
                        errorTileCallback: (tile, error, stackTrace) {
                          debugPrint('TILE ERROR: $error');
                        },
                      ),
                      if (userLatLng != null)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [userLatLng, paradaLatLng],
                              color: AppTheme.usal.withValues(alpha: 0.6),
                              strokeWidth: 3.0,
                            ),
                          ],
                        ),
                      MarkerLayer(markers: _buildMarkers(rs)),
                    ],
                  ),
                ),

                _TopBar(
                  paradaActual: rs.paradaActual + 1,
                  totalParadas: rs.totalParadas,
                  onBack: () => Navigator.of(context).pop(),
                  onRecenter: () {
                    setState(() => _followUser = true);
                    if (_userPosition != null) {
                      _mapController.move(
                        LatLng(
                          _userPosition!.latitude,
                          _userPosition!.longitude,
                        ),
                        16.0,
                      );
                    } else {
                      _centerOnCurrentStop();
                    }
                  },
                ),

                if (_showPoiOverlay)
                  PoiResponseOverlay(
                    texto: _poiOverlayText,
                    loading: _poiQueryPending,
                    onClose: () => setState(() {
                      _showPoiOverlay = false;
                      _poiOverlayText = null;
                    }),
                    bottomOffset: 240,
                  ),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: RutaBottomPanel(
                    parada: parada,
                    paradaActual: rs.paradaActual,
                    totalParadas: rs.totalParadas,
                    poisCercanos: _chipsParadaActual(rs),
                    generando: vm.generando,
                    onCamera: _openCamera,
                    onSiguiente: vm.siguienteParada,
                    onPoiTap: (poi) {
                      final currentCount = vm.messages
                          .where((m) =>
                              m.role == MensajeRole.bot &&
                              m.tipo == MensajeTipo.texto)
                          .length;
                      setState(() {
                        _poiQueryPending = true;
                        _poiOverlayText = null;
                        _showPoiOverlay = true;
                        _lastBotMessageCount = currentCount;
                      });
                      vm.preguntarSobrePoi(poi);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final int paradaActual;
  final int totalParadas;
  final VoidCallback onBack;
  final VoidCallback onRecenter;

  const _TopBar({
    required this.paradaActual,
    required this.totalParadas,
    required this.onBack,
    required this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 8,
      left: 12,
      right: 12,
      child: Row(
        children: [
          _MapButton(icon: Icons.arrow_back_rounded, onTap: onBack),
          const SizedBox(width: 8),
          Expanded(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Parada $paradaActual de $totalParadas',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _MapButton(icon: Icons.my_location_rounded, onTap: onRecenter),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22, color: Colors.black87),
        ),
      ),
    );
  }
}
