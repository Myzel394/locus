import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:locus/constants/colors.dart';
import 'package:locus/constants/spacing.dart';

final LIGHT_THEME_MATERIAL = ThemeData(
  useMaterial3: true,
  textTheme: ThemeData().textTheme.copyWith(
        displayLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: ThemeData().textTheme.bodyLarge!.copyWith(
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
        displayLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: ThemeData.dark().textTheme.bodyLarge!.copyWith(
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
        bodySmall: ThemeData.dark().textTheme.bodySmall!.copyWith(
              color: const Color(0xFF555555),
            ),
      ),
  buttonBarTheme: ThemeData.dark().buttonBarTheme.copyWith(
        buttonTextTheme: ButtonTextTheme.primary,
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
  inputDecorationTheme: const InputDecorationTheme(
    helperMaxLines: 10,
    errorMaxLines: 10,
    filled: true,
    fillColor: MIUI_DIALOG_COLOR,
    // No border
    border: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.all(Radius.circular(HUGE_SPACE)),
    ),
  ),
  primaryColor: MIUI_PRIMARY_COLOR,
  switchTheme: ThemeData.dark().switchTheme.copyWith(),
  // Swipe from right to left
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
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
