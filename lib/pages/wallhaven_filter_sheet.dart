import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

class WallhavenFilterSheet extends StatelessWidget {
  const WallhavenFilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final width = MediaQuery.of(context).size.width * 2 / 3;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: theme.scaffoldBackgroundColor,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _sectionTitle(context, "排序"),
                    _radio(context, "榜单", true),
                    _divider(tokens),
                    _radio(context, "最新", false),

                    const SizedBox(height: 24),
                    _sectionTitle(context, "分类"),
                    _checkbox(context, "Anime"),
                    _checkbox(context, "General"),
                    _checkbox(context, "People"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "筛选",
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _radio(BuildContext context, String text, bool selected) {
    return Row(
      children: [
        Radio<bool>(
          value: true,
          groupValue: selected,
          onChanged: (_) {},
        ),
        Text(text),
      ],
    );
  }

  Widget _checkbox(BuildContext context, String text) {
    return Row(
      children: [
        Checkbox(value: false, onChanged: (_) {}),
        Text(text),
      ],
    );
  }

  Widget _divider(AppTokens tokens) {
    return Container(
      height: tokens.dividerThickness,
      color: tokens.dividerColor,
    );
  }
}
