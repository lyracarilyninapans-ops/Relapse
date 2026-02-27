import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/theme/app_gradients.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Create Memory Reminder screen with step indicator, map selection, radius,
/// media toggles and upload overlay.
class CreateMemoryReminderScreen extends StatefulWidget {
  const CreateMemoryReminderScreen({super.key});

  @override
  State<CreateMemoryReminderScreen> createState() =>
      _CreateMemoryReminderScreenState();
}

class _CreateMemoryReminderScreenState
    extends State<CreateMemoryReminderScreen> {
  static const LatLng _caregiverLocation = LatLng(37.7735, -122.4210);
  static const LatLng _patientLocation = LatLng(37.7763, -122.4177);
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194),
    zoom: 14,
  );

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();

  GoogleMapController? _mapController;
  Timer? _uploadTimer;

  LatLng? _selectedLocation;
  double _radius = 50;
  double _uploadProgress = 0;

  bool _hasName = false;
  bool _hasSearchText = false;
  bool _hasPhoto = false;
  bool _hasAudio = false;
  bool _hasVideo = false;
  bool _isUploading = false;

  bool get _isTextInputFocused =>
      _nameFocusNode.hasFocus || _searchFocusNode.hasFocus;

  int get _currentStep {
    if (!_hasName) return 0;
    if (_selectedLocation == null) return 1;
    return 2;
  }

  bool get _canSave => _hasName && _selectedLocation != null && _hasPhoto;

  Set<Marker> get _markers => {
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
    if (_selectedLocation != null)
      Marker(
        markerId: const MarkerId('memory_location'),
        position: _selectedLocation!,
        infoWindow: const InfoWindow(title: 'Memory Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
  };

  Set<Circle> get _circles => {
    if (_selectedLocation != null)
      Circle(
        circleId: const CircleId('memory_radius'),
        center: _selectedLocation!,
        radius: _radius,
        strokeColor: AppColors.primaryColor,
        strokeWidth: 2,
        fillColor: AppColors.primaryColor.withAlpha(38),
      ),
  };

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
    _searchController.addListener(_onSearchChanged);
    _nameFocusNode.addListener(_onFocusChanged);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _uploadTimer?.cancel();
    _mapController?.dispose();
    _nameController.removeListener(_onNameChanged);
    _searchController.removeListener(_onSearchChanged);
    _nameFocusNode.removeListener(_onFocusChanged);
    _searchFocusNode.removeListener(_onFocusChanged);
    _nameFocusNode.dispose();
    _searchFocusNode.dispose();
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final hasName = _nameController.text.trim().isNotEmpty;
    if (hasName == _hasName) return;
    setState(() => _hasName = hasName);
  }

  void _onSearchChanged() {
    final hasSearchText = _searchController.text.isNotEmpty;
    if (hasSearchText == _hasSearchText) return;
    setState(() => _hasSearchText = hasSearchText);
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _centerOnPatientAndCaregiver() async {
    if (_mapController == null) return;

    final bounds = _boundsFromPoints([_caregiverLocation, _patientLocation]);

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
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

  void _toggleMedia(String type) {
    setState(() {
      switch (type) {
        case 'photo':
          _hasPhoto = !_hasPhoto;
          break;
        case 'audio':
          _hasAudio = !_hasAudio;
          break;
        case 'video':
          _hasVideo = !_hasVideo;
          break;
      }
    });
  }

  void _startUpload() {
    if (!_canSave || _isUploading) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    _uploadTimer?.cancel();
    _uploadTimer = Timer.periodic(const Duration(milliseconds: 220), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_uploadProgress >= 100) {
        timer.cancel();
        Navigator.pop(context);
        return;
      }

      setState(() {
        _uploadProgress = (_uploadProgress + 10).clamp(0, 100);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final pauseMapForTyping = keyboardVisible || _isTextInputFocused;
    final mapHeight = (MediaQuery.of(context).size.height * 0.4).clamp(
      250.0,
      500.0,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: const GradientText(
          'Create Memory Reminder',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.gradientStart),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildStepIndicator(),
                const SizedBox(height: 16),
                _buildNameField(),
                const SizedBox(height: 16),
                _buildLocationHeader(),
                const SizedBox(height: 12),
                _buildSearchField(),
                const SizedBox(height: 12),
                _buildMapContainer(mapHeight, pauseMapForTyping),
                const SizedBox(height: 12),
                _buildSelectedLocationCard(),
                const SizedBox(height: 24),
                _buildRadiusSelector(),
                const SizedBox(height: 24),
                _buildMediaSection(),
                const SizedBox(height: 16),
                if (_hasPhoto || _hasAudio || _hasVideo) _buildMediaPreview(),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GradientButtonWithIcon(
                    text: _canSave ? 'Save Memory' : 'Photo required to save',
                    icon: Icons.save,
                    onPressed: _canSave ? _startUpload : null,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (_isUploading) _buildUploadOverlay(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _stepItem(0, Icons.label, 'Name'),
          _stepArrow(),
          _stepItem(1, Icons.location_on, 'Location'),
          _stepArrow(),
          _stepItem(2, Icons.perm_media, 'Media'),
        ],
      ),
    );
  }

  Widget _stepItem(int step, IconData icon, String label) {
    final isComplete = _currentStep > step;
    final isCurrent = _currentStep == step;
    final active = isComplete || isCurrent;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: active ? AppGradients.button : null,
            color: active ? null : Colors.grey[300],
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? AppColors.gradientMiddle : Colors.grey[400]!,
              width: 2,
            ),
          ),
          child: Icon(
            isComplete ? Icons.check : icon,
            color: active ? Colors.white : Colors.grey[600],
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _stepArrow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
    );
  }

  Widget _buildNameField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _nameController,
        focusNode: _nameFocusNode,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: 'Memory Name',
          prefixIcon: const Icon(Icons.label, color: AppColors.primaryColor),
          suffixIcon: _hasName
              ? const Icon(Icons.check, color: Colors.green)
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.gradientMiddle,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.location_on, color: AppColors.primaryColor, size: 20),
          SizedBox(width: 8),
          Text(
            'Select Location',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurfaceColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: 'Search address or place...',
          filled: true,
          fillColor: AppColors.surfaceColor,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _hasSearchText
              ? IconButton(
                  onPressed: _searchController.clear,
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildMapContainer(double mapHeight, bool pauseMapForTyping) {
    return Container(
      height: mapHeight,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(66), width: 2),
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
            if (pauseMapForTyping)
              Container(
                color: AppColors.surfaceColor,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.keyboard,
                      color: AppColors.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Map paused while typing',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              RepaintBoundary(
                child: GoogleMap(
                  initialCameraPosition: _initialCameraPosition,
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: (latLng) => setState(() => _selectedLocation = latLng),
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
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
                heroTag: 'create_memory_center_fab',
                backgroundColor: AppColors.surfaceColor,
                onPressed: pauseMapForTyping
                    ? null
                    : _centerOnPatientAndCaregiver,
                child: const Icon(
                  Icons.center_focus_strong,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedLocationCard() {
    return Container(
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
      child: _selectedLocation == null
          ? Text(
              'Tap on the map to select a location',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppGradients.button,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location Selected',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurfaceColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedLocation!.latitude.toStringAsFixed(4)}, '
                        '${_selectedLocation!.longitude.toStringAsFixed(4)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRadiusSelector() {
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
          const Row(
            children: [
              Icon(Icons.radar, color: AppColors.primaryColor),
              SizedBox(width: 8),
              Text(
                'Trigger Radius',
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
            max: 200,
            activeColor: AppColors.primaryColor,
            inactiveColor: AppColors.primaryColor.withAlpha(70),
            onChanged: _selectedLocation == null
                ? null
                : (value) => setState(() => _radius = value),
          ),
          Text(
            _selectedLocation == null
                ? 'Select a location first to set radius'
                : 'The memory will trigger when within this radius',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.add_photo_alternate,
                color: AppColors.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Add Media',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _mediaCard(
            icon: Icons.photo_camera,
            title: 'Photo',
            subtitle: 'Required',
            hasMedia: _hasPhoto,
            onTap: () => _toggleMedia('photo'),
          ),
          const SizedBox(height: 8),
          _mediaCard(
            icon: Icons.mic,
            title: 'Audio',
            subtitle: 'Optional',
            hasMedia: _hasAudio,
            onTap: () => _toggleMedia('audio'),
          ),
          const SizedBox(height: 8),
          _mediaCard(
            icon: Icons.videocam,
            title: 'Video',
            subtitle: 'Optional',
            hasMedia: _hasVideo,
            onTap: () => _toggleMedia('video'),
          ),
        ],
      ),
    );
  }

  Widget _mediaCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool hasMedia,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      color: AppColors.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasMedia
            ? const BorderSide(color: Colors.green, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 28, color: AppColors.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Icon(
                hasMedia ? Icons.check_circle : Icons.add_circle_outline,
                color: hasMedia ? Colors.green : AppColors.primaryColor,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
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
          const Row(
            children: [
              Icon(Icons.preview, color: AppColors.primaryColor),
              SizedBox(width: 8),
              Text(
                'Media Preview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_hasPhoto)
            _mediaPreviewItem(Icons.photo_camera, 'Photo', '2.4 MB'),
          if (_hasAudio) _mediaPreviewItem(Icons.audiotrack, 'Audio', '00:26'),
          if (_hasVideo) _mediaPreviewItem(Icons.videocam, 'Video', '15.3 MB'),
        ],
      ),
    );
  }

  Widget _mediaPreviewItem(IconData icon, String label, String detail) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryColor),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(detail, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _toggleMedia(label.toLowerCase()),
            child: const Icon(
              Icons.close,
              color: AppColors.errorColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadOverlay() {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withAlpha(128),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primaryColor),
                const SizedBox(height: 16),
                Text(
                  'Uploading... ${_uploadProgress.round()}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurfaceColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
