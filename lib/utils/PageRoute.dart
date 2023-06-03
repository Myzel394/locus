import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart';

class NativePageRoute extends MaterialPageRoute {
  final BuildContext context;

  NativePageRoute({required super.builder, required this.context});

  @override
  Duration get transitionDuration {
    final settings = context.read<SettingsService>();

    return settings.isMIUI() ? 700.milliseconds : super.transitionDuration;
  }
}
