import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';
import 'app_text.dart';
import 'design_direction.dart';
import 'design_directions.dart';

const _prefKey = 'design_direction_id';

/// Persists and broadcasts the active [DesignDirection] across the app.
final designDirectionController = DesignDirectionController();

class DesignDirectionController extends ChangeNotifier {
  DesignDirection _active = DesignDirections.chavrusaDirectory;

  DesignDirection get active => _active;

  bool get isSlack => _active.id == DesignDirections.slackWorkspace.id;

  bool get isChavrusa => _active.id == DesignDirections.chavrusaDirectory.id;

  /// Load saved direction from disk; defaults to Chavrusa Directory.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_prefKey);
    if (id == null) return;
    final direction = DesignDirections.byId(id);
    if (direction != null) {
      _apply(direction, persist: false);
    }
  }

  /// Switch live theme to [direction] and optionally persist the choice.
  Future<void> apply(DesignDirection direction, {bool persist = true}) async {
    _apply(direction, persist: persist);
  }

  void _apply(DesignDirection direction, {required bool persist}) {
    _active = direction;
    AppColors.apply(direction);
    AppText.apply(direction);
    notifyListeners();
    if (persist) {
      SharedPreferences.getInstance().then(
        (prefs) => prefs.setString(_prefKey, direction.id),
      );
    }
  }
}
