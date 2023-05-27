import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:locus/constants/spacing.dart';

final LIGHT_THEME_MATERIAL = ThemeData(
  useMaterial3: true,
  textTheme: ThemeData().textTheme.copyWith(
        headline1: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w500,
        ),
        bodyText1: ThemeData().textTheme.bodyText1!.copyWith(
              height: 1.5,
            ),
      ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    helperMaxLines: 10,
    errorMaxLines: 10,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(MEDIUM_SPACE),
    ),
  ),
);

final DARK_THEME_MATERIAL = ThemeData.dark().copyWith(
  useMaterial3: true,
  textTheme: ThemeData.dark().textTheme.copyWith(
        headline1: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w500,
        ),
        bodyText1: ThemeData.dark().textTheme.bodyText1!.copyWith(
              height: 1.5,
            ),
      ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    helperMaxLines: 10,
    errorMaxLines: 10,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(MEDIUM_SPACE),
    ),
  ),
);

final LIGHT_THEME_CUPERTINO = const CupertinoThemeData().copyWith(
  textTheme: const CupertinoThemeData().textTheme.copyWith(
        navLargeTitleTextStyle: const CupertinoThemeData().textTheme.navLargeTitleTextStyle.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w500,
            ),
      ),
);

const CUPERTINO_SUBTITLE_FONT_SIZE = 12.0;
