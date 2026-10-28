import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme.dart';
import '../../services/geo_service.dart';
import '../../widgets/common.dart';

/// Hasil pilihan lokasi dari peta.
class PickedLocation {
  PickedLocation({
    required this.lat,
    required this.lng,
    required this.fullAddress,
    required this.city,
    this.postalCode,
  });

  final double lat;
  final double lng;
  final String fullAddress;
  final String city;
  final String? postalCode;
}

/// Layar penuh pemilih lokasi: geser peta sampai pin tepat di rumah,
/// alamat terisi otomatis. Mengembalikan [PickedLocation] atau null bila dibatalkan.
class PilihLokasiPage extends StatefulWidget {
  const PilihLokasiPage({super.key, this.initial});

  final LatLng? initial;

  @override
  State<PilihLokasiPage> createState() => _PilihLokasiPageState();
}

class _PilihLokasiPageState extends State<PilihLokasiPage> {
  /// Pusat awal bila tidak ada lokasi tersimpan dan GPS belum tersedia (Batam).
  static const _fallback = LatLng(1.0456, 104.0305);

  final _map = MapController();
  final _search = TextEditingController();
  late LatLng _center;
  ReverseResult? _result;
  bool _resolving = false;
  bool _locating = false;
  bool _searching = false;
  bool _reverseFailed = false;
  List<PlaceHit> _hits = [];
  Timer? _debounce;
  int _token = 0; // mengabaikan hasil geocoding yang sudah usang

  @override
  void initState() {
    super.initState();
    _center = widget.initial ?? _fallback;
    if (widget.initial == null) {
      // Alamat baru: coba langsung ke lokasi pengguna.
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToMyLocation(silent: true));
    } else {
      _scheduleReverse(immediate: true);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _map.dispose();
    super.dispose();
  }

  void _scheduleReverse({bool immediate = false}) {
    _debounce?.cancel();
    if (!_resolving) setState(() => _resolving = true);
    _debounce = Timer(Duration(milliseconds: immediate ? 50 : 800), _reverse);
  }

  Future<void> _reverse() async {
    final token = ++_token;
    final point = _center;
    final r = await GeoService.instance.reverse(point.latitude, point.longitude);
    if (!mounted || token != _token) return;
    setState(() {
      _result = r;
      _reverseFailed = r == null;
      _resolving = false;
    });
  }

  Future<void> _goToMyLocation({bool silent = false}) async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!silent && mounted) showSnack(context, 'Aktifkan GPS/lokasi pada perangkat.', error: true);
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (!silent && mounted) {
          showSnack(context, 'Izin lokasi ditolak. Geser peta secara manual.', error: true);
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      _moveTo(LatLng(pos.latitude, pos.longitude));
    } catch (_) {
      if (!silent && mounted) showSnack(context, 'Gagal mengambil lokasi saat ini.', error: true);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _moveTo(LatLng p, {double zoom = 17}) {
    _center = p;
    _map.move(p, zoom);
    _scheduleReverse();
  }

  Future<void> _doSearch() async {
    final q = _search.text.trim();
    if (q.length < 3) return;
    FocusScope.of(context).unfocus();
    setState(() => _searching = true);
    final hits = await GeoService.instance.search(q);
    if (!mounted) return;
    setState(() {
      _hits = hits;
      _searching = false;
    });
    if (hits.isEmpty) showSnack(context, 'Lokasi tidak ditemukan.');
  }

  void _confirm() {
    Navigator.of(context).pop(PickedLocation(
      lat: _center.latitude,
      lng: _center.longitude,
      fullAddress: _result?.fullAddress ?? '',
      city: _result?.city ?? '',
      postalCode: _result?.postalCode,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 17,
              minZoom: 4,
              maxZoom: 19,
              onPositionChanged: (camera, hasGesture) {
                _center = camera.center;
                if (hasGesture) {
                  if (_hits.isNotEmpty) setState(() => _hits = []);
                  _scheduleReverse();
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.komporcare',
              ),
            ],
          ),
          // Pin tetap di tengah; ujung bawah pin = titik terpilih.
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(Icons.location_on, size: 44, color: AppColors.error),
              ),
            ),
          ),
          // Bar atas: kembali + pencarian
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Material(
                        color: AppColors.surface,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(10),
                          child: TextField(
                            controller: _search,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _doSearch(),
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Cari jalan, perumahan, atau tempat',
                              prefixIcon: const Icon(Icons.search,
                                  size: 18, color: AppColors.textMuted),
                              suffixIcon: _searching
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2, color: AppColors.green)),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_hits.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6, left: 48),
                      constraints: const BoxConstraints(maxHeight: 240),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _hits.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (_, i) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.place_outlined,
                              size: 18, color: AppColors.green),
                          title: Text(_hits[i].name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12)),
                          onTap: () {
                            final h = _hits[i];
                            setState(() => _hits = []);
                            _moveTo(LatLng(h.lat, h.lng));
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Tombol lokasi saya
          Positioned(
            right: 12,
            bottom: 210,
            child: Material(
              color: AppColors.surface,
              shape: const CircleBorder(),
              elevation: 3,
              child: IconButton(
                onPressed: _locating ? null : () => _goToMyLocation(),
                icon: _locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.green))
                    : const Icon(Icons.my_location, size: 20, color: AppColors.green),
              ),
            ),
          ),
          // Atribusi OSM (wajib)
          const Positioned(
            left: 8,
            bottom: 196,
            child: Text('© OpenStreetMap contributors',
                style: TextStyle(fontSize: 9, color: Colors.black54)),
          ),
          // Kartu alamat terpilih
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lokasi terpilih',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 18, color: AppColors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _resolving
                              ? const Text('Mencari alamat...',
                                  style: TextStyle(
                                      fontSize: 12.5, color: AppColors.textMuted))
                              : _reverseFailed || r == null
                                  ? const Text(
                                      'Alamat tidak terbaca. Anda tetap bisa memakai titik ini dan melengkapi alamat di form.',
                                      style: TextStyle(fontSize: 12, height: 1.35))
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            r.fullAddress.isEmpty
                                                ? 'Nama jalan tidak tersedia'
                                                : r.fullAddress,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                height: 1.3)),
                                        const SizedBox(height: 2),
                                        Text(
                                            [
                                              if (r.city.isNotEmpty) r.city,
                                              if ((r.postalCode ?? '').isNotEmpty)
                                                r.postalCode!,
                                            ].join(' • '),
                                            style: const TextStyle(
                                                fontSize: 11, color: AppColors.textMuted)),
                                      ],
                                    ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Gunakan lokasi ini',
                      icon: Icons.check,
                      onPressed: _resolving ? null : _confirm,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
