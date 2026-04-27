import 'package:caltrack/data/caltrack_repository.dart';
import 'package:flutter/foundation.dart';

class ProfileController extends ChangeNotifier {
  ProfileController(this._repo) {
    load();
  }

  final CalTrackRepository _repo;

  Profile? profile;
  bool loading = true;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    profile = await _repo.requireProfile();
    loading = false;
    notifyListeners();
  }

  Future<void> refresh() => load();
}
