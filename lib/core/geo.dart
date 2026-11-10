import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

double haversineM(LatLng a, LatLng b) {
  const r = 6371000.0;
  final dLat = _rad(b.latitude - a.latitude);
  final dLng = _rad(b.longitude - a.longitude);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(a.latitude)) *
          math.cos(_rad(b.latitude)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.min(1.0, math.sqrt(h)));
}

double _rad(double d) => d * math.pi / 180;

double bearing(LatLng a, LatLng b) {
  final y = math.sin(_rad(b.longitude - a.longitude)) * math.cos(_rad(b.latitude));
  final x = math.cos(_rad(a.latitude)) * math.sin(_rad(b.latitude)) -
      math.sin(_rad(a.latitude)) *
          math.cos(_rad(b.latitude)) *
          math.cos(_rad(b.longitude - a.longitude));
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

LatLng lerpLatLng(LatLng a, LatLng b, double t) => LatLng(
    a.latitude + (b.latitude - a.latitude) * t,
    a.longitude + (b.longitude - a.longitude) * t);

List<LatLng> decodePolyline(String encoded) {
  final points = <LatLng>[];
  int index = 0, lat = 0, lng = 0;
  while (index < encoded.length) {
    int shift = 0, result = 0, b;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    points.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return points;
}

/// A polyline with cumulative distances so we can ask "where is 40% along?".
class GeoPath {
  final List<LatLng> pts;
  final List<double> cum = [0];
  double total = 0;
  GeoPath(this.pts) {
    for (var i = 1; i < pts.length; i++) {
      total += haversineM(pts[i - 1], pts[i]);
      cum.add(total);
    }
  }

  LatLng at(double f) {
    if (pts.isEmpty) return const LatLng(0, 0);
    if (f <= 0 || total == 0) return pts.first;
    if (f >= 1) return pts.last;
    final target = total * f;
    var i = 1;
    while (i < cum.length - 1 && cum[i] < target) {
      i++;
    }
    final seg = cum[i] - cum[i - 1];
    final t = seg == 0 ? 0.0 : (target - cum[i - 1]) / seg;
    return lerpLatLng(pts[i - 1], pts[i], t);
  }
}

LatLngBounds boundsOf(List<LatLng> pts) {
  var minLat = pts.first.latitude, maxLat = pts.first.latitude;
  var minLng = pts.first.longitude, maxLng = pts.first.longitude;
  for (final p in pts) {
    minLat = math.min(minLat, p.latitude);
    maxLat = math.max(maxLat, p.latitude);
    minLng = math.min(minLng, p.longitude);
    maxLng = math.max(maxLng, p.longitude);
  }
  return LatLngBounds(
      southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
}
