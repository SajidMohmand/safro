import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants.dart';
import '../models/models.dart';
import 'route_service.dart';

class FareConfig {
  final int base, perKm, perMin, minFare, acExtra;
  final double commission;
  const FareConfig(
      {this.base = 80,
      this.perKm = 35,
      this.perMin = 4,
      this.minFare = 150,
      this.acExtra = 60,
      this.commission = 0.12});

  factory FareConfig.fromMap(Map<String, dynamic> m) {
    const d = FareConfig();
    int i(String k, int def) => ((m[k] ?? def) as num).toInt();
    return FareConfig(
        base: i('baseFare', d.base),
        perKm: i('perKm', d.perKm),
        perMin: i('perMin', d.perMin),
        minFare: i('minFare', d.minFare),
        acExtra: i('acExtra', d.acExtra),
        commission: ((m['commission'] ?? d.commission) as num).toDouble());
  }

  /// Fixed fare = base + per km + per minute, with a minimum (brief P4 / s8).
  int fare(RouteResult r, String vehicle) {
    var f = base + perKm * r.km + perMin * r.minutes;
    if (vehicle == 'AC Car') f += acExtra;
    f = max(f, minFare.toDouble() + (vehicle == 'AC Car' ? acExtra : 0));
    return ((f / 10).round() * 10);
  }
}

class Db {
  static final FirebaseFirestore _f = FirebaseFirestore.instance;
  static String get uid => FirebaseAuth.instance.currentUser!.uid;

  // ---------- users ----------
  static Stream<UserProfile?> userStream(String uid) =>
      _f.collection('users').doc(uid).snapshots().map(
          (d) => d.exists ? UserProfile.fromMap(uid, d.data()!) : null);

