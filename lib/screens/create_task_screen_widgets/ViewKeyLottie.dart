import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../utils/theme.dart';

class ViewKeyLottie extends StatefulWidget {
  const ViewKeyLottie({Key? key}) : super(key: key);

  @override
  State<ViewKeyLottie> createState() => _ViewKeyLottieState();
}

class _ViewKeyLottieState extends State<ViewKeyLottie> {
  @override
  Widget build(BuildContext context) {
    final shades = getPrimaryColorShades(context);

    return Lottie.asset(
      "assets/lotties/3d-shape-basic.json",
      frameRate: FrameRate.max,
      delegates: LottieDelegates(
        values: [
          ValueDelegate.colorFilter(
            ["left", "Rectangle 1", "Stroke 1"],
            value: ColorFilter.mode(
              shades[0]!,
              BlendMode.lighten,
            ),
          )
        ],
      ),
    );
  }
}
