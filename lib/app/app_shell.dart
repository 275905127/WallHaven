// lib/app/app_shell.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../pages/home_page.dart';
import '../pages/settings_page.dart';
import '../theme/theme_store.dart';
import '../widgets/foggy_app_bar.dart';
import 'app_controller.dart';
import 'app_intent.dart';

class AppShell extends StatefulWidget {
  final AppController controller;
  const AppShell({super.key, required this.controller});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _sc = ScrollController();

  bool _isScrolled = false;

  AppController get _ctl => widget.controller;

  @override
  void initState() {
    super.initState();
    _sc.addListener(() {
      final s = _sc.offset > 0;
      if (s != _isScrolled) setState(() => _isScrolled = s);
    });

    _ctl.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    _ctl.removeListener(_onControllerChanged);
    _sc.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    // Drawer 开关：用 controller 状态驱动 Scaffold
    if (!mounted) return;

    if (_ctl.drawerOpen) {
      // 避免在 build 期间触发 openDrawer
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scaffoldKey.currentState?.openDrawer();
      });
    } else {
      // 如果已经开着，关掉
      if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
        Navigator.of(context).maybePop();
      }
    }

    // route 切换在 body 里用 AnimatedSwitcher 直接切
    setState(() {});
  }

  Widget _buildDrawer(BuildContext context) {
    final store = ThemeScope.of(context);
    final drawerRadius = store.cardRadius;

    return Drawer(
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
              leading: const Icon(Icons.home_outlined),
              title: const Text('主页'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _ctl.dispatch(const GoHome()),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('设置'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _ctl.dispatch(const GoSettings()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final r = _ctl.route;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: switch (r) {
        AppRoute.home => HomePage(
            key: const ValueKey('home'),
            scrollController: _sc,
          ),
        AppRoute.settings => SettingsPage(
            key: const ValueKey('settings'),
            onBack: () => _ctl.dispatch(const GoHome()),
          ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      onDrawerChanged: (open) {
        // 用户手势开关 drawer，同步回 controller
        if (open != _ctl.drawerOpen) {
          _ctl.dispatch(open ? const OpenDrawer() : const CloseDrawer());
        }
      },
      drawerEnableOpenDragGesture: true,
      drawerEdgeDragWidth: 110,
      drawerDragStartBehavior: DragStartBehavior.down,
      drawer: _buildDrawer(context),
      extendBodyBehindAppBar: true,
      appBar: FoggyAppBar(
        title: Text(_ctl.route == AppRoute.settings ? '设置' : 'App'),
        isScrolled: _isScrolled,
        leading: (_ctl.route == AppRoute.settings)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _ctl.dispatch(const GoHome()),
              )
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _ctl.dispatch(const OpenDrawer()),
              ),
      ),
      body: _buildBody(),
    );
  }
}