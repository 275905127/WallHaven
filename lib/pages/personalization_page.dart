import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../app/app_intent.dart';
import '../theme/theme_store.dart';

class PersonalizationPage extends StatelessWidget {
  final AppController controller;

  const PersonalizationPage({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final store = ThemeScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('主题 / 个性化'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => controller.dispatch(const PopRouteIntent()),
        ),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text('ThemeMode', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('系统')),
                  ButtonSegment(value: ThemeMode.light, label: Text('浅色')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('深色')),
                ],
                selected: {store.preferredMode},
                onSelectionChanged: (s) => store.setPreferredMode(s.first),
              ),
              const SizedBox(height: 18),

              Text('圆角', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('cardRadius: ${store.cardRadius.toStringAsFixed(0)}'),
              Slider(
                value: store.cardRadius,
                min: 8,
                max: 28,
                divisions: 20,
                onChanged: store.setCardRadius,
              ),
              const SizedBox(height: 8),
              Text('imageRadius: ${store.imageRadius.toStringAsFixed(0)}'),
              Slider(
                value: store.imageRadius,
                min: 6,
                max: 24,
                divisions: 18,
                onChanged: store.setImageRadius,
              ),
            ],
          );
        },
      ),
    );
  }
}