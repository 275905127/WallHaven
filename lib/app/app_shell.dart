import 'package:flutter/material.dart';

import '../pages/home_page.dart';
import '../pages/settings_page.dart';
import '../theme/theme_store.dart';
import '../widgets/foggy_app_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isScrolled = false;

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _handleScroll(double pixels) {
    final next = pixels > 0;
    if (next != _isScrolled) setState(() => _isScrolled = next);
  }

  @override
  Widget build(BuildContext context) {
    final store = ThemeScope.of(context);
    final drawerRadius = store.cardRadius;
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      drawerEnableOpenDragGesture: true,
      drawerEdgeDragWidth: 110,
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * (2 / 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(drawerRadius)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Text(
                  '菜单',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('设置'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  _openSettings();
                },
              ),
            ],
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      appBar: FoggyAppBar(
        title: const Text('App'),
        isScrolled: _isScrolled,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _openDrawer,
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          // 只跟踪垂直滚动位置，避免横向/overscroll 干扰
          if (n.metrics.axis == Axis.vertical) {
            _handleScroll(n.metrics.pixels);
          }
          return false;
        },
        child: const HomePage(),
      ),
    );
  }
}