import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/models.dart';

/// Pick a place. Returns the chosen [Place] with Navigator.pop.
/// Uses the saved / popular Bahawalpur places in [Places.all]; swap this for
/// Google Places Autocomplete later (brief P3).
class SearchPlaceScreen extends StatefulWidget {
  final String hint;
  const SearchPlaceScreen({super.key, this.hint = 'Where to ?'});
  @override
  State<SearchPlaceScreen> createState() => _SearchPlaceScreenState();
}

class _SearchPlaceScreenState extends State<SearchPlaceScreen> {
  String _q = '';

  IconData _icon(Place p) {
    if (p.name == Places.home.name) return Icons.home_rounded;
    if (p.name == Places.university.name) return Icons.school_rounded;
    if (p.name == Places.hospital.name) return Icons.local_hospital_rounded;
    if (p.name == Places.station.name) return Icons.train_rounded;
    return Icons.place_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final list = Places.all.where((p) => p.name.toLowerCase().contains(_q.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => Navigator.pop(context)),
        title: TextField(
          autofocus: true,
          onChanged: (v) => setState(() => _q = v),
          style: ts(17, w: FontWeight.w600),
          decoration: InputDecoration(border: InputBorder.none, hintText: widget.hint, hintStyle: ts(17, c: AppColors.grey)),
        ),
      ),
      body: list.isEmpty
          ? Center(child: Text('No saved place matches', style: ts(14, c: AppColors.grey)))
          : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (_, i) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: CircleAvatar(
                    backgroundColor: AppColors.redSoft,
                    child: Icon(_icon(list[i]), color: AppColors.red)),
                title: Text(list[i].name, style: ts(16, w: FontWeight.w600)),
                subtitle: Text('Bahawalpur', style: ts(12.5, c: AppColors.grey)),
                onTap: () => Navigator.pop(context, list[i]),
              ),
            ),
    );
  }
}
