import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/utils/geocoding_utils.dart';

class ActivityResolvedLocationText extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String fallback;
  final String resolvingText;
  final TextStyle style;

  const ActivityResolvedLocationText({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.fallback,
    this.resolvingText = 'Resolving location...',
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: GeocodingUtils.reverseGeocodeCoordinates(latitude, longitude),
      builder: (context, snapshot) {
        final label = snapshot.data;
        final displayText = snapshot.connectionState == ConnectionState.waiting
            ? resolvingText
            : (label != null && label.isNotEmpty)
                ? label
                : fallback;
        return Text(
          displayText,
          style: style,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

class ActivityFullScreenMapPage extends StatelessWidget {
  final LatLng initialTarget;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Circle> circles;

  const ActivityFullScreenMapPage({
    super.key,
    required this.initialTarget,
    required this.markers,
    required this.polylines,
    required this.circles,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 16,
            ),
            markers: markers,
            polylines: polylines,
            circles: circles,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 12,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceColor.withAlpha(230),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(60),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close,
                    size: 22,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
