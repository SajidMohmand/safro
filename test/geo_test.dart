import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safro/core/geo.dart';

void main() {
  test('GeoPath returns start, middle and end', () {
    final p = GeoPath([const LatLng(0, 0), const LatLng(0, 1), const LatLng(0, 2)]);
    expect(p.at(0).longitude, 0);
    expect(p.at(.5).longitude, closeTo(1, 1e-6));
    expect(p.at(1).longitude, 2);
  });

  test('decodePolyline decodes the Google sample', () {
    final pts = decodePolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
    expect(pts.length, 3);
    expect(pts.first.latitude, closeTo(38.5, 1e-5));
    expect(pts.first.longitude, closeTo(-120.2, 1e-5));
  });
}
