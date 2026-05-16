import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:unshelf_seller/models/store_model.dart';
import 'package:unshelf_seller/viewmodels/store_location_viewmodel.dart';

/// Edit Store Location screen.
///
/// Preserves the existing `FlutterMap` widget (tile layer + marker layer + tap
/// handler). The redesign only swaps the chrome: inline `AppBar` with back
/// action, themed top hint banner, and a floating bottom card that shows the
/// chosen coordinates and the "Update location" 52px pill CTA.
class EditStoreLocationView extends ConsumerStatefulWidget {
  final StoreModel storeDetails;

  const EditStoreLocationView({super.key, required this.storeDetails});

  @override
  ConsumerState<EditStoreLocationView> createState() =>
      _EditStoreLocationViewState();
}

class _EditStoreLocationViewState extends ConsumerState<EditStoreLocationView> {
  late StoreModel storeDetails;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    storeDetails = widget.storeDetails;
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    if (storeDetails.storeLatitude == null ||
        storeDetails.storeLatitude == 0.0 ||
        storeDetails.storeLongitude == null ||
        storeDetails.storeLongitude == 0.0) {
      try {
        final Position position = await _getUserLocation();
        if (!mounted) return;
        setState(() {
          storeDetails.storeLatitude = position.latitude;
          storeDetails.storeLongitude = position.longitude;
        });
      } catch (_) {
        // Silently fall through; the map will use the default centre.
      }
    }
  }

  Future<Position> _getUserLocation() async {
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final notifier = ref.read(storeLocationViewModelProvider.notifier);
    try {
      await notifier.saveLocation();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location updated.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't save location: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(storeLocationViewModelProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final lat = storeDetails.storeLatitude ?? 10.3157;
    final lng = storeDetails.storeLongitude ?? 123.8854;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Store location',
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          // ── Preserved FlutterMap (existing tap handler + tile layer) ──
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(lat, lng),
              initialZoom: 15.0,
              onTap: (tapPosition, point) {
                notifier.updateLocation(point);
                setState(() {
                  storeDetails.storeLatitude = point.latitude;
                  storeDetails.storeLongitude = point.longitude;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(lat, lng),
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.location_on_rounded,
                      size: 40,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Top hint banner ─────────────────────────────────────────────
          Positioned(
            top: 16,
            left: 24,
            right: 24,
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .02),
                    offset: const Offset(0, 1),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: const Color(0xFF1F2A20).withValues(alpha: .10),
                    offset: const Offset(0, 8),
                    blurRadius: 28,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 20,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tap anywhere on the map to set your store location.',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom floating card with coords + Save CTA ─────────────────
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .02),
                      offset: const Offset(0, 1),
                      blurRadius: 0,
                    ),
                    BoxShadow(
                      color: const Color(0xFF1F2A20).withValues(alpha: .12),
                      offset: const Offset(0, 8),
                      blurRadius: 28,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.place_outlined,
                            size: 20,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected location',
                                style: tt.labelMedium?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.65),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                                style: tt.titleSmall?.copyWith(
                                  color: cs.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: cs.onPrimary,
                                ),
                              )
                            : Text(
                                'Update location',
                                style: tt.labelLarge
                                    ?.copyWith(color: cs.onPrimary),
                              ),
                      ),
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
