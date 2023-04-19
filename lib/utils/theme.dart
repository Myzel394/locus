import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

TextStyle getBodyTextTextStyle(final BuildContext context) => platformThemeData(
      context,
      material: (data) => data.textTheme.bodyText1!,
      cupertino: (data) => data.textTheme.textStyle,
    );

TextStyle getErrorTextStyle(final BuildContext context) => getBodyTextTextStyle(context).copyWith(
      color: Colors.red,
    );

Color getBodyTextColor(final BuildContext context) => platformThemeData(
      context,
      material: (data) => data.textTheme.bodyText1!.color!,
      cupertino: (data) => data.textTheme.textStyle.color!,
    );

TextStyle getTitleTextStyle(final BuildContext context) => platformThemeData(
      context,
      material: (data) => data.textTheme.headline1!,
      cupertino: (data) => data.textTheme.navLargeTitleTextStyle,
    );

TextStyle getTitle2TextStyle(final BuildContext context) => platformThemeData(
      context,
      material: (data) => data.textTheme.headline2!,
      cupertino: (data) => data.textTheme.navTitleTextStyle,
    );

TextStyle getSubTitleTextStyle(final BuildContext context) => platformThemeData(
      context,
      material: (data) => data.textTheme.subtitle1!,
      cupertino: (data) => data.textTheme.navTitleTextStyle,
    );

TextStyle getCaptionTextStyle(final BuildContext context) => platformThemeData(
      context,
      material: (data) => data.textTheme.caption!,
      cupertino: (data) => data.textTheme.tabLabelTextStyle,
    );

Color getSheetColor(final BuildContext context) => platformThemeData(
      context,
      material: (data) => HSLColor.fromColor(data.scaffoldBackgroundColor.withAlpha(255)).withLightness(.18).toColor(),
      cupertino: (data) => data.barBackgroundColor,
    );

double getIconSizeForBodyText(final BuildContext context) => platformThemeData(
      context,
      material: (data) => data.textTheme.bodyText1!.fontSize ?? 16,
      cupertino: (data) => data.textTheme.textStyle.fontSize ?? 16,
    );

double getActionButtonSize(final BuildContext context) => platformThemeData(
      context,
      material: (data) => data.textTheme.headline6!.fontSize ?? 16,
      cupertino: (data) => data.textTheme.actionTextStyle.fontSize ?? 16,
    );
