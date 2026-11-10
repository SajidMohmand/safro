import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../core/geo.dart';

class RouteResult {
  final List<LatLng> points;
  final double km;
  final int minutes;
  late final GeoPath path = GeoPath(points);
  RouteResult(this.points, this.km, this.minutes);
}

class RouteService {
  static final Map<String, RouteResult> _cache = {};

  static String _key(LatLng a, LatLng b) =>
      '${a.latitude.toStringAsFixed(5)},${a.longitude.toStringAsFixed(5)}>'
      '${b.latitude.toStringAsFixed(5)},${b.longitude.toStringAsFixed(5)}';

  static Future<RouteResult> route(LatLng a, LatLng b) async {
    final k = _key(a, b);
    final hit = _cache[k];
    if (hit != null) return hit;

    RouteResult? res;
    if (AppConfig.mapsApiKey.isNotEmpty) {
      try {
        final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
          'origin': '${a.latitude},${a.longitude}',
          'destination': '${b.latitude},${b.longitude}',
          'mode': 'driving',
          'key': AppConfig.mapsApiKey,
        });
        final r = await http.get(uri).timeout(const Duration(seconds: 8));
        final j = jsonDecode(r.body) as Map<String, dynamic>;
        if (j['status'] == 'OK') {
          final route = (j['routes'] as List).first as Map<String, dynamic>;
          final leg = (route['legs'] as List).first as Map<String, dynamic>;
          final pts = decodePolyline(
              (route['overview_polyline'] as Map)['points'] as String);
          final km = ((leg['distance'] as Map)['value'] as num) / 1000;
          final min = (((leg['duration'] as Map)['value'] as num) / 60).round();
          if (pts.length > 1) res = RouteResult(pts, km.toDouble(), min);
        }
      } catch (_) {}
    }
    res ??= _straight(a, b);
    _cache[k] = res;
    return res;
  }

  /// Fallback when there is no Directions key: straight line, rough numbers.
  static RouteResult _straight(LatLng a, LatLng b) {
    final pts = List<LatLng>.generate(40, (i) => lerpLatLng(a, b, i / 39));
    final km = haversineM(a, b) / 1000 * 1.3;
    final min = (km / 25 * 60).round().clamp(2, 120);
    return RouteResult(pts, km, min);
  }
}
