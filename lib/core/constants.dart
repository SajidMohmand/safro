import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/models.dart';

class AppConfig {
  static const appName = 'Safro';
  static const tagline = 'Safe rides, by women, for women';

  /// Directions API key for drawing real road routes.
  /// Pass with: flutter run --dart-define=MAPS_API_KEY=xxxx
  /// (Without it the app draws a straight line between pickup and drop.)
  static const mapsApiKey = String.fromEnvironment('MAPS_API_KEY');

  /// Support number used for the SOS SMS fallback when there is no data (S9).
  static const supportPhone = '+923000000000';

  /// Firebase Phone Auth always sends 6-digit codes. See README to use 4.
  static const otpLength = 6;

  /// Create demo contacts (Ammi, Sara) and 3 past trips for a new account.
  static const seedDemoData = true;

  /// Simulates the driver side so the full ride cycle can be tested without
  /// a driver app. Set to false once a real driver app updates trip docs.
  static const simulateDriver = true;

  static const sosHoldSeconds = 3;
}

/// Approximate Bahawalpur coordinates - verify / change as needed.
class Places {
  static const bahawalpur = LatLng(29.3956, 71.6836);
  static const home = Place('Hostel, IUB', 29.3769, 71.7588);
  static const university = Place('Sadiq Women, University', 29.3938, 71.6772);
  static const hospital = Place('Bahawal Victoria Hospital', 29.3877, 71.6877);
  static const market = Place('Farid Gate Market', 29.3978, 71.6831);
  static const station = Place('Bahawalpur Railway Station', 29.3962, 71.6757);
  static const all = <Place>[home, university, hospital, market, station];
}

const fallbackDrivers = <DriverInfo>[
  DriverInfo(
      id: 'd1', name: 'Ayesha K.', plate: 'LEA-2481', car: 'Yaris, white',
      rating: 4.9, trips: 812),
  DriverInfo(
      id: 'd2', name: 'Fatima R.', plate: 'LEB-1190', car: 'Corolla, silver',
      rating: 4.8, trips: 640),
  DriverInfo(
      id: 'd3', name: 'Hira M.', plate: 'LEC-7733', car: 'City, grey',
      rating: 4.8, trips: 455),
];
