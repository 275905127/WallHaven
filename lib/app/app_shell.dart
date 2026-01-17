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

  void _closeDrawerIfOpen() {
    final st = _scaffoldKey.currentState;
    if (st == null) return;
    if (st.isDrawerOpen) {
      // 只在 drawer 打开时 pop，避免误伤路由栈
      Navigator.of(context).pop();
    }
  }

  Future<void> _pushPage(Widget page) async {
    // 避免抽屉动画/路由 push 叠在一起
    _closeDrawerIfOpen();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _handleEffect(AppEffect e) {
    if (!mounted) return;
    final c = _controller;
    if (c == null) return;

    switch (e) {
      case NavigateToSettingsEffect():
        _pushPage(SettingsPage(controller: c));
        break;

      case NavigateToPersonalizationEffect():
        _pushPage(PersonalizationPage(controller: c));
        break;

      case PopRouteEffect():
        Navigator.of(context).maybePop();
        break;

      case OpenDrawerEffect():
        _scaffoldKey.currentState?.openDrawer();
        break;

      case CloseDrawerEffect():
        _closeDrawerIfOpen();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ThemeScope.of(context);
    final drawerRadius = store.cardRadius;
    final c = _controller;

    // 首帧不要 shrink（会出现“白一下”，CI/测试也容易踩）
    if (c == null) {
      return const Scaffold(body: SizedBox.shrink());
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
                  // 先关 drawer 再导航（通过 effect 做）
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