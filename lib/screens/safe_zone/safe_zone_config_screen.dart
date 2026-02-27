import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:relapse_flutter/routes.dart';
import 'package:relapse_flutter/utils/map_utils.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Safe Zone Configuration screen with map, radius slider, settings, event logs.
class SafeZoneConfigScreen extends StatefulWidget {
  const SafeZoneConfigScreen({super.key});

  @override
  State<SafeZoneConfigScreen> createState() => _SafeZoneConfigScreenState();
}

class _SafeZoneConfigScreenState extends State<SafeZoneConfigScreen> {
  GoogleMapController? _mapController;
  static const LatLng _caregiverLocation = LatLng(37.7735, -122.4210);
  static const LatLng _patientLocation = LatLng(37.7763, -122.4177);
  double _radius = 500;
  bool _locationSelected = true;
  String _watchBehavior = 'vibrate';
  bool _alertOnExit = true;
  bool _autoNavigation = false;
  bool _offlineMapsConfirmed = false;
  LatLng _safeZoneCenter = const LatLng(37.7749, -122.4194);

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194),
    zoom: 14,
  );

  Set<Marker> get _markers => {
        Marker(
          markerId: const MarkerId('caregiver_location'),
          position: _caregiverLocation,
          infoWindow: const InfoWindow(title: 'Caregiver'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
        ),
        Marker(
          markerId: const MarkerId('patient_location'),
          position: _patientLocation,
          infoWindow: const InfoWindow(title: 'Patient'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
        Marker(
          markerId: const MarkerId('safe_zone_center'),
          position: _safeZoneCenter,
          infoWindow: const InfoWindow(title: 'Safe Zone Center'),
        ),
      };

  Future<void> _centerOnPatientAndCaregiver() async {
    final controller = _mapController;
    if (controller == null) return;

    final bounds = boundsFromPoints([
      _caregiverLocation,
      _patientLocation,
    ]);
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  Set<Circle> get _circles => {
        Circle(
          circleId: const CircleId('safe_zone_radius'),
          center: _safeZoneCenter,
          radius: _radius,
          strokeColor: AppColors.primaryColor,
          strokeWidth: 2,
          fillColor: AppColors.primaryColor.withAlpha(38),
        ),
      };

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: const GradientText(
          'Safe Zone Configuration',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.gradientStart),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.errorColor),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── Status Card ──
            _buildStatusCard(),

            // ── Offline Maps Warning ──
            if (!_offlineMapsConfirmed) _buildOfflineMapsWarning(),

            // ── Map Container ──
            Container(
              height: (sh * 0.45).clamp(300, 550),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withAlpha(66),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(38),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    RepaintBoundary(
                      child: GoogleMap(
                        initialCameraPosition: _initialCameraPosition,
                        onMapCreated: (controller) => _mapController = controller,
                        onTap: (latLng) {
                          setState(() {
                            _safeZoneCenter = latLng;
                            _locationSelected = true;
                          });
                        },
                        gestureRecognizers:
                            <Factory<OneSequenceGestureRecognizer>>{
                              Factory<OneSequenceGestureRecognizer>(
                                () => EagerGestureRecognizer(),
                              ),
                            },
                        markers: _markers,
                        circles: _circles,
                        compassEnabled: true,
                        zoomControlsEnabled: true,
                        scrollGesturesEnabled: true,
                        zoomGesturesEnabled: true,
                        rotateGesturesEnabled: true,
                        tiltGesturesEnabled: true,
                        myLocationButtonEnabled: false,
                        mapToolbarEnabled: false,
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: FloatingActionButton.small(
                        heroTag: 'safe_zone_config_center_fab',
                        backgroundColor: AppColors.surfaceColor,
                        onPressed: _centerOnPatientAndCaregiver,
                        child: const Icon(
                          Icons.center_focus_strong,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Selected center card ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryColor.withAlpha(128),
                  width: 2,
                ),
              ),
              child: _locationSelected
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Center Location',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_safeZoneCenter.latitude.toStringAsFixed(4)}, '
                          '${_safeZoneCenter.longitude.toStringAsFixed(4)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Tap on the map to select safe zone center',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
            const SizedBox(height: 16),

            // ── Radius slider ──
            _buildRadiusSlider(),
            const SizedBox(height: 16),

            // ── Settings Section ──
            _buildSettingsSection(),
            const SizedBox(height: 16),

            // ── Event Logs ──
            _buildEventLogs(),
            const SizedBox(height: 16),

            // ── Save button ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: GradientButtonWithIcon(
                text: 'Save Safe Zone',
                icon: Icons.save,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final isInside = _locationSelected; // placeholder: tied to location selection
    final statusColor = isInside ? Colors.green : AppColors.errorColor;
    final statusIcon = isInside ? Icons.check_circle : Icons.warning;
    final statusText = isInside ? 'Inside Safe Zone' : 'Outside Safe Zone';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withAlpha(128), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, size: 32, color: statusColor),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patient Status',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineMapsWarning() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(66),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'Offline Maps Not Configured',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Download offline maps for the safe zone area to ensure the watch can navigate even without internet.',
            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              await Navigator.pushNamed(context, Routes.offlineMaps);
              if (!mounted) return;
              setState(() => _offlineMapsConfirmed = true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Setup Offline Maps'),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusSlider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withAlpha(153),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.radar, color: AppColors.primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Safe Zone Radius',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurfaceColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Radius: ${_radius.round()} meters',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceColor,
            ),
          ),
          Slider(
            value: _radius,
            min: 20,
            max: 2000,
            divisions: 198,
            activeColor: AppColors.primaryColor,
            inactiveColor: AppColors.primaryColor.withAlpha(70),
            onChanged: (val) => setState(() => _radius = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings, color: AppColors.primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Safety Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Watch Behavior on Exit',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          RadioGroup<String>(
            groupValue: _watchBehavior,
            onChanged: (String? val) {
              if (val != null) setState(() => _watchBehavior = val);
            },
            child: Column(
              children: [
                _radioOption('vibrate', 'Vibrate Only', 'Watch vibrates when leaving zone'),
                _radioOption('alarm', 'Sound Alarm', 'Watch plays alarm sound'),
                _radioOption('both', 'Vibrate + Alarm', 'Both vibration and alarm'),
              ],
            ),
          ),

          const Divider(),

          SwitchListTile(
            title: const Text('Alert on Exit'),
            value: _alertOnExit,
            activeTrackColor: AppColors.primaryColor,
            onChanged: (val) => setState(() => _alertOnExit = val),
          ),

          const Divider(),

          SwitchListTile(
            title: const Text('Auto Navigation'),
            value: _autoNavigation,
            activeTrackColor: AppColors.primaryColor,
            onChanged: (val) => setState(() => _autoNavigation = val),
          ),
        ],
      ),
    );
  }

  Widget _radioOption(String value, String title, String subtitle) {
    return RadioListTile<String>(
      value: value,
      activeColor: AppColors.primaryColor,
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildEventLogs() {
    final events = [
      {'type': 'Zone Exit', 'time': '2 hours ago', 'status': 'Resolved'},
      {'type': 'Zone Exit', 'time': '1 day ago', 'status': 'Alert Sent'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: AppColors.primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Recent Events',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...events.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.errorColor.withAlpha(77),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning,
                      color: AppColors.errorColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      e['type']!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      e['time']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: e['status'] == 'Resolved'
                            ? Colors.grey[200]
                            : AppColors.errorColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        e['status']!,
                        style: TextStyle(
                          fontSize: 11,
                          color: e['status'] == 'Resolved'
                              ? Colors.grey[600]
                              : AppColors.errorColor,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
