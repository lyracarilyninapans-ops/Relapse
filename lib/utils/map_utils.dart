import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Computes a [LatLngBounds] that encloses all the given [points].
///
/// The list must contain at least one point.
LatLngBounds boundsFromPoints(List<LatLng> points) {
  assert(points.isNotEmpty, 'points must not be empty');

  double minLat = points.first.latitude;
  double maxLat = points.first.latitude;
  double minLng = points.first.longitude;
  double maxLng = points.first.longitude;

  for (final point in points.skip(1)) {
    if (point.latitude < minLat) minLat = point.latitude;
    if (point.latitude > maxLat) maxLat = point.latitude;
    if (point.longitude < minLng) minLng = point.longitude;
    if (point.longitude > maxLng) maxLng = point.longitude;
  }

  return LatLngBounds(
    southwest: LatLng(minLat, minLng),
    northeast: LatLng(maxLat, maxLng),
  );
}
