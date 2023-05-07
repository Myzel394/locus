import 'dart:io';

import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/welcome_screen_widgets/BatteryOptimizationsScreen.dart';
import 'package:locus/screens/welcome_screen_widgets/InitialScreen.dart';
import 'package:locus/screens/welcome_screen_widgets/PermissionsScreen.dart';

import 'MainScreen.dart';

const storage = FlutterSecureStorage();

enum Page {
  welcome,
  permissions,
  batteryOptimizations,
  done,
}

class WelcomeScreen extends StatefulWidget {
  final bool hasLocationAlwaysGranted;
  final bool isIgnoringBatteryOptimizations;

  const WelcomeScreen({
    required this.hasLocationAlwaysGranted,
    required this.isIgnoringBatteryOptimizations,
    Key? key,
  }) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  void _nextScreen(final int page) {
    _controller.animateToPage(page, duration: 500.ms, curve: Curves.easeOutExpo);
  }

  void _onDone() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MainScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          child: PageView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            children: <Widget>[
              InitialScreen(
                onContinue: () {
                  if (Platform.isAndroid) {
                    if (widget.hasLocationAlwaysGranted) {
                      _nextScreen(Page.batteryOptimizations.index);
                    } else {
                      _nextScreen(Page.permissions.index);
                    }
                  } else {
                    if (widget.hasLocationAlwaysGranted) {
                      _onDone();
                    } else {
                      _nextScreen(Page.permissions.index);
                    }
                  }
                },
              ),
              PermissionsScreen(
                onGranted: () {
                  if (Platform.isAndroid) {
                    if (widget.isIgnoringBatteryOptimizations) {
                      _onDone();
                    } else {
                      _nextScreen(Page.batteryOptimizations.index);
                    }
                  } else {
                    _onDone();
                  }
                },
              ),
              BatteryOptimizationsScreen(onDone: _onDone),
            ],
          ),
        ),
      ),
    );
  }
}
