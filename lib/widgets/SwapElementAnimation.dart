import 'package:flutter/material.dart';

import '../utils/position.dart';

class SwapAnimationData<T> {
  final Animation<Offset> animation;
  final Offset startPosition;
  final T oldValue;

  const SwapAnimationData({
    required this.startPosition,
    required this.oldValue,
    required this.animation,
  });
}

class SwapElementAnimation<T> extends StatefulWidget {
  final T value;
  final List<T> items;

  final Curve easing;
  final Duration duration;

  // Builds the full widget
  // `swapElement` is the element that can be swapped
  // `renderElement` is a function that renders an element at a given index
  final Widget Function(Widget swapElement, Widget Function(int index) renderElement) builder;

  // Builds a single element; Used for building both elements inside the list and the swap element
  final Widget Function(T? value, GlobalKey key) elementBuilder;

  final Widget Function(T? value, GlobalKey key)? swapElementBuilder;

  const SwapElementAnimation({
    required this.value,
    required this.items,
    required this.builder,
    required this.elementBuilder,
    this.easing = Curves.linear,
    this.duration = const Duration(milliseconds: 800),
    this.swapElementBuilder,
    Key? key,
  }) : super(key: key);

  @override
  State<SwapElementAnimation> createState() => _SwapElementAnimationState<T>();
}

class _SwapElementAnimationState<T> extends State<SwapElementAnimation<T>> with TickerProviderStateMixin {
  late final List<GlobalKey> keys;
  late final AnimationController controller;
  SwapAnimationData? animationData;
  SwapAnimationData? outAnimationData;

  final relativeAnchorKey = GlobalKey();
  final swapKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    keys = List.generate(widget.items.length, (index) => GlobalKey());
    controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          animationData = null;
          outAnimationData = null;
        });
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SwapElementAnimation<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      _createAnimation(oldWidget.value);
    }
  }

  GlobalKey? findKeyByValue(final T value) {
    final index = widget.items.indexOf(value);

    if (index == -1) {
      return null;
    }

    return keys[index];
  }

  void _createAnimation(final T oldValue) {
    final changePositionKey = findKeyByValue(widget.value);
    final moveOutPositionKey = findKeyByValue(oldValue);

    final swapPosition = getPositionTopLeft(relativeAnchorKey, swapKey);

    if (changePositionKey != null) {
      final valuePosition = getPositionTopLeft(relativeAnchorKey, changePositionKey);
      final offset = Offset(
        swapPosition.dx - valuePosition.dx,
        swapPosition.dy - valuePosition.dy,
      );

      setState(() {
        animationData = SwapAnimationData<T>(
          startPosition: valuePosition,
          oldValue: oldValue,
          animation: Tween<Offset>(
            begin: Offset.zero,
            end: offset,
          ).animate(
            CurvedAnimation(
              parent: controller,
              curve: widget.easing,
            ),
          ),
        );
      });
    }

    if (moveOutPositionKey != null) {
      final moveOutPosition = getPositionTopLeft(relativeAnchorKey, moveOutPositionKey);
      final moveOutOffset = Offset(
        moveOutPosition.dx - swapPosition.dx,
        moveOutPosition.dy - swapPosition.dy,
      );

      setState(() {
        outAnimationData = SwapAnimationData<T>(
          startPosition: swapPosition,
          oldValue: oldValue,
          animation: Tween<Offset>(
            begin: Offset.zero,
            end: moveOutOffset,
          ).animate(
            CurvedAnimation(
              parent: controller,
              curve: widget.easing,
            ),
          ),
        );
      });
    }

    controller.forward(
      from: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: relativeAnchorKey,
      children: [
        widget.builder(
          widget.swapElementBuilder == null
              ? widget.elementBuilder(
                  animationData == null ? widget.value : null,
                  swapKey,
                )
              : widget.swapElementBuilder!(animationData == null ? widget.value : null, swapKey),
          (index) {
            final value = widget.items[index];

            return Opacity(
              opacity: (widget.value == value) || (outAnimationData?.oldValue == value) ? 0 : 1,
              child: widget.elementBuilder(widget.items[index], keys[index]),
            );
          },
        ),
        animationData == null
            ? const SizedBox.shrink()
            : Positioned(
                left: animationData!.startPosition.dx,
                top: animationData!.startPosition.dy,
                child: AnimatedBuilder(
                  animation: animationData!.animation,
                  child: widget.elementBuilder(
                    widget.value,
                    GlobalKey(),
                  ),
                  builder: (context, child) => Transform.translate(
                    offset: animationData!.animation.value,
                    child: child,
                  ),
                ),
              ),
        outAnimationData == null
            ? const SizedBox.shrink()
            : Positioned(
                left: outAnimationData!.startPosition.dx,
                top: outAnimationData!.startPosition.dy,
                child: AnimatedBuilder(
                  animation: outAnimationData!.animation,
                  child: widget.elementBuilder(
                    outAnimationData!.oldValue,
                    GlobalKey(),
                  ),
                  builder: (context, child) => Transform.translate(
                    offset: outAnimationData!.animation.value,
                    child: child,
                  ),
                ),
              ),
      ],
    );
  }
}
