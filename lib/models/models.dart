import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Place {
  final String name;
  final double lat;
  final double lng;
  const Place(this.name, this.lat, this.lng);
  LatLng get latLng => LatLng(lat, lng);
  Map<String, dynamic> toMap() => {'name': name, 'lat': lat, 'lng': lng};
  factory Place.fromMap(Map<String, dynamic> m) => Place(
      (m['name'] ?? '') as String,
      ((m['lat'] ?? 0) as num).toDouble(),
      ((m['lng'] ?? 0) as num).toDouble());
}

class DriverInfo {
  final String id, name, plate, car;
  final double rating;
  final int trips;
  final int monthlyPrice;
  const DriverInfo({
    required this.id,
    required this.name,
    required this.plate,
    required this.car,
    required this.rating,
    required this.trips,
    this.monthlyPrice = 7500,
  });
  String get firstName => name.split(' ').first;
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'plate': plate,
        'car': car,
        'rating': rating,
        'trips': trips,
        'monthlyPrice': monthlyPrice,
      };
  factory DriverInfo.fromMap(String id, Map<String, dynamic> m) => DriverInfo(
        id: id,
        name: (m['name'] ?? 'Driver') as String,
        plate: (m['plate'] ?? '') as String,
        car: (m['car'] ?? '') as String,
        rating: ((m['rating'] ?? 4.8) as num).toDouble(),
        trips: ((m['trips'] ?? 0) as num).toInt(),
        monthlyPrice: ((m['monthlyPrice'] ?? 7500) as num).toInt(),
      );
}

class Contact {
  final String id, name, phone;
  const Contact(this.id, this.name, this.phone);
}

class UserProfile {
  final String uid, name, phone;
  final bool shareEveryTrip;
  const UserProfile(this.uid, this.name, this.phone, this.shareEveryTrip);
  String get firstName => name.trim().split(' ').first;
  factory UserProfile.fromMap(String uid, Map<String, dynamic> m) =>
      UserProfile(uid, (m['name'] ?? '') as String, (m['phone'] ?? '') as String,
          (m['shareEveryTrip'] ?? true) as bool);
}

class PlanModel {
  final String? driverId;
  final Place pickup, drop;
  final List<int> days; // 0 = Mon ... 6 = Sun
  final int minutes; // minutes after midnight
  final int price;
  final bool active;
  const PlanModel(this.driverId, this.pickup, this.drop, this.days,
      this.minutes, this.price, this.active);
  factory PlanModel.fromMap(Map<String, dynamic> m) => PlanModel(
        m['driverId'] as String?,
        Place.fromMap(Map<String, dynamic>.from(m['pickup'] as Map)),
        Place.fromMap(Map<String, dynamic>.from(m['drop'] as Map)),
        List<int>.from((m['days'] ?? <int>[]) as List),
        ((m['minutes'] ?? 450) as num).toInt(),
        ((m['price'] ?? 7500) as num).toInt(),
        (m['active'] ?? false) as bool,
      );
}

class TripStatus {
  static const searching = 'searching';
  static const found = 'found';
  static const onTheWay = 'onTheWay';
  static const inProgress = 'inProgress';
  static const arriving = 'arriving';
  static const completed = 'completed';
  static const cancelled = 'cancelled';
}

class TripModel {
  final String id, passengerId, vehicle, status, pin, receiptNo, payment;
  final Place pickup, drop;
  final int fare;
  final DriverInfo? driver;
  final double? driverLat, driverLng;
  final int etaMin;
  final bool driverArrived, pinEntered, sosActive;
  final double progress;
  final List<String> followers;
  final DateTime createdAt;
  final int? rating;

  const TripModel({
    required this.id,
    required this.passengerId,
    required this.vehicle,
    required this.status,
    required this.pin,
    required this.receiptNo,
    required this.payment,
    required this.pickup,
    required this.drop,
    required this.fare,
    required this.driver,
    required this.driverLat,
    required this.driverLng,
    required this.etaMin,
    required this.driverArrived,
    required this.pinEntered,
    required this.sosActive,
    required this.progress,
    required this.followers,
    required this.createdAt,
    required this.rating,
  });

  factory TripModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    final dm = m['driver'];
    return TripModel(
      id: d.id,
      passengerId: (m['passengerId'] ?? '') as String,
      vehicle: (m['vehicle'] ?? 'Car') as String,
      status: (m['status'] ?? TripStatus.searching) as String,
      pin: (m['pin'] ?? '0000') as String,
      receiptNo: (m['receiptNo'] ?? '#SF-00000') as String,
      payment: (m['payment'] ?? 'Cash') as String,
      pickup: Place.fromMap(Map<String, dynamic>.from(m['pickup'] as Map)),
      drop: Place.fromMap(Map<String, dynamic>.from(m['drop'] as Map)),
      fare: ((m['fare'] ?? 0) as num).toInt(),
      driver: dm is Map
          ? DriverInfo.fromMap(
              (dm['id'] ?? '') as String, Map<String, dynamic>.from(dm))
          : null,
      driverLat: (m['driverLat'] as num?)?.toDouble(),
      driverLng: (m['driverLng'] as num?)?.toDouble(),
      etaMin: ((m['etaMin'] ?? 0) as num).toInt(),
      driverArrived: (m['driverArrived'] ?? false) as bool,
      pinEntered: (m['pinEntered'] ?? false) as bool,
      sosActive: (m['sosActive'] ?? false) as bool,
      progress: ((m['progress'] ?? 0) as num).toDouble(),
      followers: List<String>.from((m['followers'] ?? <String>[]) as List),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rating: (m['rating'] as num?)?.toInt(),
    );
  }
}
