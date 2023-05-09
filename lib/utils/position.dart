import 'package:flutter/widgets.dart';

getPositionTopLeft(final GlobalKey parentKey, final GlobalKey childKey) {
  final parentBox = parentKey.currentContext!.findRenderObject() as RenderBox?;
  if (parentBox == null) {
    throw Exception();
  }
  final childBox = childKey.currentContext!.findRenderObject() as RenderBox?;
  if (childBox == null) {
    throw Exception();
  }

  final parentPosition = parentBox.localToGlobal(Offset.zero);

  final childPosition = childBox.localToGlobal(Offset.zero);

  final x = childPosition.dx - parentPosition.dx;
  final y = (childPosition.dy - parentPosition.dy).abs();

  return Offset(x, y);
}
