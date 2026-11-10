import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../services/db.dart';
import '../widgets/common.dart';
import 'book_ride_screen.dart';

class TripsTab extends StatelessWidget {
  const TripsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return SafeArea(
      child: StreamBuilder<List<TripModel>>(
        stream: Db.trips(uid),
        builder: (context, snap) {
          final all = (snap.data ?? [])
              .where((t) => t.status == TripStatus.completed)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final trips = all.take(3).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              Text('Your trips', style: ts(30, w: FontWeight.w800, ls: -.5)),
              const SizedBox(height: 18),
              if (snap.connectionState == ConnectionState.waiting)
                const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(child: CircularProgressIndicator(color: AppColors.red))),
              if (snap.connectionState != ConnectionState.waiting && trips.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(children: [
                    const Icon(Icons.directions_car_outlined, size: 54, color: AppColors.line),
                    const SizedBox(height: 12),
                    Text('No trips yet.\nYour completed rides will show here.',
                        textAlign: TextAlign.center, style: ts(14.5, c: AppColors.grey, h: 1.5)),
                  ]),
                ),
              for (final t in trips) ...[
                _TripCard(trip: t),
                const SizedBox(height: 14),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripModel trip;
  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(tripWhen(trip.createdAt), style: ts(13.5, c: AppColors.grey, w: FontWeight.w600))),
            Text('PKR ${money(trip.fare)}', style: ts(16, w: FontWeight.w800)),
          ]),
          const SizedBox(height: 10),
          Text(trip.pickup.name, style: ts(19, w: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('to ${trip.drop.name}', style: ts(14.5, c: AppColors.grey)),
          const SizedBox(height: 16),
          BorderButton(
            label: 'Book again',
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => BookRideScreen(pickup: trip.pickup, drop: trip.drop, vehicle: trip.vehicle))),
          ),
        ]),
      );
}
