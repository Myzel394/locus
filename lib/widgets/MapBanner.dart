import 'package:flutter/material.dart';

import '../constants/spacing.dart';

class MapBanner extends StatelessWidget {
  final Widget child;

  const MapBanner({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Positioned(
        left: 0,
        right: 0,
        top: 0,
        child: Container(
          color: Colors.black.withOpacity(.8),
          child: Padding(
            padding: const EdgeInsets.all(MEDIUM_SPACE),
            child: child,
          ),
        ),
      ),
    );
  }
}
