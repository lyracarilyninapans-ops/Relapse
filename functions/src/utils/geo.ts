/**
 * Compute the Haversine distance between two lat/lng points in meters.
 */
export function haversineDistance(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const R = 6371000; // Earth radius in meters
  const toRad = (deg: number) => (deg * Math.PI) / 180;

  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c;
}

/**
 * Generate a geohash-like prefix (4-char) for clustering location cells.
 * Uses a simple grid-based approach, not full geohash encoding.
 */
export function locationCellKey(lat: number, lng: number, precision = 3): string {
  const latBucket = Math.round(lat * 10 ** precision);
  const lngBucket = Math.round(lng * 10 ** precision);
  return `${latBucket}_${lngBucket}`;
}
