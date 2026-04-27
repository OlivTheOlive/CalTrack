import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const String kOpenNutritionUrl = 'https://www.opennutrition.app';

/// Required visible attribution when showing OpenNutrition catalog data.
class OpenNutritionAttribution extends StatelessWidget {
  const OpenNutritionAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Text('Food data from OpenNutrition.', style: style),
        TextButton(
          onPressed: () async {
            final uri = Uri.parse(kOpenNutritionUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: const Text('opennutrition.app'),
        ),
      ],
    );
  }
}
