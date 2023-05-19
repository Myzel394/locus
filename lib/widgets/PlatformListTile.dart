// Create a platform list tile that uses ListTile for android and CupertinoListTile for iOS

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class PlatformListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final GestureTapCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final bool cupertinoNotched;
  final Widget? cupertinoAdditionalInfo;
  final VisualDensity? materialVisualDensity;

  const PlatformListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding,
    this.cupertinoNotched = false,
    this.cupertinoAdditionalInfo,
    this.materialVisualDensity,
    Key? key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isCupertino(context)) {
      if (cupertinoNotched) {
        return CupertinoListTile.notched(
          title: title,
          subtitle: subtitle,
          leading: leading,
          trailing: trailing,
          onTap: onTap,
          padding: padding,
          additionalInfo: cupertinoAdditionalInfo,
        );
      } else {
        return CupertinoListTile(
          title: title,
          subtitle: subtitle,
          leading: leading,
          trailing: trailing,
          onTap: onTap,
          padding: padding,
          additionalInfo: cupertinoAdditionalInfo,
        );
      }
    } else {
      return ListTile(
        title: title,
        subtitle: subtitle,
        leading: leading,
        trailing: trailing,
        onTap: onTap,
        contentPadding: padding,
        visualDensity: materialVisualDensity,
      );
    }
  }
}
