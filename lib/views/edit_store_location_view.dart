import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/viewmodels/store_location_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:unshelf_seller/models/store_model.dart';
import 'package:unshelf_seller/components/custom_app_bar.dart';

class EditStoreLocationView extends StatefulWidget {
  final StoreModel storeDetails;

  const EditStoreLocationView({super.key, required this.storeDetails});

  @override
  State<EditStoreLocationView> createState() => _EditStoreLocationViewState();
}

class _EditStoreLocationViewState extends State<EditStoreLocationView> {
  late StoreLocationViewModel viewModel;
  late StoreModel storeDetails;

  @override
  void initState() {
    super.initState();
    storeDetails = widget.storeDetails;
    viewModel = Provider.of<StoreLocationViewModel>(context, listen: false);
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    if (storeDetails.storeLatitude == null ||
        storeDetails.storeLatitude == 0.0 ||
        storeDetails.storeLongitude == null ||
        storeDetails.storeLongitude == 0.0) {
      Position position = await _getUserLocation();
      setState(() {
        storeDetails.storeLatitude = position.latitude;
        storeDetails.storeLongitude = position.longitude;
      });
    }
  }

  Future<Position> _getUserLocation() async {
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Edit Store Location',
        onBackPressed: () {
          Navigator.pop(context);
        },
        actionWidget: IconButton(
          icon: Icon(
            Icons.save,
            color: AppColors.textPrimary,
          ),
          onPressed: () async {
            try {
              await viewModel.saveLocation();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location saved successfully!')),
              );
              Navigator.pop(context, true);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to save location: $e')),
              );
            }
          },
        ),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(
            storeDetails.storeLatitude ?? 1.3521,
            storeDetails.storeLongitude ?? 103.8198,
          ),
          initialZoom: 15.0,
          onTap: (tapPosition, point) {
            viewModel.updateLocation(point);
            setState(() {
              storeDetails.storeLatitude = point.latitude;
              storeDetails.storeLongitude = point.longitude;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                  storeDetails.storeLatitude ?? 1.3521,
                  storeDetails.storeLongitude ?? 103.8198,
                ),
                child: const Icon(
                  Icons.location_pin,
                  color: AppColors.error,
                  size: 40.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
