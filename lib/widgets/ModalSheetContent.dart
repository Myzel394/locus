import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/utils/theme.dart';
import 'package:provider/provider.dart';

import '../constants/spacing.dart';
import 'package:locus/services/settings_service/index.dart';

class ModalSheetContent extends StatelessWidget {
  final String title;
  final String? description;
  final IconData? icon;

  final List<Widget> children;

  final VoidCallback? onSubmit;
  final IconData submitIcon;
  final String? submitLabel;

  const ModalSheetContent({
    required this.title,
    required this.children,
    this.submitIcon = Icons.check_rounded,
    this.description,
    this.icon,
    this.submitLabel,
    this.onSubmit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (icon != null) ...[
          Icon(
            icon,
            size: 48,
            color: platformThemeData(
              context,
              material: (data) =>
                  settings.primaryColor ?? data.colorScheme.tertiary,
              cupertino: (data) => settings.primaryColor ?? data.primaryColor,
            ),
          ),
          const SizedBox(height: MEDIUM_SPACE),
        ],
        Text(
          title,
          style: getTitle2TextStyle(context),
          textAlign: TextAlign.center,
        ),
        if (description != null) ...[
          const SizedBox(height: MEDIUM_SPACE),
          Text(
            description!,
            style: getCaptionTextStyle(context),
          ),
        ],
        const SizedBox(height: LARGE_SPACE),
        ...children,
        if (submitLabel != null) ...[
          const SizedBox(height: LARGE_SPACE),
          PlatformElevatedButton(
            material: (_, __) => MaterialElevatedButtonData(
              icon: Icon(submitIcon),
            ),
            padding: const EdgeInsets.all(MEDIUM_SPACE),
            onPressed: onSubmit,
            child: Text(submitLabel!),
          ),
        ],
      ],
    );
  }
}
