import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../utils/theme.dart';

class SignKeyLottie extends StatefulWidget {
  const SignKeyLottie({Key? key}) : super(key: key);

  @override
  State<SignKeyLottie> createState() => _SignKeyLottieState();
}

class _SignKeyLottieState extends State<SignKeyLottie> {
  @override
  Widget build(BuildContext context) {
    final shades = getPrimaryColorShades(context);

    return Lottie.asset(
      "assets/lotties/circle-loading.json",
      frameRate: FrameRate.max,
      delegates: LottieDelegates(
        values: [
          // Front
          ValueDelegate.color(
            ["Shape Layer 2", "Shape 1", "Fill 1"],
            value: shades[500],
          ),
          ValueDelegate.color(
            ["Shape Layer 1", "Shape 1", "Fill 1"],
            value: shades[500],
          ),
          // Dark sides
          ValueDelegate.color(
            ["Shape 7", "Shape 2", "Fill 1"],
            value: shades[600],
          ),
          ValueDelegate.color(
            ["Shape 3", "Shape 3", "Fill 1"],
            value: shades[600],
          ),
          ValueDelegate.color(
            ["Shape 4", "Shape 4", "Fill 1"],
            value: shades[600],
          ),
          // Bright sides
          ValueDelegate.color(
            ["Shape 6", "Shape 3", "Fill 1"],
            value: shades[400],
          ),
          ValueDelegate.color(
            ["Shape 5", "Shape 4", "Fill 1"],
            value: shades[400],
          ),
          ValueDelegate.color(
            ["Shape 2", "Shape 2", "Fill 1"],
            value: shades[400],
          ),
        ],
      ),
    );
  }
}
