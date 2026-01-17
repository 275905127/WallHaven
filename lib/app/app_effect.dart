// lib/app/app_effect.dart
sealed class AppEffect {
  const AppEffect();
}

class NavigateToSettingsEffect extends AppEffect {
  const NavigateToSettingsEffect();
}

class NavigateToPersonalizationEffect extends AppEffect {
  const NavigateToPersonalizationEffect();
}

class PopRouteEffect extends AppEffect {
  const PopRouteEffect();
}

class OpenDrawerEffect extends AppEffect {
  const OpenDrawerEffect();
}

class CloseDrawerEffect extends AppEffect {
  const CloseDrawerEffect();
}