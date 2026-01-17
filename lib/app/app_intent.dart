// lib/app/app_intent.dart
sealed class AppIntent {
  const AppIntent();
}

class OpenSettingsIntent extends AppIntent {
  const OpenSettingsIntent();
}

class OpenDrawerIntent extends AppIntent {
  const OpenDrawerIntent();
}

class CloseDrawerIntent extends AppIntent {
  const CloseDrawerIntent();
}