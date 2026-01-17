// lib/app/app_intent.dart
sealed class AppIntent {
  const AppIntent();
}

class OpenDrawer extends AppIntent {
  const OpenDrawer();
}

class CloseDrawer extends AppIntent {
  const CloseDrawer();
}

class GoHome extends AppIntent {
  const GoHome();
}

class GoSettings extends AppIntent {
  const GoSettings();
}