import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/utils/theme.dart';
import 'package:provider/provider.dart';

import '../constants/spacing.dart';
import '../services/settings_service.dart';

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
      children: <Widget>[
        if (icon != null)
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
        if (submitLabel != null)
          PlatformElevatedButton(
            material: (_, __) => MaterialElevatedButtonData(
              icon: Icon(submitIcon),
            ),
            onPressed: onSubmit,
            child: Text(submitLabel!),
          )
      ],
    );
  }
}