  /// Creates the profile (and demo data) the first time a number signs in.
  static Future<void> ensureUser(User u) async {
    final ref = _f.collection('users').doc(u.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      'phone': u.phoneNumber ?? '',
      'name': '',
      'shareEveryTrip': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (AppConfig.seedDemoData) await _seed(u.uid);
  }

  static Future<void> _seed(String uid) async {
    final b = _f.batch();
    final c = _f.collection('users').doc(uid).collection('contacts');
    b.set(c.doc(), {'name': 'Ammi', 'phone': '', 'createdAt': FieldValue.serverTimestamp()});
    b.set(c.doc(), {'name': 'Sara', 'phone': '', 'createdAt': FieldValue.serverTimestamp()});

    final now = DateTime.now();
    final samples = [
      (DateTime(now.year, now.month, now.day, 8, 12), 420, 'Car', Places.home, Places.university),
      (DateTime(now.year, now.month, now.day, 17, 40).subtract(const Duration(days: 1)), 420, 'Car', Places.university, Places.home),
      (DateTime(now.year, now.month, now.day, 8, 5).subtract(const Duration(days: 2)), 480, 'AC Car', Places.home, Places.university),
    ];
    final rnd = Random();
    for (final s in samples) {
      b.set(_f.collection('trips').doc(), {
        'passengerId': uid,
        'pickup': s.$4.toMap(),
        'drop': s.$5.toMap(),
        'vehicle': s.$3,
        'fare': s.$2,
        'status': TripStatus.completed,
        'payment': 'Cash',
        'receiptNo': '#SF-${10000 + rnd.nextInt(90000)}',
        'pin': '0000',
        'followers': <String>[],
        'seeded': true,
        'createdAt': Timestamp.fromDate(s.$1),
      });
    }
    await b.commit();
  }

  static Future<void> setName(String uid, String name) =>
      _f.collection('users').doc(uid).set({
        'name': name.trim(),
        'confirmedWoman18Plus': true,
        'acceptedTermsAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  static Future<void> setShareEvery(String uid, bool v) =>
      _f.collection('users').doc(uid).set({'shareEveryTrip': v}, SetOptions(merge: true));

  // ---------- contacts ----------
  static Stream<List<Contact>> contacts(String uid) => _f
      .collection('users')
      .doc(uid)
      .collection('contacts')
      .snapshots()
      .map((s) => s.docs
          .map((d) => Contact(d.id, (d['name'] ?? '') as String, (d.data()['phone'] ?? '') as String))
          .toList());

  static Future<List<Contact>> contactsOnce(String uid) async {
    final s = await _f.collection('users').doc(uid).collection('contacts').get();
    return s.docs
        .map((d) => Contact(d.id, (d['name'] ?? '') as String, (d.data()['phone'] ?? '') as String))
        .toList();
  }

  static Future<void> addContact(String uid, String name, String phone) => _f
      .collection('users')
      .doc(uid)
      .collection('contacts')
      .add({'name': name, 'phone': phone, 'createdAt': FieldValue.serverTimestamp()});

  static Future<void> removeContact(String uid, String id) =>
      _f.collection('users').doc(uid).collection('contacts').doc(id).delete();

  // ---------- drivers / config ----------
  static Future<List<DriverInfo>> drivers() async {
    try {
      final s = await _f.collection('drivers').get().timeout(const Duration(seconds: 6));
      final list = s.docs.map((d) => DriverInfo.fromMap(d.id, d.data())).toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}
    return fallbackDrivers;
  }

  static Future<FareConfig> fareConfig() async {
    try {
      final d = await _f.collection('config').doc('app').get().timeout(const Duration(seconds: 6));
      if (d.exists) return FareConfig.fromMap(d.data()!);
    } catch (_) {}
    return const FareConfig();
  }

  // ---------- trips ----------
  static Stream<List<TripModel>> trips(String uid) => _f
      .collection('trips')
      .where('passengerId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map(TripModel.fromDoc).toList());

  static Stream<TripModel?> tripStream(String id) => _f
      .collection('trips')
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? TripModel.fromDoc(d) : null);

  static Future<TripModel?> getTrip(String id) async {
    final d = await _f.collection('trips').doc(id).get();
    return d.exists ? TripModel.fromDoc(d) : null;
  }

  static Future<String> createTrip({
    required Place pickup,
    required Place drop,
    required String vehicle,
    required int fare,
    required List<String> followers,
  }) async {
    final ref = _f.collection('trips').doc();
    final rnd = Random();
    await ref.set({
      'passengerId': uid,
      'pickup': pickup.toMap(),
      'drop': drop.toMap(),
      'vehicle': vehicle,
      'fare': fare,
      'status': TripStatus.searching,
      'payment': 'Cash',
      'pin': (1000 + rnd.nextInt(9000)).toString(),
      'receiptNo': '#SF-${10000 + rnd.nextInt(90000)}',
      'followers': followers,
      'driverArrived': false,
      'pinEntered': false,
      'sosActive': false,
      'progress': 0,
      'createdAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 12));
    return ref.id;
  }

  static Future<void> updateTrip(String id, Map<String, dynamic> data) =>
      _f.collection('trips').doc(id).update(data);

  // ---------- chat (masked, in-app) ----------
  static Stream<List<Map<String, dynamic>>> messages(String tripId) => _f
      .collection('trips')
      .doc(tripId)
      .collection('messages')
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList());

  static Future<void> sendMessage(String tripId, String text) => _f
      .collection('trips')
      .doc(tripId)
      .collection('messages')
      .add({'from': 'passenger', 'text': text, 'createdAt': FieldValue.serverTimestamp()});

  // ---------- plans ----------
  static Stream<PlanModel?> planStream(String uid) =>
      _f.collection('plans').doc(uid).snapshots().map(
          (d) => d.exists ? PlanModel.fromMap(d.data()!) : null);

  static Future<void> savePlan(String uid, Map<String, dynamic> data) =>
      _f.collection('plans').doc(uid).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  // ---------- SOS & tickets ----------
  static DocumentReference<Map<String, dynamic>> newSosRef() =>
      _f.collection('sos_alerts').doc();

  static Future<void> cancelSos(String id) =>
      _f.collection('sos_alerts').doc(id).update({
        'status': 'cancelled_by_user',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

  static Future<String> createTicket(String tripId, String text) async {
    final lower = text.toLowerCase();
    const urgentWords = ['unsafe', 'harass', 'scared', 'threat', 'touch', 'follow', 'danger', 'help'];
    final urgent = urgentWords.any(lower.contains);
    final number = 'T-${10000 + Random().nextInt(90000)}';
    await _f.collection('tickets').add({
      'number': number,
      'passengerId': uid,
      'tripId': tripId,
      'text': text,
      'priority': urgent ? 'urgent' : 'normal',
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return number;
  }
}

class DriverRepo {
  static List<DriverInfo>? _cache;
  static Future<List<DriverInfo>> load() async => _cache ??= await Db.drivers();
}
