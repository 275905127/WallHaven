// lib/app/app_shell.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../pages/home_page.dart';
import '../pages/personalization_page.dart';
import '../pages/settings_page.dart';
import '../theme/theme_store.dart';
import '../widgets/foggy_app_bar.dart';
import 'app_controller.dart';
import 'app_effect.dart';
import 'app_intent.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _sc = ScrollController();

  AppController? _controller;
  StreamSubscription<AppEffect>? _effSub;

  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();

    _sc.addListener(() {
      final s = _sc.offset > 0;
      if (s != _isScrolled) setState(() => _isScrolled = s);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 只初始化一次
    if (_controller != null) return;

    final store = ThemeScope.of(context);
    final c = AppController(store: store);
    _controller = c;
    _effSub = c.effects.listen(_handleEffect);
  }

  @override
  void dispose() {
    _effSub?.cancel();
    _controller?.dispose();
    _sc.dispose();
    super.dispose();
  }

  void _handleEffect(AppEffect e) {
    if (!mounted) return;
    final c = _controller;
    if (c == null) return;

    switch (e) {
      case NavigateToSettingsEffect():
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SettingsPage(controller: c)),
        );
        break;

      case NavigateToPersonalizationEffect():
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PersonalizationPage(controller: c)),
        );
        break;

      case PopRouteEffect():
        Navigator.of(context).maybePop();
        break;

      case OpenDrawerEffect():
        _scaffoldKey.currentState?.openDrawer();
        break;

      case CloseDrawerEffect():
        Navigator.of(context).maybePop();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ThemeScope.of(context);
    final drawerRadius = store.cardRadius;
    final c = _controller;

    // controller 尚未初始化（极短窗口），先给空壳
    if (c == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      key: _scaffoldKey,
      drawerEnableOpenDragGesture: true,
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
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Text('菜单', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('设置'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  c.dispatch(const CloseDrawerIntent());
                  c.dispatch(const OpenSettingsIntent());
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
      ),
      body: HomePage(scrollController: _sc),
    );
  }
}