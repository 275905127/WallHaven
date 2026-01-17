// lib/app/app_intent.dart
import 'package:flutter/material.dart';

sealed class AppIntent {
  const AppIntent();
}

// -------- Navigation --------
class OpenSettingsIntent extends AppIntent {
  const OpenSettingsIntent();
}

class OpenPersonalizationIntent extends AppIntent {
  const OpenPersonalizationIntent();
}

class PopRouteIntent extends AppIntent {
  const PopRouteIntent();
}

class OpenDrawerIntent extends AppIntent {
  const OpenDrawerIntent();
}

class CloseDrawerIntent extends AppIntent {
  const CloseDrawerIntent();
}

// -------- Theme actions (write ThemeStore) --------
class SetPreferredModeIntent extends AppIntent {
  final ThemeMode mode;
  const SetPreferredModeIntent(this.mode);
}

class SetEnableThemeModeIntent extends AppIntent {
  final bool enabled;
  const SetEnableThemeModeIntent(this.enabled);
}

class SetEnableCustomColorsIntent extends AppIntent {
  final bool enabled;
  const SetEnableCustomColorsIntent(this.enabled);
}

class SetAccentIntent extends AppIntent {
  final Color color;
  final String name;
  const SetAccentIntent(this.color, this.name);
}

class SetCardRadiusIntent extends AppIntent {
  final double value;
  const SetCardRadiusIntent(this.value);
}

class SetImageRadiusIntent extends AppIntent {
  final double value;
  const SetImageRadiusIntent(this.value);
}

class SetCustomBackgroundColorIntent extends AppIntent {
  final Color? color;
  const SetCustomBackgroundColorIntent(this.color);
}

class SetCustomCardColorIntent extends AppIntent {
  final Color? color;
  const SetCustomCardColorIntent(this.color);
}