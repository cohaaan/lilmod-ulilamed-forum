import 'package:flutter/foundation.dart';

/// Interface language for the Seforim library screens (browse / category /
/// book): English titles by default, Hebrew when toggled — Sefaria's א/A
/// switch. Reader text language is separate (the reader has its own control).
final ValueNotifier<bool> seforimHebrewMode = ValueNotifier<bool>(false);
