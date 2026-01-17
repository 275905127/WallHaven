// lib/app/app_effect.dart
sealed class AppEffect {
  const AppEffect();
}

class NavigateToSettingsEffect extends AppEffect {
  const NavigateToSettingsEffect();
}

class OpenDrawerEffect extends AppEffect {
  const OpenDrawerEffect();
}

class CloseDrawerEffect extends AppEffect {
  const CloseDrawerEffect();
}