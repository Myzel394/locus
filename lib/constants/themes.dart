import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:locus/constants/colors.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/OpenFromRightPageTransition.dart';

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

final DARK_THEME_MATERIAL_MIUI = ThemeData.dark().copyWith(
  useMaterial3: true,
  scaffoldBackgroundColor: Colors.black,
  dialogBackgroundColor: MIUI_DIALOG_COLOR,
  appBarTheme: ThemeData.dark().appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
      ),
  textTheme: ThemeData.dark().textTheme.copyWith(
        headlineLarge: const TextStyle(
          fontSize: 46,
          fontWeight: FontWeight.w200,
        ),
        bodyLarge: ThemeData.dark().textTheme.bodyMedium!.copyWith(
              height: 1.5,
              fontWeight: FontWeight.w400,
              fontSize: 16,
            ),
      ),
  buttonBarTheme: ThemeData.dark().buttonBarTheme.copyWith(
        buttonTextTheme: ButtonTextTheme.primary,
      ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: MIUI_PRIMARY_COLOR,
      foregroundColor: Colors.white,
      splashFactory: NoSplash.splashFactory,
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
  popupMenuTheme: ThemeData.dark().popupMenuTheme.copyWith(
        color: MIUI_DIALOG_COLOR,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MEDIUM_SPACE),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
  inputDecorationTheme: InputDecorationTheme(
    helperMaxLines: 10,
    errorMaxLines: 10,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(MEDIUM_SPACE),
    ),
  ),
  switchTheme: ThemeData.dark().switchTheme.copyWith(),
  // Swipe from right to left
  pageTransitionsTheme: PageTransitionsTheme(
    builders: {
      TargetPlatform.android: OpenFromRightPageTransitionsBuilder(),
    },
  ),
);

final LIGHT_THEME_CUPERTINO = const CupertinoThemeData().copyWith(
  textTheme: const CupertinoThemeData().textTheme.copyWith(
        navLargeTitleTextStyle: const CupertinoThemeData()
            .textTheme
            .navLargeTitleTextStyle
            .copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w500,
            ),
      ),
);

const CUPERTINO_SUBTITLE_FONT_SIZE = 12.0;
