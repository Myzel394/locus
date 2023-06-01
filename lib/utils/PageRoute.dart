import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:locus/utils/device.dart';

class NativePageRoute extends MaterialPageRoute {
  NativePageRoute({required super.builder});

  @override
  Duration get transitionDuration =>
      isMIUI() ? 800.milliseconds : super.transitionDuration;
}
