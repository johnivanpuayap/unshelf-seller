import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unshelf_seller/core/providers/services.dart';
import 'package:unshelf_seller/services/permission_service.dart';

part 'store_location_viewmodel.g.dart';

/// Immutable state for the Edit Store Location screen.
class StoreLocationState {
  final bool isLoading;
  final String? errorMessage;
  final LatLng chosenLocation;

  const StoreLocationState({
    required this.isLoading,
    required this.errorMessage,
    required this.chosenLocation,
  });

  factory StoreLocationState.initial() => const StoreLocationState(
        isLoading: false,
        errorMessage: null,
        // Cebu City default — matches the original ChangeNotifier seed.
        chosenLocation: LatLng(10.3157, 123.8854),
      );

  StoreLocationState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    LatLng? chosenLocation,
  }) {
    return StoreLocationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      chosenLocation: chosenLocation ?? this.chosenLocation,
    );
  }

  static const _sentinel = Object();
}

/// Store location ViewModel — backs the Edit Store Location map screen.
@riverpod
class StoreLocationViewModel extends _$StoreLocationViewModel {
  @override
  StoreLocationState build() => StoreLocationState.initial();

  void updateLocation(LatLng location) {
    state = state.copyWith(chosenLocation: location);
  }

  Future<Position?> getUserLocation(BuildContext context) async {
    // Request location permission
    await requestLocationPermission();

    // Check if permission is granted
    var status = await Permission.location.status;
    if (status.isGranted) {
      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } else if (status.isDenied) {
      String message =
          'Location permission is required to use this feature. Please enable it in settings.';
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
      return null;
    } else if (status.isPermanentlyDenied) {
      // Permission is permanently denied
      String message =
          'Location permission is permanently denied. Please enable it in app settings.';
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                openAppSettings();
              },
            ),
          ),
        );
      }
      return null;
    }

    return null;
  }

  Future<void> saveLocation() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(storeServiceProvider).saveStoreLocation(
            state.chosenLocation.latitude,
            state.chosenLocation.longitude,
          );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}
