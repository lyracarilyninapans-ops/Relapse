import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:relapse_flutter/models/memory_reminder.dart';
import 'package:relapse_flutter/providers/activity_providers.dart';
import 'package:relapse_flutter/providers/memory_providers.dart';
import 'package:relapse_flutter/providers/patient_providers.dart';
import 'package:relapse_flutter/routes.dart';
import 'package:relapse_flutter/utils/map_utils.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/theme/app_gradients.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Memory map screen with search toggle, real memory markers, and FAB.
class MemoryScreen extends ConsumerStatefulWidget {
  const MemoryScreen({super.key});

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  GoogleMapController? _mapController;

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194),
    zoom: 13.2,
  );

  Set<Marker> _buildMarkers(
      List<MemoryReminder> reminders, LatLng? patientPos) {
    final markers = <Marker>{};

    for (final reminder in reminders) {
      if (reminder.latitude != null && reminder.longitude != null) {
        markers.add(Marker(
          markerId: MarkerId('memory_${reminder.id}'),
          position: LatLng(reminder.latitude!, reminder.longitude!),
          infoWindow: InfoWindow(title: reminder.title),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ));
      }
    }

    if (patientPos != null) {
      final patientName =
          ref.read(selectedPatientProvider)?.name ?? 'Patient';
      markers.add(Marker(
        markerId: const MarkerId('patient_location'),
        position: patientPos,
        infoWindow: InfoWindow(title: patientName),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    return markers;
  }

  Set<Circle> _buildCircles(List<MemoryReminder> reminders) {
    return reminders
        .where((r) => r.latitude != null && r.longitude != null)
        .map((r) => Circle(
              circleId: CircleId('memory_radius_${r.id}'),
              center: LatLng(r.latitude!, r.longitude!),
              radius: r.radiusMeters,
              strokeColor: AppColors.primaryColor.withAlpha(128),
              strokeWidth: 1,
              fillColor: AppColors.primaryColor.withAlpha(26),
            ))
        .toSet();
  }

  Future<void> _focusReminder(MemoryReminder reminder) async {
    if (_mapController == null ||
        reminder.latitude == null ||
        reminder.longitude == null) return;
    await _mapController!.animateCamera(
      CameraUpdate.newLatLng(LatLng(reminder.latitude!, reminder.longitude!)),
    );
  }

  Future<void> _centerOnAll(
      List<MemoryReminder> reminders, LatLng? patientPos) async {
    if (_mapController == null) return;

    final points = <LatLng>[];
    for (final r in reminders) {
      if (r.latitude != null && r.longitude != null) {
        points.add(LatLng(r.latitude!, r.longitude!));
      }
    }
    if (patientPos != null) points.add(patientPos);

    if (points.isEmpty) return;
    if (points.length == 1) {
      await _mapController!
          .animateCamera(CameraUpdate.newLatLngZoom(points.first, 15));
    } else {
      final bounds = boundsFromPoints(points);
      await _mapController!
          .animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patient = ref.watch(selectedPatientProvider);

    if (patient == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
          elevation: 0,
          title: const GradientText(
            'Memories',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        body: const NoPatientLinkedView(featureLabel: 'memory cues'),
      );
    }

    final reminders = ref.watch(activeMemoryRemindersProvider);
    final liveLocation = ref.watch(liveLocationProvider);
    final hasMemories = reminders.isNotEmpty;

    final patientPos = liveLocation.whenOrNull(
      data: (record) => record != null && record.latitude != null
          ? LatLng(record.latitude!, record.longitude!)
          : null,
    );

    final query = _searchController.text.toLowerCase();
    final filteredReminders = query.isEmpty
        ? reminders
        : reminders
            .where((r) => r.title.toLowerCase().contains(query))
            .toList();

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
            markers: _buildMarkers(reminders, patientPos),
            circles: _buildCircles(reminders),
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
          if (!hasMemories)
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
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // Search results overlay
          if (_isSearching && query.isNotEmpty)
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
                child: filteredReminders.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No matches found'),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: filteredReminders.length.clamp(0, 5),
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) => ListTile(
                          leading: const Icon(Icons.location_on,
                              color: Colors.blue),
                          title: Text(filteredReminders[i].title),
                          onTap: () {
                            setState(() => _isSearching = false);
                            _focusReminder(filteredReminders[i]);
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
            onPressed: () => _centerOnAll(reminders, patientPos),
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
                Navigator.pushNamed(context, Routes.createMemory);
              },
              child: const Icon(Icons.add, size: 32, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
