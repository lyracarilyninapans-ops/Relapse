import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/theme/app_gradients.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Memory map screen with search toggle, placeholder map, and FAB.
class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  GoogleMapController? _mapController;

  static const LatLng _caregiverLocation = LatLng(37.7735, -122.4210);
  static const LatLng _patientLocation = LatLng(37.7763, -122.4177);

  // Placeholder data
  final _hasMemories = true;
  final List<String> _searchResults = <String>[
    'Home - Living Room',
    'Park - East Entrance',
    'Grocery Store',
  ];

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194),
    zoom: 13.2,
  );

  final Map<String, LatLng> _memoryLocations = const {
    'Home - Living Room': LatLng(37.7749, -122.4194),
    'Park - East Entrance': LatLng(37.7694, -122.4862),
    'Grocery Store': LatLng(37.7841, -122.4075),
  };

  Set<Marker> get _memoryMarkers => _memoryLocations.entries
      .map(
        (entry) => Marker(
          markerId: MarkerId(entry.key),
          position: entry.value,
          infoWindow: InfoWindow(title: entry.key),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      )
      .toSet();

  Set<Marker> get _contextMarkers => {
    Marker(
      markerId: const MarkerId('caregiver_location'),
      position: _caregiverLocation,
      infoWindow: const InfoWindow(title: 'Caregiver'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
    ),
    Marker(
      markerId: const MarkerId('patient_location'),
      position: _patientLocation,
      infoWindow: const InfoWindow(title: 'Patient'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ),
  };

  Set<Marker> get _allMarkers => {
    ...(_hasMemories ? _memoryMarkers : const <Marker>{}),
    ..._contextMarkers,
  };

  Future<void> _focusMemory(String memoryName) async {
    final controller = _mapController;
    final position = _memoryLocations[memoryName];
    if (controller == null || position == null) return;

    await controller.animateCamera(CameraUpdate.newLatLng(position));
  }

  Future<void> _centerOnPatientAndCaregiver() async {
    final controller = _mapController;
    if (controller == null) return;

    final points = <LatLng>[_caregiverLocation, _patientLocation];
    final bounds = _boundsFromPoints(points);
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  LatLngBounds _boundsFromPoints(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search memories...',
                  hintStyle: TextStyle(color: Colors.black54),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : const GradientText(
                'Memories',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: AppColors.primaryColor,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (controller) => _mapController = controller,
            markers: _allMarkers,
            compassEnabled: true,
            zoomControlsEnabled: false,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Empty state overlay
          if (!_hasMemories)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No memories added yet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the + button to add your first memory',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // Search results overlay
          if (_isSearching && _searchController.text.isNotEmpty)
            Positioned(
              top: 0,
              left: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _searchResults.length.clamp(0, 5),
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.blue),
                    title: Text(_searchResults[i]),
                    onTap: () async {
                      final selectedMemory = _searchResults[i];
                      setState(() => _isSearching = false);
                      await _focusMemory(selectedMemory);
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'memory_center_fab',
            backgroundColor: AppColors.surfaceColor,
            onPressed: _centerOnPatientAndCaregiver,
            child: const Icon(
              Icons.center_focus_strong,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              gradient: AppGradients.button,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: FloatingActionButton(
              heroTag: 'memory_add_fab',
              backgroundColor: Colors.transparent,
              elevation: 0,
              onPressed: () {
                Navigator.pushNamed(context, '/create-memory');
              },
              child: const Icon(Icons.add, size: 32, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
